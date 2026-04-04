import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../models/supplier.dart';
import '../models/journal_entry.dart';
import '../models/account.dart';
import '../models/entity.dart';
import '../models/payment.dart';
import '../services/api_service.dart';

class InvoiceDialogs {
  static const Color primaryColor = Color(0xFF49F6C7);
  static final ApiService _apiService = ApiService();

  /// --- 1. FORMULAIRE PARTENAIRE ---
  static Future<Supplier?> showPartnerForm({
    required BuildContext context,
    required InvoiceType type,
    Supplier? partner,
    required List<Account> accounts,
  }) async {
    final nameC = TextEditingController(text: partner?.name ?? "");
    final emailC = TextEditingController(text: partner?.email ?? "");
    final addrC = TextEditingController(text: partner?.address ?? "");
    final siretC = TextEditingController(text: partner?.siret ?? "");
    final vatinC = TextEditingController(text: partner?.vatin ?? "");
    String selectedTerms = partner?.paymentTerms ?? '30 jours';
    String selectedAccount = partner?.expenseAccount ?? (type == InvoiceType.achat ? '401' : '411');

    final partnerAccounts = accounts.where((a) => a.type == 'tiers' || a.number.startsWith('4')).toList();

    return await showDialog<Supplier>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(partner == null
              ? (type == InvoiceType.achat ? 'Nouveau fournisseur' : 'Nouveau client')
              : 'Modifier'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Nom / Raison Sociale *')),
                const SizedBox(height: 16),
                TextField(controller: emailC, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 16),
                TextField(controller: addrC, decoration: const InputDecoration(labelText: 'Adresse complète')),
                const SizedBox(height: 16),
                TextField(controller: siretC, decoration: const InputDecoration(labelText: 'SIRET (14 chiffres)')),
                const SizedBox(height: 16),
                TextField(controller: vatinC, decoration: const InputDecoration(labelText: 'N° TVA Intracommunautaire')),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: ['Immédiat', '15 jours', '30 jours', '45 jours fin de mois', '60 jours'].contains(selectedTerms) ? selectedTerms : '30 jours',
                  items: ['Immédiat', '15 jours', '30 jours', '45 jours fin de mois', '60 jours'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setS(() => selectedTerms = v!),
                  decoration: const InputDecoration(labelText: 'Conditions de paiement par défaut'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: partnerAccounts.any((a) => a.number == selectedAccount) ? selectedAccount : (partnerAccounts.isNotEmpty ? partnerAccounts.first.number : null),
                  items: partnerAccounts.map((a) => DropdownMenuItem(value: a.number, child: Text("${a.number} - ${a.name}"))).toList(),
                  onChanged: (v) => setS(() => selectedAccount = v!),
                  decoration: const InputDecoration(labelText: 'Compte comptable rattaché'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ANNULER')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () {
                if (nameC.text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Le nom est obligatoire")));
                  return;
                }
                Navigator.pop(
                  ctx,
                  Supplier(
                    id: partner?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameC.text,
                    email: emailC.text,
                    address: addrC.text,
                    siret: siretC.text,
                    vatin: vatinC.text,
                    paymentTerms: selectedTerms,
                    expenseAccount: selectedAccount,
                  ),
                );
              },
              child: const Text('ENREGISTRER', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  /// --- 2. FORMULAIRE FACTURE DÉTAILLÉ ---
  static void showInvoiceForm({
    required BuildContext context,
    required InvoiceType type,
    Invoice? invoiceToEdit,
    bool isReadOnly = false,
    required List<Entity> entities,
    required List<Supplier> partners,
    required List<Account> accounts,
    required List<Map<String, dynamic>> quotes,
    required Function(Invoice) onSave,
    required Function(String, double, String?, StateSetter) onTriggerIA,
  }) {
    final numC = TextEditingController(text: invoiceToEdit?.number ?? "");
    final desC = TextEditingController(text: invoiceToEdit?.designation ?? "");
    final htC = TextEditingController(text: invoiceToEdit?.amountHT.toString() ?? "");
    String? selectedPartnerId = invoiceToEdit?.supplierOrClientId;
    String? contact = invoiceToEdit?.supplierOrClientName;
    String? entityId = invoiceToEdit?.entityId ?? (entities.isNotEmpty ? entities.first.id : null);
    DateTime invoiceDate = invoiceToEdit?.date ?? DateTime.now();
    DateTime? dueDate = invoiceToEdit?.dueDate;
    double tvaR = invoiceToEdit != null ? (invoiceToEdit.tva / (invoiceToEdit.amountHT != 0 ? invoiceToEdit.amountHT : 1) * 100).roundToDouble() : 20.0;
    String curr = invoiceToEdit?.currency ?? 'EUR';
    String? selectedAccount = invoiceToEdit?.expenseAccount;
    String? paymentTerms = invoiceToEdit?.paymentTerms ?? '30 jours';
    String? linkedQuoteNumber = invoiceToEdit?.linkedQuoteNumber;

    List<Payment> localPayments = invoiceToEdit != null ? List.from(invoiceToEdit.payments) : [];

    final filteredAccounts = accounts.where((a) => type == InvoiceType.achat ? a.type == 'charge' : a.type == 'produit').toList();
    final bankAccounts = accounts.where((a) => a.type == 'banque' || a.number.startsWith('512')).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          double ht = double.tryParse(htC.text.replaceAll(',', '.')) ?? 0.0;
          double ttc = ht * (1 + tvaR / 100);
          double totalPaid = localPayments.fold(0.0, (sum, p) => sum + p.amountBaseCurrency);
          double remaining = double.parse((ttc - totalPaid).toStringAsFixed(2));

          void updateDueDate() {
            if (invoiceToEdit != null) return;
            if (paymentTerms == 'Immédiat') dueDate = invoiceDate;
            else if (paymentTerms == '15 jours') dueDate = invoiceDate.add(const Duration(days: 15));
            else if (paymentTerms == '30 jours') dueDate = invoiceDate.add(const Duration(days: 30));
            else dueDate = invoiceDate.add(const Duration(days: 30));
          }

          return Container(
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          invoiceToEdit == null
                              ? (type == InvoiceType.achat ? 'Nouvel achat' : 'Nouvelle vente')
                              : 'Modifier facture',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (totalPaid > 0 && remaining > 0.01)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(12)),
                          child: const Text("PAIEMENT PARTIEL", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      if (totalPaid > 0 && remaining <= 0.01)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                          child: const Text("SOLDE RÉGLÉ", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: entities.any((e) => e.id == entityId) ? entityId : (entities.isNotEmpty ? entities.first.id : null),
                    items: entities.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
                    onChanged: isReadOnly ? null : (v) => setS(() => entityId = v),
                    decoration: const InputDecoration(labelText: 'Émetteur (Entité) *'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: partners.any((p) => p.id == selectedPartnerId) ? selectedPartnerId : null,
                    items: partners.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                    onChanged: isReadOnly ? null : (v) {
                      setS(() {
                        selectedPartnerId = v;
                        final p = partners.firstWhere((p) => p.id == v);
                        contact = p.name;
                        paymentTerms = p.paymentTerms;
                        updateDueDate();
                      });
                    },
                    decoration: InputDecoration(labelText: type == InvoiceType.achat ? 'Fournisseur *' : 'Client *'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: ['Immédiat', '15 jours', '30 jours', '45 jours fin de mois', '60 jours'].contains(paymentTerms) ? paymentTerms : '30 jours',
                    items: ['Immédiat', '15 jours', '30 jours', '45 jours fin de mois', '60 jours'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: isReadOnly ? null : (v) { setS(() { paymentTerms = v; updateDueDate(); }); },
                    decoration: const InputDecoration(labelText: 'Conditions de paiement'),
                  ),
                  if (type == InvoiceType.vente) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: (linkedQuoteNumber != null && quotes.any((q) => q['number'].toString() == linkedQuoteNumber.toString())) ? linkedQuoteNumber.toString() : null,
                      items: [const DropdownMenuItem<String>(value: null, child: Text("Aucun devis lié")), ...quotes.map((q) => DropdownMenuItem<String>(value: q['number'].toString(), child: Text("Devis n° ${q['number']}")))],
                      onChanged: isReadOnly ? null : (v) => setS(() => linkedQuoteNumber = v),
                      decoration: const InputDecoration(labelText: 'Lier à un devis'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: isReadOnly ? null : () async {
                            final d = await showDatePicker(context: context, initialDate: invoiceDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (d != null) setS(() {
                              invoiceDate = d;
                              updateDueDate();
                            });
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Date facture *'),
                            child: Text(DateFormat('dd/MM/yyyy').format(invoiceDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: isReadOnly ? null : () async {
                            final d = await showDatePicker(context: context, initialDate: dueDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (d != null) setS(() => dueDate = d);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Échéance'),
                            child: Text(dueDate != null ? DateFormat('dd/MM/yyyy').format(dueDate!) : 'Choisir...'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: numC, readOnly: isReadOnly, decoration: const InputDecoration(labelText: 'N° facture *')),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: filteredAccounts.any((a) => a.number == selectedAccount) ? selectedAccount : (filteredAccounts.isNotEmpty ? filteredAccounts.first.number : null),
                    items: filteredAccounts.map((a) => DropdownMenuItem(value: a.number, child: Text(a.toString(), style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: isReadOnly ? null : (v) => setS(() => selectedAccount = v),
                    decoration: InputDecoration(labelText: type == InvoiceType.achat ? 'Compte de charge *' : 'Compte de produit *'),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: desC, readOnly: isReadOnly, decoration: const InputDecoration(labelText: 'Désignation')),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(flex: 3, child: Container(margin: const EdgeInsets.only(right: 8), child: TextField(controller: htC, readOnly: isReadOnly, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Montant HT *'), onChanged: (_) => setS(() {})))),
                    Expanded(flex: 2, child: _buildTaxDropdown(
                        value: tvaR,
                        isReadOnly: isReadOnly,
                        onChanged: (v) => setS(() => tvaR = v!)
                    )),
                  ]),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TOTAL TTC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Row(children: [
                              Text(ttc.toStringAsFixed(2), style: const TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              DropdownButton<String>(
                                value: ['EUR', 'USD', 'GBP', 'CHF'].contains(curr) ? curr : 'EUR',
                                dropdownColor: Colors.black, underline: Container(), style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                                items: ['EUR', 'USD', 'GBP', 'CHF'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                onChanged: isReadOnly ? null : (v) => setS(() => curr = v!),
                              ),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 15),
                        const Divider(color: Colors.grey, height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("RÉGLÉ : ${totalPaid.toStringAsFixed(2)} $curr", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12)),
                            Text("À PAYER : ${remaining.toStringAsFixed(2)} $curr", style: TextStyle(color: remaining > 0.01 ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (localPayments.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              children: localPayments.map((p) => ListTile(
                                dense: true,
                                leading: const Icon(Icons.check_circle, size: 16, color: primaryColor),
                                title: Text("${p.amount.toStringAsFixed(2)} ${p.currency} (${p.method})", style: const TextStyle(color: Colors.white, fontSize: 11)),
                                subtitle: Text("${DateFormat('dd/MM/yyyy').format(p.date)}${p.currency != curr ? ' (Taux: ${p.exchangeRate})' : ''}", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                trailing: isReadOnly ? null : IconButton(icon: const Icon(Icons.delete, size: 16, color: Colors.red), onPressed: () => setS(() => localPayments.remove(p))),
                              )).toList(),
                            ),
                          ),
                        if (!isReadOnly && remaining > 0.01)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, minimumSize: const Size(double.infinity, 36)),
                            onPressed: () => _showAddPaymentDialog(context, remaining, curr, bankAccounts, (amt, payCurr, rate, bankId, date) {
                              setS(() {
                                localPayments.add(Payment(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(), amount: amt, currency: payCurr, exchangeRate: rate, amountBaseCurrency: payCurr == curr ? amt : amt * rate, date: date, method: 'Virement', linkedInvoiceId: invoiceToEdit?.id ?? 'temp', type: type == InvoiceType.achat ? PaymentType.fournisseur : PaymentType.client, bankAccountId: bankId,
                                ));
                              });
                            }),
                            icon: const Icon(Icons.add, size: 18, color: Colors.black),
                            label: const Text("AJOUTER UN ACOMPTE / RÈGLEMENT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (!isReadOnly)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, minimumSize: const Size(double.infinity, 50)),
                      onPressed: () {
                        if (contact == null || entityId == null || selectedPartnerId == null || htC.text.isEmpty || numC.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez remplir les champs obligatoires (*)")));
                          return;
                        }
                        InvoiceStatus finalStatus = InvoiceStatus.pending;
                        if (totalPaid >= ttc - 0.01) finalStatus = InvoiceStatus.paid;
                        else if (totalPaid > 0) finalStatus = InvoiceStatus.partiallyPaid;
                        onSave(Invoice(id: invoiceToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(), number: numC.text, supplierOrClientName: contact!, supplierOrClientId: selectedPartnerId!, amountHT: ht, tva: ht * tvaR / 100, amountTTC: ttc, currency: curr, date: invoiceDate, dueDate: dueDate, type: type, entityId: entityId!, designation: desC.text, expenseAccount: selectedAccount, paymentTerms: paymentTerms, linkedQuoteNumber: linkedQuoteNumber, payments: localPayments, status: finalStatus));
                        Navigator.pop(ctx);
                      },
                      child: const Text('ENREGISTRER', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static void _showAddPaymentDialog(BuildContext context, double remaining, String baseCurrency, List<Account> bankAccounts, Function(double amt, String currency, double rate, String bankId, DateTime date) onAdd) {
    final amountC = TextEditingController(text: remaining.toStringAsFixed(2));
    final rateC = TextEditingController(text: "1.0");
    String selectedCurrency = baseCurrency;
    String? selectedBankId = bankAccounts.isNotEmpty ? bankAccounts.first.id : null;
    DateTime date = DateTime.now();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          double amt = double.tryParse(amountC.text.replaceAll(',', '.')) ?? 0.0;
          double rate = double.tryParse(rateC.text.replaceAll(',', '.')) ?? 1.0;
          double converted = selectedCurrency == baseCurrency ? amt : amt * rate;
          return AlertDialog(
            title: const Text("Ajouter un règlement"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Montant restant : ${remaining.toStringAsFixed(2)} $baseCurrency", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(flex: 2, child: TextField(controller: amountC, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: "Montant"), onChanged: (_) => setS(() {}))),
                    const SizedBox(width: 8),
                    Expanded(child: DropdownButtonFormField<String>(value: ['EUR', 'USD', 'GBP', 'CHF'].contains(selectedCurrency) ? selectedCurrency : 'EUR', items: ['EUR', 'USD', 'GBP', 'CHF'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setS(() => selectedCurrency = v!), decoration: const InputDecoration(labelText: "Devise"))),
                  ]),
                  if (selectedCurrency != baseCurrency) ...[
                    const SizedBox(height: 16),
                    TextField(controller: rateC, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: "Taux de change (1 $selectedCurrency = ? $baseCurrency)"), onChanged: (_) => setS(() {})),
                    const SizedBox(height: 16),
                    Container(padding: const EdgeInsets.all(8), color: Colors.grey[100], child: Text("Soit ${converted.toStringAsFixed(2)} $baseCurrency", style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(value: bankAccounts.any((a) => a.id == selectedBankId) ? selectedBankId : (bankAccounts.isNotEmpty ? bankAccounts.first.id : null), items: bankAccounts.map((a) => DropdownMenuItem(value: a.id, child: Text("${a.number} - ${a.name}"))).toList(), onChanged: (v) => setS(() => selectedBankId = v), decoration: const InputDecoration(labelText: "Compte bancaire")),
                  const SizedBox(height: 16),
                  InkWell(onTap: () async { final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2030)); if (d != null) setS(() => date = d); }, child: InputDecorator(decoration: const InputDecoration(labelText: "Date"), child: Text(DateFormat('dd/MM/yyyy').format(date)))),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANNULER")), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: primaryColor), onPressed: () { if (amt > 0 && selectedBankId != null) { onAdd(amt, selectedCurrency, rate, selectedBankId!, date); Navigator.pop(ctx); } }, child: const Text("AJOUTER", style: TextStyle(color: Colors.black)))],
          );
        },
      ),
    );
  }

  /// --- 3. DIALOGUE PAIEMENT (EXPRESS) ---
  static void showPaymentDialog({
    required BuildContext context,
    required Invoice invoice,
    required List<Account> accounts,
    required Function(String bankAccountId, DateTime paymentDate, double amount, String currency, double rate) onPaid,
  }) {
    String? selectedBankId;
    DateTime paymentDate = DateTime.now();
    double remaining = invoice.remainingAmount;
    final amountC = TextEditingController(text: remaining.toStringAsFixed(2));
    final rateC = TextEditingController(text: "1.0");
    String selectedCurrency = invoice.currency;
    final bankAccounts = accounts.where((a) => a.type == 'banque' || a.number.startsWith('512')).toList();
    if (bankAccounts.isNotEmpty) selectedBankId = bankAccounts.first.id;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          double amt = double.tryParse(amountC.text.replaceAll(',', '.')) ?? 0.0;
          double rate = double.tryParse(rateC.text.replaceAll(',', '.')) ?? 1.0;
          double converted = selectedCurrency == invoice.currency ? amt : amt * rate;
          return AlertDialog(
            title: Text(invoice.type == InvoiceType.achat ? "Règlement Fournisseur" : "Encaissement Client"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("N° ${invoice.number} - ${invoice.supplierOrClientName}", style: const TextStyle(fontSize: 12)),
                  const Divider(),
                  Row(children: [
                    Expanded(flex: 2, child: TextField(controller: amountC, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: "Montant payé"), onChanged: (_) => setS(() {}))),
                    const SizedBox(width: 8),
                    Expanded(child: DropdownButtonFormField<String>(value: ['EUR', 'USD', 'GBP', 'CHF'].contains(selectedCurrency) ? selectedCurrency : 'EUR', items: ['EUR', 'USD', 'GBP', 'CHF'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setS(() => selectedCurrency = v!), decoration: const InputDecoration(labelText: "Devise"))),
                  ]),
                  if (selectedCurrency != invoice.currency) ...[
                    const SizedBox(height: 16),
                    TextField(controller: rateC, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: "Taux de change (1 $selectedCurrency = ? ${invoice.currency})"), onChanged: (_) => setS(() {})),
                    const SizedBox(height: 16),
                    Container(padding: const EdgeInsets.all(8), width: double.infinity, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)), child: Text("Equivalent : ${converted.toStringAsFixed(2)} ${invoice.currency}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(value: bankAccounts.any((a) => a.id == selectedBankId) ? selectedBankId : (bankAccounts.isNotEmpty ? bankAccounts.first.id : null), items: bankAccounts.map((a) => DropdownMenuItem(value: a.id, child: Text("${a.number} - ${a.name}"))).toList(), onChanged: (v) => setS(() => selectedBankId = v), decoration: const InputDecoration(labelText: "Compte bancaire")),
                  const SizedBox(height: 16),
                  InkWell(onTap: () async { final d = await showDatePicker(context: context, initialDate: paymentDate, firstDate: DateTime(2020), lastDate: DateTime(2030)); if (d != null) setS(() => paymentDate = d); }, child: InputDecorator(decoration: const InputDecoration(labelText: "Date"), child: Text(DateFormat('dd/MM/yyyy').format(paymentDate)))),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANNULER")), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: primaryColor), onPressed: () { if (selectedBankId == null || amt <= 0) return; onPaid(selectedBankId!, paymentDate, amt, selectedCurrency, rate); Navigator.pop(ctx); }, child: const Text("VALIDER", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))],
          );
        },
      ),
    );
  }

  /// --- 5. FORMULAIRE SAISIE JOURNAL COMPTABLE (Style NetSuite) ---
  static void showJournalEntryForm({
    required BuildContext context,
    JournalEntry? entry,
    String? nextOdNumber,
    bool isReadOnly = false,
    required List<Entity> entities,
    required List<Account> accounts,
    required Function(JournalEntry) onSave,
  }) {
    final journalNumC = TextEditingController(text: entry?.journalNumber ?? nextOdNumber ?? "");
    String? entityId = entry?.entityId ?? (entities.isNotEmpty ? entities.first.id : null);
    DateTime entryDate = entry?.date ?? DateTime.now();

    // Logique NetSuite : Devise de la transaction et Taux
    String transactionCurrency = 'EUR';
    double exchangeRate = 1.0;
    final rateController = TextEditingController(text: "1.0");

    List<JournalLine> lines = entry != null ? List.from(entry.lines) : [
      JournalLine(accountCode: '', description: '', debit: 0, credit: 0),
      JournalLine(accountCode: '', description: '', debit: 0, credit: 0),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          double totalDebit = lines.fold(0, (sum, l) => sum + l.debit);
          double totalCredit = lines.fold(0, (sum, l) => sum + l.credit);
          bool isBalanced = (totalDebit - totalCredit).abs() < 0.01;

          Entity? currentEntity = entities.firstWhere((e) => e.id == entityId, orElse: () => entities.first);
          bool showExchangeRate = transactionCurrency != currentEntity.currency;

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Journal Entry', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // PRIMARY INFORMATION (Header)
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: DropdownButtonFormField<String>(
                              value: entityId,
                              decoration: const InputDecoration(labelText: 'Subsidiary (Entity) *', border: OutlineInputBorder()),
                              items: entities.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name, style: const TextStyle(fontSize: 12)))).toList(),
                              onChanged: isReadOnly ? null : (v) => setS(() => entityId = v),
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: InkWell(
                              onTap: isReadOnly ? null : () async {
                                final d = await showDatePicker(context: context, initialDate: entryDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
                                if (d != null) setS(() => entryDate = d);
                              },
                              child: InputDecorator(decoration: const InputDecoration(labelText: 'Date *', border: OutlineInputBorder()), child: Text(DateFormat('dd/MM/yyyy').format(entryDate))),
                            )),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: TextField(controller: journalNumC, readOnly: isReadOnly, decoration: const InputDecoration(labelText: 'Entry No.', border: OutlineInputBorder()))),
                            const SizedBox(width: 12),
                            Expanded(child: DropdownButtonFormField<String>(
                              value: transactionCurrency,
                              decoration: const InputDecoration(labelText: 'Currency', border: OutlineInputBorder()),
                              items: ['EUR', 'USD', 'GBP', 'CHF'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: isReadOnly ? null : (v) => setS(() { transactionCurrency = v!; }),
                            )),
                          ],
                        ),
                        if (showExchangeRate) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: rateController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: 'Exchange Rate (1 $transactionCurrency = ? ${currentEntity.currency})', border: const OutlineInputBorder()),
                            onChanged: (v) => exchangeRate = double.tryParse(v) ?? 1.0,
                          ),
                        ],

                        const SizedBox(height: 30),
                        const Text("LINES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
                        const Divider(),

                        // LINES (NetSuite Style)
                        ...lines.asMap().entries.map((item) {
                          int idx = item.key;
                          JournalLine line = item.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(flex: 3, child: DropdownButtonFormField<String>(
                                      value: accounts.any((a) => a.number == line.accountCode) ? line.accountCode : null,
                                      isExpanded: true,
                                      items: accounts.map((a) => DropdownMenuItem(value: a.number, child: Text("${a.number} ${a.name}", style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis))).toList(),
                                      onChanged: isReadOnly ? null : (v) => setS(() => lines[idx].accountCode = v!),
                                      decoration: const InputDecoration(labelText: "Account", isDense: true),
                                    )),
                                    const SizedBox(width: 8),
                                    if (!isReadOnly) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => setS(() => lines.removeAt(idx))),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  readOnly: isReadOnly,
                                  onChanged: (v) => line.description = v,
                                  decoration: const InputDecoration(labelText: "Memo (Line Description)", isDense: true),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(child: TextField(
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: "Debit", isDense: true, prefixText: ""),
                                      onChanged: (v) {
                                        setS(() {
                                          lines[idx].debit = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                                          if (lines[idx].debit > 0) lines[idx].credit = 0;
                                        });
                                      },
                                    )),
                                    const SizedBox(width: 12),
                                    Expanded(child: TextField(
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: "Credit", isDense: true),
                                      onChanged: (v) {
                                        setS(() {
                                          lines[idx].credit = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                                          if (lines[idx].credit > 0) lines[idx].debit = 0;
                                        });
                                      },
                                    )),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildTaxDropdown(
                                    value: line.tvaRate ?? 0.0,
                                    isReadOnly: isReadOnly,
                                    onChanged: (v) => setS(() => lines[idx].tvaRate = v),
                                    label: "Line Tax Code"
                                ),
                              ],
                            ),
                          );
                        }),

                        TextButton.icon(
                          onPressed: () => setS(() => lines.add(JournalLine(accountCode: '', description: '', debit: 0, credit: 0))),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text("Add New Line"),
                        ),
                        const SizedBox(height: 100), // Space for bottom bar
                      ],
                    ),
                  ),
                ),

                // BOTTOM SUMMARY BAR
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text("TOTALS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            Row(children: [
                              Text("D: ${totalDebit.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                              const SizedBox(width: 15),
                              Text("C: ${totalCredit.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                            ]),
                          ]),
                          if (isBalanced) const Icon(Icons.check_circle, color: Colors.green) else const Icon(Icons.warning, color: Colors.red),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isBalanced ? Colors.black : Colors.grey,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isBalanced ? () {
                          if (entityId == null || journalNumC.text.isEmpty) return;
                          onSave(JournalEntry(
                            id: entry?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                            date: entryDate,
                            journalNumber: journalNumC.text,
                            entityId: entityId!,
                            lines: lines,
                          ));
                          Navigator.pop(ctx);
                        } : null,
                        child: const Text('SAVE ENTRY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  /// --- 6. FORMULAIRE FNP (Facture Non Parvenue) ---
  static void showFnpForm({
    required BuildContext context,
    required List<Entity> entities,
    required List<Supplier> suppliers,
    required List<Account> accounts,
    required Function(Invoice) onSave,
  }) {
    final htC = TextEditingController();
    final desC = TextEditingController();
    String? entityId = entities.isNotEmpty ? entities.first.id : null;
    String? supplierId;
    String? supplierName;
    DateTime date = DateTime.now();
    String selectedAccount = "601";
    double tvaR = 20.0;
    final chargeAccounts = accounts.where((a) => a.type == 'charge').toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Nouvelle provision (FNP)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  value: entities.any((e) => e.id == entityId) ? entityId : (entities.isNotEmpty ? entities.first.id : null),
                  items: entities.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
                  onChanged: (v) => setS(() => entityId = v),
                  decoration: const InputDecoration(labelText: 'Émetteur (Entité) *'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: suppliers.any((s) => s.id == supplierId) ? supplierId : null,
                  items: suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                  onChanged: (v) { setS(() { supplierId = v; supplierName = suppliers.firstWhere((s) => s.id == v).name; }); },
                  decoration: const InputDecoration(labelText: 'Fournisseur concerné'),
                ),
                const SizedBox(height: 16),
                TextField(controller: desC, decoration: const InputDecoration(labelText: 'Désignation de la provision *')),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: chargeAccounts.any((a) => a.number == selectedAccount) ? selectedAccount : (chargeAccounts.isNotEmpty ? chargeAccounts.first.number : null),
                  items: chargeAccounts.map((a) => DropdownMenuItem(value: a.number, child: Text(a.toString(), style: const TextStyle(fontSize: 11)))).toList(),
                  onChanged: (v) => setS(() => selectedAccount = v!),
                  decoration: const InputDecoration(labelText: "Compte de charge"),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(flex: 3, child: Container(margin: const EdgeInsets.only(right: 8), child: TextField(controller: htC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Montant HT Estimé *')))),
                  Expanded(flex: 2, child: _buildTaxDropdown(
                      value: tvaR,
                      isReadOnly: false,
                      onChanged: (v) => setS(() => tvaR = v!)
                  )),
                ]),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, minimumSize: const Size(double.infinity, 50)),
                  onPressed: () {
                    if (entityId == null || htC.text.isEmpty || desC.text.isEmpty) return;
                    double ht = double.tryParse(htC.text) ?? 0;
                    onSave(Invoice(id: 'fnp-${DateTime.now().millisecondsSinceEpoch}', number: 'FNP-PROV', supplierOrClientName: supplierName ?? "Provision Diverses", supplierOrClientId: supplierId ?? 'unknown', amountHT: ht, tva: ht * tvaR / 100, amountTTC: ht * (1 + tvaR / 100), date: date, type: InvoiceType.achat, entityId: entityId!, designation: desC.text, expenseAccount: selectedAccount, status: InvoiceStatus.pending));
                    Navigator.pop(ctx);
                  },
                  child: const Text('ENREGISTRER PROVISION', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildTaxDropdown({
    required double? value,
    required bool isReadOnly,
    required void Function(double?) onChanged,
    String label = 'Tax Code',
  }) {
    final List<DropdownMenuItem<String>> items = [];
    String? selectedValue;

    void addGroup(String title, List<double> rates) {
      items.add(DropdownMenuItem<String>(
        enabled: false,
        value: "header:$title",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (items.isNotEmpty) const Divider(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
          ],
        ),
      ));
      for (var r in rates) {
        String val = "$title:$r";
        items.add(DropdownMenuItem<String>(value: val, child: Text("TVA $r %", style: const TextStyle(fontSize: 12))));
        if (selectedValue == null && value != null && (r - value).abs() < 0.001) {
          selectedValue = val;
        }
      }
    }

    addGroup("FRANCE (TVA FR)", _apiService.getTaxesForCountry("France"));
    addGroup("UK (VAT UK)", _apiService.getTaxesForCountry("UK"));
    addGroup("GERMANY (MwSt DE)", _apiService.getTaxesForCountry("Germany"));
    addGroup("USA (Sales Tax US)", _apiService.getTaxesForCountry("USA"));

    if (selectedValue == null && items.isNotEmpty) {
      for (var item in items) {
        if (item.value != null && !item.value!.startsWith("header:")) {
          selectedValue = item.value;
          break;
        }
      }
    }

    return DropdownButtonFormField<String>(
      value: selectedValue,
      items: items,
      onChanged: isReadOnly ? null : (v) {
        if (v != null && !v.startsWith("header:")) {
          final parts = v.split(':');
          if (parts.length > 1) {
            onChanged(double.tryParse(parts[1]));
          }
        }
      },
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }
}
