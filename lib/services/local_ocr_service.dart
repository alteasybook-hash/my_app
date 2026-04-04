import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';

class LocalOCRService {
  final TextRecognizer _textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin);

  Future<Map<String, dynamic>> processImage(String path) async {
    String imagePath = path;
    File? tempFile;

    try {
      if (path.toLowerCase().endsWith('.pdf')) {
        final document = await PdfDocument.openFile(path);
        final page = await document.getPage(1);
        final pageImage = await page.render(
          width: page.width * 2, // Haute résolution pour une meilleure lecture
          height: page.height * 2,
          format: PdfPageImageFormat.png,
        );

        final tempDir = await getTemporaryDirectory();
        tempFile = File('${tempDir.path}/temp_ocr_page_${DateTime
            .now()
            .millisecondsSinceEpoch}.png');
        await tempFile.writeAsBytes(pageImage!.bytes);
        imagePath = tempFile.path;

        await page.close();
        await document.close();
      }

      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
          inputImage);

      String fullText = recognizedText.text;

      // Extraction avancée
      final amounts = _extractAmountsDetailed(fullText);
      final supplier = _extractSupplier(fullText);
      final categorization = _suggestCategoryAndAccount(supplier, fullText);

      return {
        'supplierName': supplier,
        'amountTTC': amounts['ttc'],
        'amountHT': amounts['ht'],
        'tva': amounts['tva'],
        'tvaRate': amounts['tvaRate'],
        'date': _extractDate(fullText),
        'invoiceNumber': _extractInvoiceNumber(fullText),
        'category': categorization['category'],
        'expenseAccount': categorization['account'],
        'designation': categorization['designation'] ??
            'Achat ${supplier ?? ""}',
      };
    } catch (e) {
      return {'error': 'Erreur lors du traitement du fichier: $e'};
    } finally {
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  String? _extractSupplier(String text) {
    final lines = text.split('\n');
    if (lines.isEmpty) return null;

    // On cherche les noms sur les 5 premières lignes (en ignorant les chiffres)
    for (int i = 0; i < lines.length && i < 10; i++) {
      String clean = lines[i].trim();
      if (clean.length > 3 &&
          !clean.contains(RegExp(r'\d{5}')) && // Pas un code postal
          !RegExp(r'^(FACT|INV|REF|DATE|N.)', caseSensitive: false).hasMatch(
              clean)) {
        return clean;
      }
    }
    return lines.first.trim();
  }

  Map<String, double?> _extractAmountsDetailed(String text) {
    // Nettoyage des caractères spéciaux pour les montants
    String cleanText = text.replaceAll(
        RegExp(r'\s(?=\d)'), ''); // Supprime les espaces entre chiffres
    cleanText = cleanText.replaceAll(',', '.').replaceAll('€', '').replaceAll(
        'EUR', '');

    double? ttc;
    double? ht;
    double? tva;
    double? tvaRate;

    // 1. Détection du Taux de TVA (ex: 20%, 5.5%) - Priorité haute
    final RegExp rateRegex = RegExp(
        r'(\d{1,2}[\.,]?\d?)[\s]*%', caseSensitive: false);
    final rateMatch = rateRegex.firstMatch(text);
    if (rateMatch != null) {
      tvaRate = double.tryParse(rateMatch.group(1)!.replaceAll(',', '.'));
    }

    // 2. Recherche TTC (Patterns multiples)
    final List<RegExp> ttcPatterns = [
      RegExp(
          r'(TOTAL\s*TTC|NET\s*A\s*PAYER|TOTAL\s*A\s*PAYER|TTC)[\s:]*([0-9]+\.[0-9]{2})',
          caseSensitive: false),
      RegExp(r'(TOTAL)[\s:]*([0-9]+\.[0-9]{2})$', caseSensitive: false,
          multiLine: true), // Souvent en fin de doc
    ];

    for (var pattern in ttcPatterns) {
      final match = pattern.firstMatch(cleanText);
      if (match != null) {
        ttc = double.tryParse(match.group(2)!);
        if (ttc != null) break;
      }
    }

    // 3. Recherche HT
    final List<RegExp> htPatterns = [
      RegExp(r'(TOTAL\s*HT|HT|MONTANT\s*HT)[\s:]*([0-9]+\.[0-9]{2})',
          caseSensitive: false),
      RegExp(r'(NET\s*HT)[\s:]*([0-9]+\.[0-9]{2})', caseSensitive: false),
    ];

    for (var pattern in htPatterns) {
      final match = pattern.firstMatch(cleanText);
      if (match != null) {
        ht = double.tryParse(match.group(2)!);
        if (ht != null) break;
      }
    }

    // 4. Recherche Montant TVA
    final RegExp tvaRegExp = RegExp(
        r'(TVA|TAXE|DONT\s*TVA)[\s:]*([0-9]+\.[0-9]{2})', caseSensitive: false);
    final tvaMatch = tvaRegExp.firstMatch(cleanText);
    if (tvaMatch != null) {
      tva = double.tryParse(tvaMatch.group(2)!);
    }

    // --- Logique Comptable Correctrice ---
    if (tvaRate == null) {
      if (text.toLowerCase().contains("tva non applicable") ||
          text.toLowerCase().contains("article 293b")) {
        tvaRate = 0.0;
        tva = 0.0;
      } else {
        tvaRate = 20.0; // Défaut France
      }
    }

    if (ttc != null && ht == null) {
      ht = ttc / (1 + (tvaRate / 100));
      tva = ttc - ht;
    } else if (ht != null && tva != null && ttc == null) {
      ttc = ht + tva;
    } else if (ttc != null && ht != null && tva == null) {
      tva = ttc - ht;
    }

    return {
      'ttc': ttc != null ? double.parse(ttc.toStringAsFixed(2)) : null,
      'ht': ht != null ? double.parse(ht.toStringAsFixed(2)) : null,
      'tva': tva != null ? double.parse(tva.toStringAsFixed(2)) : null,
      'tvaRate': tvaRate,
    };
  }

  Map<String, String> _suggestCategoryAndAccount(String? supplier,
      String text) {
    String fullLower = (supplier ?? "" + text).toLowerCase();

    // Téléphonie & Internet
    if (fullLower.contains(RegExp(
        r'orange|sfr|free|bouygues|telecom|internet|cloud|aws|google\s*cloud|microsoft|adobe|zoom'))) {
      return {
        'category': 'IT / Télécom',
        'account': '626000',
        'designation': 'Abonnement & Services IT'
      };
    }
    // Énergie & Utilitaires
    if (fullLower.contains(
        RegExp(r'edf|engie|totalenergies|veolia|eau|electricite|gaz'))) {
      return {
        'category': 'Énergie',
        'account': '606100',
        'designation': 'Consommables Énergie'
      };
    }
    // Transport & Mobilité
    if (fullLower.contains(RegExp(
        r'sncf|uber|bolt|taxi|train|avion|air\s*france|petrole|total\s*access|essence'))) {
      return {
        'category': 'Transport',
        'account': '625100',
        'designation': 'Déplacements'
      };
    }
    // Fournitures Bureau
    if (fullLower.contains(
        RegExp(r'amazon|fnac|cdiscount|bureau\s*vallee|staples|office|ikea'))) {
      return {
        'category': 'Fournitures',
        'account': '606300',
        'designation': 'Petit matériel / Fournitures'
      };
    }
    // Restauration
    if (fullLower.contains(RegExp(
        r'restau|dejeuner|repas|cafe|brasserie|monoprix|carrefour|auchan|lidl'))) {
      return {
        'category': 'Repas',
        'account': '625700',
        'designation': 'Frais de réception'
      };
    }
    // Assurance
    if (fullLower.contains(
        RegExp(r'axa|allianz|mma|generali|assurance|mutuelle'))) {
      return {
        'category': 'Assurance',
        'account': '616000',
        'designation': 'Primes d\'assurance'
      };
    }
    // Services Bancaires
    if (fullLower.contains(RegExp(
        r'banque|bnp|societe\s*generale|qonto|revolut|frais\s*bancaires'))) {
      return {
        'category': 'Frais Bancaires',
        'account': '627800',
        'designation': 'Commissions bancaires'
      };
    }

    return {
      'category': 'Achats divers',
      'account': '601000',
      'designation': 'Achat de biens et services'
    };
  }

  String? _extractDate(String text) {
    final RegExp dateRegExp = RegExp(
        r'(\d{2}/\d{2}/\d{4})|(\d{2}-\d{2}-\d{4})|(\d{4}/\d{2}/\d{2})');
    final match = dateRegExp.firstMatch(text);
    return match?.group(0);
  }

  String? _extractInvoiceNumber(String text) {
    final RegExp invRegExp = RegExp(
        r'(N°|Facture|INV|Ref|Pièce)[\s:]*([A-Z0-9-]{4,})',
        caseSensitive: false);
    final match = invRegExp.firstMatch(text);
    return match?.group(2);
  }

  void dispose() {
    _textRecognizer.close();
  }
}
