import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/invoice.dart';
import '../models/bank_transaction.dart';

class AccountingAI {
  final GenerativeModel _model;

  AccountingAI({required String apiKey})
      : _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

  /// Analyse une opération comptable avec plus de contexte
  Future<Map<String, dynamic>> analyzeInvoice({
    required String label,
    required double amount,
    String? supplier, String? history,
    String? lastAccount,
    List<String>? keywords,
  }) async {
    final prompt = """
    Analyse cette opération comptable.
    Libellé: "$label"
    Montant: $amount €
    Plan comptable français.
    Réponds en JSON:
    {"account": "606", "vat_rate": 20, "category": "Fournitures", "confidence": 0.92}
    """;

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? "{}";
      final jsonStart = text.indexOf('{');
      final jsonEnd = text.lastIndexOf('}') + 1;
      if (jsonStart == -1) return {"account": "606", "vat_rate": 20.0, "category": "Divers", "confidence": 0.5};
      return json.decode(text.substring(jsonStart, jsonEnd));
    } catch (e) {
      return {"account": "606", "vat_rate": 20.0, "category": "Erreur", "confidence": 0.0};
    }
  }

  /// RESTAURATION : Extraction OCR des données d'une facture depuis un fichier
  Future<Map<String, dynamic>> extractInvoiceDataFromPath(String path) async {
    final fileBytes = await File(path).readAsBytes();
    final prompt = [
      Content.multi([
        TextPart("Analyse cette image de facture et extrais : le numéro de facture (number), le nom du fournisseur (supplier), la date (date au format YYYY-MM-DD), le montant HT (amountHT), le montant TVA (tva), et le montant TTC (amountTTC). Réponds uniquement en JSON."),
        DataPart('image/jpeg', fileBytes),
      ])
    ];

    try {
      final response = await _model.generateContent(prompt);
      final text = response.text ?? "{}";
      final jsonStart = text.indexOf('{');
      final jsonEnd = text.lastIndexOf('}') + 1;
      if (jsonStart == -1) return {};
      return json.decode(text.substring(jsonStart, jsonEnd));
    } catch (e) {
      print("Erreur OCR IA: $e");
      return {};
    }
  }

  /// RESTAURATION : Génération d'un email de relance
  Future<String> generateReminderEmail({
    required String customerName,
    required String invoiceNumber,
    required double amount,
    required String dueDate,
  }) async {
    final prompt = """
    Rédige un email de relance de paiement amical et professionnel.
    Client: $customerName, Facture n°: $invoiceNumber, Montant: $amount €, Échéance: $dueDate.
    Réponds uniquement avec le corps du texte.
    """;

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "Impossible de générer le mail.";
    } catch (e) {
      return "Erreur lors de la génération : $e";
    }
  }

  List<Map<String, dynamic>> autoMatch({
    required List<BankTransaction> bankTransactions,
    required List<Invoice> invoices,
    required List<BankTransaction> softwareTransactions,
  }) {
    List<Map<String, dynamic>> suggestions = [];
    for (var bTx in bankTransactions.where((t) => t.id.startsWith('csv-') && !t.isReconciled)) {
      for (var inv in invoices.where((i) => !i.isReconciled)) {
        double invAmount = inv.type == InvoiceType.achat ? -inv.amountTTC : inv.amountTTC;
        if ((bTx.amount - invAmount).abs() < 0.01) {
          int diffDays = bTx.date.difference(inv.date).inDays.abs();
          if (diffDays <= 7) {
            suggestions.add({
              'bankTxId': bTx.id,
              'softwareId': inv.id,
              'type': 'invoice',
              'confidence': diffDays == 0 ? 1.0 : 0.8,
              'label': inv.supplierOrClientName
            });
          }
        }
      }
    }
    return suggestions;
  }

  bool detectDuplicateInvoice(Invoice newInvoice, List<Invoice> existingInvoices) {
    for (var existing in existingInvoices) {
      if (newInvoice.number.isNotEmpty && existing.number.isNotEmpty && newInvoice.number.trim().toLowerCase() == existing.number.trim().toLowerCase()) return true;
      final samePartner = newInvoice.supplierOrClientName.trim().toLowerCase() == existing.supplierOrClientName.trim().toLowerCase();
      final sameAmount = (newInvoice.amountTTC - existing.amountTTC).abs() < 0.01;
      final sameDate = newInvoice.date.year == existing.date.year && newInvoice.date.month == existing.date.month && newInvoice.date.day == existing.date.day;
      if (samePartner && sameAmount && sameDate) return true;
    }
    return false;
  }
}
