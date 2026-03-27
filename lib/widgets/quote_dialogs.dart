import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../models/account.dart';
import '../models/entity.dart';
import '../models/supplier.dart';

void showQuoteDialog({
  required BuildContext context,
  Invoice? quoteToEdit,
  required List<Supplier> suppliers,
  required List<Entity> entities,
  required List<Account> accounts,
  required Function(Invoice) onSave,
}) {
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
  String? paymentTerms = quoteToEdit?.paymentTerms ?? '30 jours';
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
                          ? 'Nouveau Devis'
                          : 'Modifier Devis',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),

                      // Émetteur et Devise
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: entities.any((e) => e.id == entityId)
                                  ? entityId
                                  : null,
                              items: entities
                                  .map((e) =>
                                  DropdownMenuItem(
                                      value: e.id, child: Text(e.name)))
                                  .toList(),
                              onChanged: (v) => setS(() => entityId = v),
                              decoration: const InputDecoration(
                                  labelText: 'Émetteur *'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedCurrency,
                              items: ['EUR', 'USD', 'GBP', 'CHF']
                                  .map((c) =>
                                  DropdownMenuItem(value: c, child: Text(c)))
                                  .toList(),
                              onChanged: (v) =>
                                  setS(() => selectedCurrency = v!),
                              decoration: const InputDecoration(
                                  labelText: 'Devise'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Client
                      DropdownButtonFormField<String>(
                        value: suppliers.any((s) => s.id == selectedPartnerId)
                            ? selectedPartnerId
                            : null,
                        items: suppliers
                            .map((s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name)))
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
                        decoration: const InputDecoration(
                            labelText: 'Client *'),
                      ),
                      const SizedBox(height: 16),

                      // Compte de Produit
                      DropdownButtonFormField<String>(
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
                        decoration: const InputDecoration(
                            labelText: 'Compte de produit (Vente)'),
                      ),
                      const SizedBox(height: 16),

                      TextField(controller: numC,
                          decoration: const InputDecoration(
                              labelText: 'N° devis *')),
                      const SizedBox(height: 16),
                      TextField(controller: desC,
                          decoration: const InputDecoration(
                              labelText: 'Désignation (Titre)')),
                      const SizedBox(height: 16),

                      // Description longue
                      TextField(
                        controller: longDescC,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Description détaillée (Détails prestations)',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Montants
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: htC,
                              keyboardType: const TextInputType
                                  .numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                  labelText: 'Montant HT *'),
                              onChanged: (v) => setS(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<double>(
                              value: [20.0, 10.0, 5.5, 0.0].contains(tvaR)
                                  ? tvaR
                                  : 20.0,
                              items: [20.0, 10.0, 5.5, 0.0].map((t) =>
                                  DropdownMenuItem(
                                      value: t, child: Text('$t%'))).toList(),
                              onChanged: (v) => setS(() => tvaR = v ?? 20.0),
                              decoration: const InputDecoration(
                                  labelText: 'TVA'),
                            ),
                          ),
                        ],
                      ),

                      // Affichage TTC
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("TOTAL TTC :",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              "${((double.tryParse(
                                  htC.text.replaceAll(',', '.')) ?? 0) * (1 +
                                  tvaR / 100)).toStringAsFixed(
                                  2)} $selectedCurrency",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
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
                              paymentTerms: paymentTerms ?? '30 jours',
                              expenseAccount: selectedProductAccount,
                              status: quoteToEdit?.status ??
                                  InvoiceStatus.draft,
                            );
                            onSave(newQuote);
                            Navigator.pop(context);
                          },
                          child: const Text('ENREGISTRER LE DEVIS'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ),
  );
}