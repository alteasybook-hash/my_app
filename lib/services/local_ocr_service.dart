import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

class LocalOCRService {
  final TextRecognizer _textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin);

  LocalOCRService();

  Future<Map<String, dynamic>> processImage(String path) async {
    String imagePath = path;
    File? tempFile;

    try {
      if (path.toLowerCase().endsWith('.pdf')) {
        final document = await PdfDocument.openFile(path);
        final page = await document.getPage(1);
        final pageImage = await page.render(
          width: page.width * 3,
          height: page.height * 3,
          format: PdfPageImageFormat.png,
        );

        final tempDir = await getTemporaryDirectory();
        tempFile = File('${tempDir.path}/temp_ocr_${DateTime.now().millisecondsSinceEpoch}.png');
        await tempFile.writeAsBytes(pageImage!.bytes);
        imagePath = tempFile.path;

        await page.close();
        await document.close();
      }

      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      String fullText = recognizedText.text;
      String lowerText = fullText.toLowerCase();

      final amounts = _extractAmountsImproved(recognizedText);

      // Détection du type NDF et alignement des comptes
      String? expenseAccount;
      String? category;

      if (lowerText.contains('restaurant') || lowerText.contains('brasserie') || lowerText.contains('diner') || lowerText.contains('repas')) {
        expenseAccount = '625700'; // Réceptions
        category = 'RESTAURANT';
      } else if (lowerText.contains('taxi') || lowerText.contains('uber') || lowerText.contains('bolt')) {
        expenseAccount = '625100'; // Voyages et déplacements
        category = 'TAXI';
      } else if (lowerText.contains('hotel') || lowerText.contains('ibis') || lowerText.contains('novotel') || lowerText.contains('nuitée')) {
        expenseAccount = '625100'; // Voyages et déplacements
        category = 'HOTEL';
      } else if (lowerText.contains('sncf') || lowerText.contains('train') || lowerText.contains('billet')) {
        expenseAccount = '625100';
        category = 'TRAIN';
      } else if (lowerText.contains('essence') || lowerText.contains('carburant') || lowerText.contains('gasoil') || lowerText.contains('totalenergies')) {
        expenseAccount = '606100'; // Fournitures non stockables (énergie)
        category = 'CARBURANT';
      }

      return {
        'supplierName': _extractSupplierImproved(recognizedText),
        'invoiceNumber': _extractInvoiceNumberImproved(fullText),
        'date': _extractDateImproved(fullText),
        'amountTTC': amounts['ttc'],
        'amountHT': amounts['ht'],
        'tva': amounts['tva'],
        'tvaRate': amounts['tvaRate'],
        'currency': _extractCurrency(fullText),
        'type': 'achat',

        'category': category,
        'expenseAccount': expenseAccount,

        'siren': _extractRegex(fullText, r'\b\d{3}\s?\d{3}\s?\d{3}\b')?.replaceAll(' ', ''),
        'vatNumber': _extractRegex(fullText, r'FR\s?\d{2}\s?\d{9}', caseSensitive: false),

        'rawText': fullText,
      };


    } catch (e) {
      print("Erreur OCR Locale: $e");
      return {'error': 'Erreur scanner: $e'};
    } finally {
      if (tempFile != null && await tempFile.exists()) await tempFile.delete();
    }
  }

  String? _extractSupplierImproved(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return null;
    for (var block in recognizedText.blocks.take(3)) {
      String firstLine = block.text.split('\n').first.trim();
      if (firstLine.length > 2 &&
          !firstLine.toUpperCase().contains('FACTURE') &&
          !firstLine.toUpperCase().contains('REÇU') &&
          !firstLine.toUpperCase().contains('NOTE') &&
          !RegExp(r'^\d').hasMatch(firstLine)) {
        return firstLine;
      }
    }
    return "Fournisseur Inconnu";
  }

  Map<String, double> _extractAmountsImproved(RecognizedText recognizedText) {
    String text = recognizedText.text.replaceAll(',', '.');
    final matches = RegExp(r'(\d+[\s.]\d{2})').allMatches(text);
    List<double> values = [];
    for (var m in matches) {
      String clean = m.group(0)!.replaceAll(' ', '');
      double? val = double.tryParse(clean);
      if (val != null) values.add(val);
    }

    if (values.isEmpty) return {'ttc': 0.0, 'ht': 0.0, 'tva': 0.0, 'tvaRate': 20.0};
    
    values.sort((a, b) => b.compareTo(a));
    double ttc = values.first;

    double rate = 20.0;
    if (text.contains('5.5%') || text.contains('5,5')) rate = 5.5;
    else if (text.contains('10%') || text.contains('10,0')) rate = 10.0;
    else if (text.contains('2.1%') || text.contains('2,1')) rate = 2.1;

    double ht = double.parse((ttc / (1 + (rate / 100))).toStringAsFixed(2));
    double tva = double.parse((ttc - ht).toStringAsFixed(2));

    return {'ttc': ttc, 'ht': ht, 'tva': tva, 'tvaRate': rate};
  }

  String? _extractDateImproved(String text) {
    return _extractRegex(text, r'(\d{2}[/\-.]\d{2}[/\-.]\d{4})') ??
           _extractRegex(text, r'(\d{4}[/\-.]\d{2}[/\-.]\d{2})');
  }

  String? _extractInvoiceNumberImproved(String text) {
    final match = RegExp(r'(?:N°|Facture|INV|Ref|Note)[\s:]*([A-Z0-9\-_]{4,})', caseSensitive: false).firstMatch(text);
    return match?.group(1)?.trim();
  }

  String _extractCurrency(String text) {
    if (text.contains('€') || text.contains('EUR')) return 'EUR';
    if (text.contains('\$') || text.contains('USD')) return 'USD';
    return 'EUR';
  }

  String? _extractRegex(String text, String pattern, {bool caseSensitive = true}) {
    final reg = RegExp(pattern, caseSensitive: caseSensitive);
    return reg.firstMatch(text)?.group(0);
  }

  void dispose() => _textRecognizer.close();
}
