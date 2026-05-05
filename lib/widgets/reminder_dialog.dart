import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../models/supplier.dart';
import '../models/entity.dart';
import '../services/api_service.dart';

class ReminderDialog extends StatefulWidget {
  final Invoice invoice;

  const ReminderDialog({super.key, required this.invoice});

  @override
  State<ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<ReminderDialog> {
  final TextEditingController _controller = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _customerEmail;

  @override
  void initState() {
    super.initState();
    _prepareReminder();
  }

  Future<void> _prepareReminder() async {
    // 1. Chercher l'email du client
    final customers = await _apiService.fetchCustomers();
    final customer = customers.cast<Supplier?>().firstWhere(
          (c) => c?.id == widget.invoice.supplierOrClientId,
      orElse: () => null,
    );

    _customerEmail = customer?.email;

    // 2. Chercher le nom de l'entité (entreprise)
    final entities = await _apiService.fetchEntities();
    final entity = entities.cast<Entity?>().firstWhere(
      (e) => e?.id == widget.invoice.entityId,
      orElse: () => null,
    );
    final String entityName = entity?.name ?? "votre partenaire";

    // 3. Préparer le texte de relance
    final String dueDateStr = widget.invoice.dueDate != null 
        ? DateFormat('dd/MM/yyyy').format(widget.invoice.dueDate!) 
        : "N/A";

    final int reminderCount = widget.invoice.reminderDates.length + 1;
    String prefix = "Relance";
    if (reminderCount == 1) prefix = "Première relance";
    else if (reminderCount == 2) prefix = "Deuxième relance";
    else if (reminderCount == 3) prefix = "Troisième relance";
    else prefix = "$reminderCountème relance";

    final String message = "Objet : $prefix - Facture n°${widget.invoice.number}\n\n"
        "Bonjour ${widget.invoice.supplierOrClientName},\n\n"
        "Sauf erreur de notre part, nous n'avons pas encore reçu le règlement de la facture n°${widget.invoice.number} "
        "d'un montant de ${widget.invoice.amountTTC} €, qui était arrivée à échéance le $dueDateStr.\n\n"
        "Nous vous remercions de bien vouloir régulariser cette situation dans les meilleurs délais. "
        "Si votre paiement a déjà été envoyé, nous vous prions de ne pas tenir compte de ce message.\n\n"
        "En vous souhaitant une excellente journée.\n\n"
        "Cordialement,\n\n"
        "$entityName";

    if (mounted) {
      setState(() {
        _controller.text = message;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendEmail() async {
    final String body = Uri.encodeComponent(_controller.text);
    final String subject = Uri.encodeComponent("Relance n°${widget.invoice.reminderDates.length + 1} : Facture n°${widget.invoice.number}");
    final String recipient = _customerEmail ?? "";
    final String mailUrl = "mailto:$recipient?subject=$subject&body=$body";

    try {
      if (await canLaunchUrl(Uri.parse(mailUrl))) {
        // Enregistrer la date de relance dans la base de données via l'API
        final List<DateTime> updatedReminders = List.from(widget.invoice.reminderDates)..add(DateTime.now());
        await _apiService.updateInvoice(widget.invoice.id, {
          'reminderDates': updatedReminders.map((d) => d.toIso8601String()).toList(),
        });

        await launchUrl(Uri.parse(mailUrl));
        if (mounted) Navigator.pop(context, "sent");
      } else {
        throw "Could not launch $mailUrl";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'ouvrir votre application de messagerie")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mail_outline, color: Color(0xFF49F6C7)),
              const SizedBox(width: 10),
              Text("Relance Client",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            ],
          ),
          if (widget.invoice.reminderDates.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "${widget.invoice.reminderDates.length} relance(s) déjà envoyée(s)",
                style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      content: _isLoading
          ? const SizedBox(height: 150, child: Center(child: CircularProgressIndicator(color: Color(0xFF49F6C7))))
          : Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_customerEmail != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text("À : $_customerEmail", 
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
          TextField(
            controller: _controller,
            maxLines: 10,
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: isDark ? const Color(0xFF232435) : Colors.grey[50],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("ANNULER", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF49F6C7),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          onPressed: _isLoading ? null : _sendEmail,
          child: const Text("ENVOYER L'EMAIL", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
