import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../models/account_fr.dart';
import '../models/entity.dart';
import '../models/supplier.dart';
import '../l10n/app_localizations.dart';

const Color primaryColor = Color(0xFF49F6C7);

InputDecoration _getInputDecoration(String label, {bool isDark = false, bool dense = false, Widget? suffixIcon}) {
  return InputDecoration(
    labelText: label,
    isDense: dense,
    suffixIcon: suffixIcon,
    labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12),
    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: dense ? 10 : 14),
  );
}

void showQuoteDialog({
  required BuildContext context,
  Invoice? quoteToEdit,
  required List<Supplier> suppliers,
  required List<Entity> entities,
  required List<Account> accounts,
  required Function(Invoice) onSave,
}) {
  final t = AppLocalizations.of(context);
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  
  // 1. Initialisation des données
  String? entityId = quoteToEdit?.entityId ??
      (entities.isNotEmpty ? entities.first.id : null);
  String? selectedPartnerId = quoteToEdit?.supplierOrClientId;
  String currentPartnerName = quoteToEdit?.supplierOrClientName ?? '';

  // Gestion de la description (on sépare le titre de la description longue)
  List<String> descParts = (quoteToEdit?.designation ?? '').split('|');
  TextEditingController desC = TextEditingController(text: descParts[0]);
  TextEditingController longDescC = TextEditingController(
      text: descParts.length > 1 ? descParts[1] : '');

  // Nouveaux champs
  String selectedCurrency = 'EUR';
  String? selectedProductAccount = quoteToEdit?.expenseAccount;

  TextEditingController numC = TextEditingController(
      text: quoteToEdit?.number ?? '');
  TextEditingController htC = TextEditingController(
      text: quoteToEdit?.amountHT.toString() ?? '0');

  DateTime quoteDate = quoteToEdit?.date ?? DateTime.now();
  String? paymentTerms = quoteToEdit?.paymentTerms ?? t.thirtyDays;
  double tvaR = 20.0;

  // Filtrer les comptes de produits (Classe 7)
  final productAccounts = accounts
      .where((a) => a.number.startsWith('7'))
      .toList();
  if (selectedProductAccount == null && productAccounts.isNotEmpty) {
    selectedProductAccount = productAccounts.any((a) => a.number == '707')
        ? '707'
        : productAccounts.first.number;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) =>
        StatefulBuilder(
          builder: (ctx, setS) =>
              Container(
                padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery
                    .of(ctx)
                    .viewInsets
                    .bottom + 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(quoteToEdit == null
                          ? t.newQuote
                          : t.edit,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                      const SizedBox(height: 24),

                      // Émetteur et Devise
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              isDense: true,
                              dropdownColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              value: entities.any((e) => e.id == entityId)
                                  ? entityId
                                  : null,
                              items: entities
                                  .map((e) =>
                                  DropdownMenuItem(
                                      value: e.id, child: Text(e.name, style: const TextStyle(fontSize: 11))))
                                  .toList(),
                              onChanged: (v) => setS(() => entityId = v),
                              decoration: _getInputDecoration(t.issuer + ' *', isDark: isDark, dense: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              isDense: true,
                              dropdownColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              value: selectedCurrency,
                              items: ['EUR', 'USD', 'GBP', 'CHF']
                                  .map((c) =>
                                  DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 11))))
                                  .toList(),
                              onChanged: (v) =>
                                  setS(() => selectedCurrency = v!),
                              decoration: _getInputDecoration(t.currency, isDark: isDark, dense: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Client
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        isDense: true,
                        dropdownColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        value: suppliers.any((s) => s.id == selectedPartnerId)
                            ? selectedPartnerId
                            : null,
                        items: suppliers
                            .map((s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name, style: const TextStyle(fontSize: 11))))
                            .toList(),
                        onChanged: (v) {
                          setS(() {
                            selectedPartnerId = v;
                            if (v != null) {
                              final s = suppliers.firstWhere((s) => s.id == v);
                              currentPartnerName = s.name;
                              paymentTerms = s.paymentTerms;
                            }
                          });
                        },
                        decoration: _getInputDecoration(t.customers + ' *', isDark: isDark, dense: true),
                      ),
                      const SizedBox(height: 16),

                      // Compte de Produit
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        isDense: true,
                        dropdownColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        value: productAccounts.any((a) =>
                        a.number == selectedProductAccount)
                            ? selectedProductAccount
                            : null,
                        items: productAccounts.map((a) =>
                            DropdownMenuItem(
                                value: a.number,
                                child: Text("${a.number} - ${a.name}",
                                    style: const TextStyle(fontSize: 11))
                            )).toList(),
                        onChanged: (v) =>
                            setS(() => selectedProductAccount = v),
                        decoration: _getInputDecoration(t.chartOfAccounts, isDark: isDark, dense: true),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: numC,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: _getInputDecoration(t.quotes + ' N° *', isDark: isDark, dense: true)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: desC,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: _getInputDecoration(t.label + ' (Titre)', isDark: isDark, dense: true)),
                      const SizedBox(height: 16),

                      // Description longue
                      TextField(
                        controller: longDescC,
                        maxLines: 4,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: _getInputDecoration(t.description + ' (Détails)', isDark: isDark, dense: true),
                      ),
                      const SizedBox(height: 16),

                      // Montants
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: htC,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              keyboardType: const TextInputType
                                  .numberWithOptions(decimal: true),
                              decoration: _getInputDecoration(t.totalHT + ' *', isDark: isDark, dense: true),
                              onChanged: (v) => setS(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<double>(
                              isExpanded: true,
                              isDense: true,
                              dropdownColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              value: [20.0, 10.0, 5.5, 0.0].contains(tvaR)
                                  ? tvaR
                                  : 20.0,
                              items: [20.0, 10.0, 5.5, 0.0].map((val) =>
                                  DropdownMenuItem(
                                      value: val, child: Text('$val%', style: const TextStyle(fontSize: 11)))).toList(),
                              onChanged: (v) => setS(() => tvaR = v ?? 20.0),
                              decoration: _getInputDecoration(t.tva_label, isDark: isDark, dense: true),
                            ),
                          ),
                        ],
                      ),

                      // Affichage TTC
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(t.totalTTC + ' :',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            Text(
                              "${((double.tryParse(
                                  htC.text.replaceAll(',', '.')) ?? 0) * (1 +
                                  tvaR / 100)).toStringAsFixed(
                                  2)} $selectedCurrency",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                  fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            if (entityId == null || selectedPartnerId == null ||
                                numC.text.isEmpty) return;
                            final ht = double.tryParse(htC.text.replaceAll(',',
                                '.')) ?? 0.0;
                            final tva = ht * (tvaR / 100);

                            final newQuote = Invoice(
                              id: quoteToEdit?.id ?? 'q-${DateTime
                                  .now()
                                  .millisecondsSinceEpoch}',
                              type: InvoiceType.vente,
                              number: numC.text,
                              date: quoteDate,
                              entityId: entityId!,
                              supplierOrClientId: selectedPartnerId!,
                              supplierOrClientName: currentPartnerName,
                              // On stocke Titre + Description séparés par un pipe |
                              designation: "${desC.text}|${longDescC.text}",
                              amountHT: ht,
                              tva: tva,
                              amountTTC: ht + tva,
                              paymentTerms: paymentTerms ?? t.thirtyDays,
                              expenseAccount: selectedProductAccount,
                              status: quoteToEdit?.status ??
                                  InvoiceStatus.draft,
                            );
                            onSave(newQuote);
                            Navigator.pop(context);
                          },
                          child: Text(t.save.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ),
  );
}
