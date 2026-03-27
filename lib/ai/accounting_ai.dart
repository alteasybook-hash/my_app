import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/invoice.dart';
import '../models/bank_transaction.dart';
import '../models/payment.dart';

class AccountingAI {
  final GenerativeModel _model;

  AccountingAI({required String apiKey})
      : _model = GenerativeModel(
    // Utilisation du nom EXACT requis par l'API v1beta
    model: 'gemini-1.5-flash',
    apiKey: 'AIzaSyCrtVAiqGDLtdC9RQSxZnm4-FQ2mhJTTy4',);

  Future<Map<String, dynamic>> analyzeInvoice({
    required String label,
    required double amount,
    String? supplier,
    String? history,
    String? companyType,
    String? lastAccount,
  }) async {
    // Ajout d'un log pour déboguer si besoin (visible dans la console)
    print("IA: Analyse en cours pour $label...");

    final prompt = """
    Analyse cette opération comptable.
    Données : Libellé: "$label", Montant: $amount €.
    Réponds EXCLUSIVEMENT en JSON :
    {"account": "606000", "vat_rate": 20, "category": "Fournitures", "confidence": 0.95, "suggested_label": "Achat"}
    """;

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null) return {};
      final jsonStr = text.substring(
          text.indexOf('{'), text.lastIndexOf('}') + 1);
      return jsonDecode(jsonStr);
    } catch (e) {
      print("Erreur IA Analyse: $e");
      return {};
    }
  }

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
      // On retourne l'erreur précise pour aider au diagnostic
      return "Erreur lors de la génération : $e";
    }
  }

  List<Map<String, dynamic>> suggestMatches({
    required BankTransaction bTx,
    required List<Invoice> invoices,
    required List<Payment> payments,
  }) {
    return [];
  }
}