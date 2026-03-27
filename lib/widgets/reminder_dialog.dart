// lib/widgets/reminder_dialog.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/invoice.dart';
import '../models/supplier.dart'; // Import pour le modèle Supplier (Client)
import '../ai/accounting_ai.dart';
import '../services/api_service.dart';

class ReminderDialog extends StatefulWidget {
  final Invoice invoice;
  final AccountingAI ai;

  const ReminderDialog({super.key, required this.invoice, required this.ai});

  @override
  State<ReminderDialog> createState() => _ReminderDialogState();
}


class _ReminderDialogState extends State<ReminderDialog> {
  final TextEditingController _controller = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isGenerating = true;
  String? _customerEmail;

  @override
  void initState() {
    super.initState();
    _loadCustomerAndGenerate();
  }

  Future<void> _loadCustomerAndGenerate() async {
    // 1. On cherche l'email du client dans la base
    final customers = await _apiService.fetchCustomers();
    final customer = customers.cast<Supplier?>().firstWhere(
          (c) => c?.id == widget.invoice.supplierOrClientId,
      orElse: () => null,
    );

    _customerEmail = customer?.email;

    // 2. On génère le texte IA
    final text = await widget.ai.generateReminderEmail(
      customerName: widget.invoice.supplierOrClientName,
      invoiceNumber: widget.invoice.number,
      amount: widget.invoice.amountTTC,
      dueDate: widget.invoice.dueDate?.toString() ?? "N/A",
    );

    if (mounted) {
      setState(() {
        _controller.text = text;
        _isGenerating = false;
      });
    }
  }

  Future<void> _sendEmail() async {
    final String body = Uri.encodeComponent(_controller.text);
    final String subject = Uri.encodeComponent(
        "Relance : Facture n°${widget.invoice.number}");

    // Si on a l'email, on le met, sinon on laisse vide pour que l'utilisateur le saisisse
    final String recipient = _customerEmail ?? "";
    final String mailUrl = "mailto:$recipient?subject=$subject&body=$body";

    try {
      if (await canLaunchUrl(Uri.parse(mailUrl))) {
        await launchUrl(Uri.parse(mailUrl));
        if (mounted) Navigator.pop(context, true);
      } else {
        throw "Could not launch $mailUrl";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(
              "Impossible d'ouvrir votre application de messagerie")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF49F6C7)),
          const SizedBox(width: 10),
          const Text("Relance IA",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: _isGenerating
          ? const SizedBox(height: 150,
          child: Center(
              child: CircularProgressIndicator(color: Color(0xFF49F6C7))))
          : Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_customerEmail != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text("À : $_customerEmail", style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold)),
            ),
          TextField(
            controller: _controller,
            maxLines: 10,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text("ANNULER")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF49F6C7),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          onPressed: _isGenerating ? null : _sendEmail,
          child: const Text("VALIDER & ENVOYER",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}