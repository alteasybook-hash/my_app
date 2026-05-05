import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/invoice.dart';
import '../models/budget_models.dart';
import '../models/entity.dart';
import '../models/employee.dart';
import 'package:flutter/foundation.dart';

class AccountingAI {
  final GenerativeModel _chatModel;
  final String apiKey;

  AccountingAI({required String apiKey})
      : apiKey = apiKey.replaceAll(';', '').trim(),
        _chatModel = GenerativeModel(
          model: 'gemini-flash-latest',
          apiKey: apiKey.replaceAll(';', '').trim(),
          requestOptions: const RequestOptions(apiVersion: 'v1beta'),
        );

  Future<String> chatWithContext({
    required String userMessage,
    required List<Invoice> invoices,
    required List<EntityBudget> budgets,
    required List<Entity> entities,
    required String currentPlan,
    required List<Employee> employees,
  }) async {
    if (apiKey.isEmpty) {
      return "Erreur : Clé API manquante dans le fichier .env";
    }

    final now = DateTime.now();
    final threeMonthsAgo = now.subtract(const Duration(days: 90));

    Map<String, double> salesByCurrency = {};
    Map<String, double> expensesByCurrency = {};

    for (var inv in invoices) {
      if (inv.type == InvoiceType.vente) {
        salesByCurrency[inv.currency] = (salesByCurrency[inv.currency] ?? 0.0) + inv.amountTTC;
      } else if (inv.type == InvoiceType.achat) {
        expensesByCurrency[inv.currency] = (expensesByCurrency[inv.currency] ?? 0.0) + inv.amountTTC;
      }
    }

    Set<String> allClients = invoices.where((i) => i.type == InvoiceType.vente).map((i) => i.supplierOrClientName).toSet();
    Set<String> activeClients = invoices.where((i) => i.type == InvoiceType.vente && i.date.isAfter(threeMonthsAgo)).map((i) => i.supplierOrClientName).toSet();
    List<String> lostClients = allClients.difference(activeClients).toList();

    String entitiesList = entities.isEmpty
        ? "Aucune entité enregistrée."
        : entities.map((e) => "- ${e.name} (ID: ${e.id}, Pays: ${e.country}, Devise: ${e.currency})").join("\n");

    final prompt = """
Tu es "alt.", un assistant financier intelligent.

CONTEXTE :
1. ENTITÉS DISPONIBLES : 
$entitiesList

2. RÉSUMÉ COMPTABLE :
- Plan comptable utilisé : $currentPlan
- Chiffre d'affaires (Ventes) : ${_formatCurrencyMap(salesByCurrency)}
- Dépenses totales : ${_formatCurrencyMap(expensesByCurrency)}
- Nombre de salariés : ${employees.length}
- Clients inactifs (> 90 jours) : ${lostClients.isEmpty ? 'Aucun' : lostClients.join(', ')}

3. STATISTIQUES :
- Factures totales : ${invoices.length}
- Budgets actifs : ${budgets.length}

RÈGLES DE RÉPONSE :
- Réponds uniquement dans la langue de l'utilisateur.
- Ne mélange jamais plusieurs langues.
- Traduis automatiquement toutes les phrases système dans la langue utilisée.
- Reste factuel.

QUESTION : "$userMessage"
""";

    try {
      final content = [Content.text(prompt)];
      final response = await _chatModel.generateContent(content);
      return (response.text ?? "Désolé, je n'ai pas pu générer de réponse.").trim();
    } catch (e) {
      return "Erreur de connexion IA : $e";
    }
  }

  String _formatCurrencyMap(Map<String, double> map) {
    if (map.isEmpty) return "0.00";
    return map.entries.map((e) => "${e.value.toStringAsFixed(2)} ${e.key}").join(", ");
  }

  // --- EXTRACTION MULTIMODALE (PDF & IMAGES) ---
  Future<Map<String, dynamic>> extractInvoiceDataFromPath(String path) async {
    try {
      final file = File(path);
      final fileBytes = await file.readAsBytes();
      
      // Détection dynamique du type MIME
      String mimeType = 'image/jpeg';
      if (path.toLowerCase().endsWith('.pdf')) {
        mimeType = 'application/pdf';
      } else if (path.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      }

      final prompt = [
        Content.multi([
          TextPart("""
          Analyse ce document (Facture ou Note de frais).
          Extrais les informations suivantes au format JSON uniquement :
          {
           "supplierName": "nom du fournisseur",
           "invoiceNumber": "numéro de facture",
           "date": "YYYY-MM-DD",
           "amountTTC": nombre,
           "amountHT": nombre,
           "tva": nombre,
           "tvaRate": nombre,
           "currency": "EUR",
           "type": "achat",
           "siren": "9 chiffres",
           "vatNumber": "numéro TVA intra",
           "iban": "si présent",
           "category": "RESTAURANT, TAXI, HOTEL, TRAIN, CARBURANT, ACHAT_BIENS, ou AUTRE"
           }

          Si une info est manquante, mets null.
          Réponds uniquement avec le JSON.
          """),
          DataPart(mimeType, fileBytes),
        ])
      ];

      final response = await _chatModel.generateContent(prompt);
      return _cleanAndDecodeJson(response.text);
    } catch (e) {
      debugPrint("Erreur Extraction Gemini : $e");
      return {'error': 'L\'IA n\'a pas pu analyser ce document : $e'};
    }
  }

  Map<String, dynamic> _cleanAndDecodeJson(String? text) {
    if (text == null || text.trim().isEmpty) return {};
    String cleanText = text.trim();
    if (cleanText.contains('```json')) {
      cleanText = cleanText.split('```json')[1].split('```')[0].trim();
    } else if (cleanText.contains('```')) {
      cleanText = cleanText.split('```')[1].split('```')[0].trim();
    }
    try {
      return json.decode(cleanText);
    } catch (e) {
      return {'error': 'L\'IA a renvoyé un format invalide.'};
    }
  }
}
