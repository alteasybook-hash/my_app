import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../models/invoice.dart';
import '../models/supplier.dart';
import '../models/journal_entry.dart';
import '../models/account_fr.dart';
import '../models/account_de.dart';
import '../models/account_uk.dart';
import '../models/account_us.dart';
import '../models/entity.dart';
import '../models/payment.dart';
import '../models/cost_center.dart';
import '../services/api_service.dart';

class InvoiceDialogs {
  static const Color primaryColor = Color(0xFF49F6C7);

  // Décoration réutilisable pour les champs de saisie
  static InputDecoration _getInputDecoration(String label,
      {bool isDark = false, bool dense = false, String? errorText, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      errorText: errorText,
      suffixIcon: suffixIcon,
      labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54,
          fontSize: dense ? 12 : 14),
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
      isDense: dense,
      contentPadding: dense ? const EdgeInsets.symmetric(
          horizontal: 12, vertical: 8) : null,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1)),
    );
  }

  // RECHERCHE DE COMPTE AVEC FILTRAGE PAR PLAN (UK, FR, etc.)
  static Future<String?> _showAccountSearch(BuildContext context, {
    String? initialValue,
    required List<Account> accounts,
    String? filterPlan,
  }) async {
    final t = AppLocalizations.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController searchC = TextEditingController();

    final List<Account> sourceAccounts = filterPlan != null
        ? accounts.where((a) => a.plan == filterPlan).toList()
        : accounts;

    List<Account> filtered = List.from(sourceAccounts);

    return await showDialog<String>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, setS) => AlertDialog(
                backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                title: Text(t.chartOfAccounts, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                content: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      TextField(
                      controller: searchC,
                      autofocus: true,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: _getInputDecoration(t.search, isDark: isDark, dense: true, suffixIcon: const Icon(Icons.search)),
                      onChanged: (v) {
                        setS(() {
                          filtered = sourceAccounts.where((a) {
                            final numMatch = a.number.contains(v);
                            final nameMatch = a.name.toLowerCase().contains(v.toLowerCase());
                            return numMatch || nameMatch;
                          }).toList();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) => ListTile(
                          dense: true,
                          title: Text(filtered[i].number, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                          subtitle: Text(filtered[i].name, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 11)),
                          onTap: () => Navigator.pop(ctx, filtered[i].number),
                        ),
                      ),
                    ),
                      ],
                    ),
                ),
            ),
        ),
    );
  }
    
  // FORMULAIRE FOURNISSEUR / CLIENT
  static Future<Supplier?> showPartnerForm({
    required BuildContext context,
    required InvoiceType type,
    Supplier? partner,
    required List<Entity> entities,
    required List<Account> accounts,
  }) async {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final nameC = TextEditingController(text: partner?.name ?? "");
    final emailC = TextEditingController(text: partner?.email ?? "");
    final addrC = TextEditingController(text: partner?.address ?? "");
    final siretC = TextEditingController(text: partner?.siret ?? "");
    final vatinC = TextEditingController(text: partner?.vatin ?? "");

    String? selectedEntityId = partner?.entityId ??
        (entities.isNotEmpty ? entities.first.id : null);
    String selectedTerms = partner?.paymentTerms ?? t.thirtyDays;
    String selectedAccount = partner?.expenseAccount ??
        (type == InvoiceType.achat ? '401000' : '411000');

    bool showErrors = false;
    Entity? selectedEntity = entities.isNotEmpty
        ? entities.firstWhere((e) => e.id == selectedEntityId,
        orElse: () => entities.first)
        : null;

    return await showDialog<Supplier>(
      context: context,
      builder: (ctx) =>
          StatefulBuilder(
            builder: (ctx, setS) {
              final nameError = showErrors && nameC.text.isEmpty
                  ? "Nom obligatoire"
                  : null;
              final entityError = showErrors && selectedEntityId == null
                  ? "L'entité est obligatoire"
                  : null;

              return AlertDialog(
                backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                title: Text(partner == null ? (type == InvoiceType.achat
                    ? t.suppliers
                    : t.customers) : t.edit,
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        isDense: true,
                        dropdownColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 13),
                        value: selectedEntityId,
                        hint: const Text("Sélectionner l'entité *",
                            style: TextStyle(fontSize: 12)),
                        items: entities
                            .map((e) =>
                            DropdownMenuItem(value: e.id,
                                child: Text(e.name,
                                    style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) {
                          setS(() {
                            selectedEntityId = v;
                            selectedEntity =
                                entities.firstWhere((e) => e.id == v);
                            if (partner == null && selectedEntity != null) {
                              final isFrance = selectedEntity?.accountingPlan?.contains("France") ?? false;
                              selectedAccount = (type == InvoiceType.achat
                                  ? (isFrance ? "401000" : "2100")
                                  : (isFrance ? "411000" : "1200"));
                            }
                          });
                        },
                        decoration: _getInputDecoration(
                            "Appartient à l'entité *", isDark: isDark,
                            dense: true,
                            errorText: entityError),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                          controller: nameC,
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black),
                          decoration: _getInputDecoration(
                              t.raisonSociale + ' *', isDark: isDark,
                              dense: true,
                              errorText: nameError)
                      ),
                      const SizedBox(height: 16),
                      TextField(controller: emailC,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black),
                          decoration: _getInputDecoration(
                              t.email, isDark: isDark, dense: true)),
                      const SizedBox(height: 16),
                      TextField(controller: addrC,
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black),
                          decoration: _getInputDecoration(
                              t.address, isDark: isDark, dense: true)),
                      const SizedBox(height: 16),
                      TextField(controller: siretC,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black),
                          decoration: _getInputDecoration(
                              t.siret, isDark: isDark, dense: true)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        isDense: true,
                        dropdownColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                        value: selectedTerms,
                        items: [
                          t.immediate,
                          t.fifteenDays,
                          t.thirtyDays,
                          t.fortyFiveDaysEOM,
                          t.sixtyDays
                        ].map((val) =>
                            DropdownMenuItem(value: val,
                                child: Text(val, style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                    fontSize: 11)))).toList(),
                        onChanged: (v) => setS(() => selectedTerms = v!),
                        decoration: _getInputDecoration(
                            t.paymentTerms, isDark: isDark, dense: true),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          final res = await _showAccountSearch(
                            context,
                            accounts: accounts,
                            filterPlan: selectedEntity?.accountingPlan,
                          );
                          if (res != null) setS(() => selectedAccount = res);
                        },
                        child: InputDecorator(
                          decoration: _getInputDecoration(
                              t.chartOfAccounts, isDark: isDark,
                              dense: true,
                              suffixIcon: const Icon(Icons.search, size: 18)),
                          child: Text(selectedAccount, style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx),
                      child: Text(t.cancel.toUpperCase())),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor),
                      onPressed: () {
                        if (nameC.text.isEmpty || selectedEntityId == null) {
                          setS(() => showErrors = true);
                          return;
                        }
                        Navigator.pop(ctx, Supplier(
                          id: partner?.id ?? DateTime
                              .now()
                              .millisecondsSinceEpoch
                              .toString(),
                          name: nameC.text,
                          email: emailC.text,
                          address: addrC.text,
                          siret: siretC.text,
                          vatin: vatinC.text,
                          paymentTerms: selectedTerms,
                          expenseAccount: selectedAccount,
                          entityId: selectedEntityId!,
                        ));
                      },
                      child: Text(t.save.toUpperCase(), style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold))
                  ),
                ],
              );
            },
          ),
    );
  }

  static void showInvoiceForm({
    required BuildContext context,
    required InvoiceType type,
    Invoice? invoiceToEdit,
    bool isReadOnly = false,
    required List<Entity> entities,
    required List<Supplier> partners,
    required List<Account> accounts,
    required List<Map<String, dynamic>> quotes,
    List<CostCenter> costCenters = const [],
    required Function(Invoice) onSave,
    required Function(String, double, String?, StateSetter) onTriggerIA,
  }) {
    final t = AppLocalizations.of(context);
    final numC = TextEditingController(text: invoiceToEdit?.number ?? "");
    final desC = TextEditingController(text: invoiceToEdit?.designation ?? "");
    final htC = TextEditingController(text: invoiceToEdit?.amountHT.toString() ?? "");
    
    String siren = invoiceToEdit?.siren ?? "";
    String address = invoiceToEdit?.address ?? "";
    String country = invoiceToEdit?.country ?? "";

    String? entityId = invoiceToEdit?.entityId ?? (entities.isNotEmpty ? entities.first.id : null);
    List<Supplier> filteredPartners = partners.where((p) => p.entityId == entityId).toList();
    
    String? selectedPartnerId = invoiceToEdit?.supplierOrClientId;
    if (selectedPartnerId != null && !filteredPartners.any((p) => p.id == selectedPartnerId)) {
      selectedPartnerId = null;
    }

    String? contact = invoiceToEdit?.supplierOrClientName;
    DateTime invoiceDate = invoiceToEdit?.date ?? DateTime.now();
    DateTime? dueDate = invoiceToEdit?.dueDate;
    double tvaR = invoiceToEdit != null ? (invoiceToEdit.tva / (invoiceToEdit.amountHT != 0 ? invoiceToEdit.amountHT : 1) * 100).roundToDouble() : 20.0;
    String curr = invoiceToEdit?.currency ?? 'EUR';
    String? selectedAccount = invoiceToEdit?.expenseAccount;
    String? paymentTerms = invoiceToEdit?.paymentTerms ?? t.thirtyDays;
    String? linkedQuoteNumber = invoiceToEdit?.linkedQuoteNumber;
    String? selectedCostCenter = invoiceToEdit?.costCenterCode;
    String? paymentMethod = invoiceToEdit?.paymentMethod ?? "Virement";

    List<Payment> localPayments = invoiceToEdit != null ? List.from(invoiceToEdit.payments) : [];
    List<InvoiceItem> localItems = invoiceToEdit != null ? List.from(invoiceToEdit.items) : [];

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final currentEntity = entities.cast<Entity?>().firstWhere(
                (e) => e?.id == entityId,
            orElse: () => null,
          );

          if (currentEntity != null) {
            siren = currentEntity.idNumber;
            address = currentEntity.address;
            country = currentEntity.country;
          }

          double calculatedHT = localItems.fold(0, (sum, item) => sum + item.totalHT);
          if (localItems.isNotEmpty) {
            htC.text = calculatedHT.toStringAsFixed(2);
          }

          double ht = double.tryParse(htC.text.replaceAll(',', '.')) ?? 0.0;
          double ttc = localItems.isNotEmpty 
              ? localItems.fold(0, (sum, item) => sum + item.totalTTC)
              : ht * (1 + tvaR / 100);
          
          double totalPaid = localPayments.fold(0.0, (sum, p) => sum + p.amountBaseCurrency);
          double remaining = double.parse((ttc - totalPaid).toStringAsFixed(2));

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.9,
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(invoiceToEdit == null ? (type == InvoiceType.achat ? t.achats : t.ventes) : t.edit, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  IconButton(icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black), onPressed: () => Navigator.pop(ctx)),
                ]),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(children: [
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        isDense: true,
                        dropdownColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        value: entityId,
                        items: entities.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: isReadOnly ? null : (v) => setS(() {
                          entityId = v;
                          final newEntity = entities.firstWhere((e) => e.id == v);
                          filteredPartners = partners.where((p) => p.entityId == entityId).toList();
                          if (selectedPartnerId != null && !filteredPartners.any((p) => p.id == selectedPartnerId)) {
                            selectedPartnerId = null;
                          }
                          if (invoiceToEdit == null && newEntity != null) {
                            country = newEntity.country;
                            curr = newEntity.currency;
                             selectedAccount = type == InvoiceType.vente 
                                ? newEntity.defaultSaleAccount 
                                : newEntity.defaultPurchaseAccount;
                          }
                        }),
                        decoration: _getInputDecoration("Entité émettrice", isDark: isDark, dense: true),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text("SIREN: $siren", style: TextStyle(fontSize: 10, color: isDark ? Colors.grey : Colors.black54)),
                          Text("Adresse: $address", style: TextStyle(fontSize: 10, color: isDark ? Colors.grey : Colors.black54)),
                          Text("Pays: $country", style: TextStyle(fontSize: 10, color: isDark ? Colors.grey : Colors.black54)),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        isDense: true,
                        dropdownColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        value: selectedPartnerId,
                        hint: Text(type == InvoiceType.achat ? "Choisir un fournisseur..." : "Choisir un client...", style: const TextStyle(fontSize: 11)),
                        items: filteredPartners.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: isReadOnly ? null : (v) { 
                          setS(() { 
                            selectedPartnerId = v; 
                            final p = filteredPartners.firstWhere((p) => p.id == v); 
                            contact = p.name; 
                            paymentTerms = p.paymentTerms; 
                            selectedAccount = p.expenseAccount;
                          }); 
                        },
                        decoration: _getInputDecoration(type == InvoiceType.achat ? t.supplier_label + ' *' : t.customers + ' *', isDark: isDark, dense: true),
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: InkWell(borderRadius: BorderRadius.circular(8), onTap: isReadOnly ? null : () async { final d = await showDatePicker(context: context, initialDate: invoiceDate, firstDate: DateTime(2020), lastDate: DateTime(2030)); if (d != null) setS(() { invoiceDate = d; }); }, child: InputDecorator(decoration: _getInputDecoration(t.dateLabel + ' *', isDark: isDark, dense: true), child: Text(DateFormat('dd/MM/yyyy').format(invoiceDate), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 11))))),
                        const SizedBox(width: 8),
                        Expanded(child: InkWell(borderRadius: BorderRadius.circular(8), onTap: isReadOnly ? null : () async { final d = await showDatePicker(context: context, initialDate: dueDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030)); if (d != null) setS(() => dueDate = d); }, child: InputDecorator(decoration: _getInputDecoration(t.upcoming, isDark: isDark, dense: true), child: Text(dueDate != null ? DateFormat('dd/MM/yyyy').format(dueDate!) : 'Choisir...', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 11))))),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: TextField(controller: numC, readOnly: isReadOnly, style: TextStyle(color: isDark ? Colors.white : Colors.black), decoration: _getInputDecoration(t.invNumber + ' *', isDark: isDark, dense: true))),
                        const SizedBox(width: 8),
                        Expanded(child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          isDense: true,
                          dropdownColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          value: paymentMethod,
                          items: ["Virement", "CB", "Espèces", "Prélèvement"].map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 11)))).toList(),
                          onChanged: isReadOnly ? null : (v) => setS(() => paymentMethod = v),
                          decoration: _getInputDecoration("Mode paiement", isDark: isDark, dense: true),
                        )),
                      ]),
                      const SizedBox(height: 12),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text("Détails (Produits)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        if (!isReadOnly) TextButton.icon(onPressed: () => _addInvoiceItem(context, isDark, (newItem) => setS(() => localItems.add(newItem))), icon: const Icon(Icons.add, size: 16), label: const Text("Ajouter ligne", style: TextStyle(fontSize: 11))),
                      ]),
                      if (localItems.isNotEmpty)
                        Column(children: localItems.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          return ListTile(
                            dense: true,
                            title: Text(item.product, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            subtitle: Text("Qté: ${item.quantity} x ${item.unitPriceHT} ${curr}", style: const TextStyle(fontSize: 10)),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text("${item.totalTTC.toStringAsFixed(2)} ${curr}", style: const TextStyle(fontSize: 11)),
                              if (!isReadOnly) IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => setS(() => localItems.removeAt(idx))),
                            ]),
                          );
                        }).toList()),
                      const SizedBox(height: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: isReadOnly ? null : () async {
                          final res = await _showAccountSearch(context, accounts: accounts);
                          if (res != null) setS(() => selectedAccount = res);
                        },
                        child: InputDecorator(
                          decoration: _getInputDecoration(t.chartOfAccounts + ' *', isDark: isDark, dense: true, suffixIcon: const Icon(Icons.search, size: 18)),
                          child: Text(selectedAccount ?? "Sélect. un compte", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 11)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: desC, readOnly: isReadOnly, style: TextStyle(color: isDark ? Colors.white : Colors.black), decoration: _getInputDecoration(t.desc_label, isDark: isDark, dense: true)),
                      const SizedBox(height: 12),
                      if (localItems.isEmpty)
                        Row(children: [
                          Expanded(flex: 3, child: TextField(controller: htC, readOnly: isReadOnly, style: TextStyle(color: isDark ? Colors.white : Colors.black), keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _getInputDecoration(t.ht_label + ' *', isDark: isDark, dense: true), onChanged: (_) => setS(() {}))),
                          const SizedBox(width: 8),
                          Expanded(flex: 2, child: _buildTaxDropdown(value: tvaR, isReadOnly: isReadOnly, isDark: isDark, onChanged: (v) => setS(() => tvaR = v!), label: t.tva_label)),
                        ]),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                        child: Column(children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(t.totalTTC, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            Row(children: [
                              Text(ttc.toStringAsFixed(2), style: const TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              DropdownButton<String>(value: curr, dropdownColor: Colors.black, underline: Container(), style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14), items: ['EUR', 'USD', 'GBP', 'CHF', 'FCFA'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: isReadOnly ? null : (v) => setS(() => curr = v!)),
                            ]),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      if (!isReadOnly)
                        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: primaryColor, minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () { 
                          if (contact == null || entityId == null || selectedPartnerId == null || (localItems.isEmpty && htC.text.isEmpty) || numC.text.isEmpty) return; 
                          onSave(Invoice(
                            id: invoiceToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(), 
                            number: numC.text, 
                            supplierOrClientName: contact!, 
                            supplierOrClientId: selectedPartnerId!, 
                            amountHT: ht, 
                            tva: localItems.isNotEmpty ? (localItems.fold(0, (sum, i) => sum + (i.totalTTC - i.totalHT))) : (ht * tvaR / 100), 
                            amountTTC: ttc, 
                            currency: curr, 
                            date: invoiceDate, 
                            dueDate: dueDate, 
                            type: type, 
                            entityId: entityId!, 
                            designation: desC.text, 
                            expenseAccount: selectedAccount, 
                            paymentTerms: paymentTerms, 
                            paymentMethod: paymentMethod,
                            items: localItems,
                            siren: siren,
                            address: address,
                            country: country,
                            linkedQuoteNumber: linkedQuoteNumber, 
                            payments: localPayments, 
                            costCenterCode: selectedCostCenter, 
                            status: (totalPaid >= ttc - 0.01) ? InvoiceStatus.paid : (totalPaid > 0 ? InvoiceStatus.partiallyPaid : InvoiceStatus.pending)
                          )); 
                          Navigator.pop(ctx); 
                        }, child: Text(t.save.toUpperCase(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static void _addInvoiceItem(BuildContext context, bool isDark, Function(InvoiceItem) onAdded) {
    final prodC = TextEditingController();
    final qteC = TextEditingController(text: "1");
    final pxC = TextEditingController();
    double tva = 20.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          title: const Text("Ajouter une ligne"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: prodC, decoration: _getInputDecoration("Désignation", isDark: isDark, dense: true)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: qteC, keyboardType: TextInputType.number, decoration: _getInputDecoration("Quantité", isDark: isDark, dense: true))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: pxC, keyboardType: TextInputType.number, decoration: _getInputDecoration("Prix Unitaire HT", isDark: isDark, dense: true))),
              ]),
              const SizedBox(height: 12),
              _buildTaxDropdown(value: tva, isReadOnly: false, isDark: isDark, onChanged: (v) => setS(() => tva = v!), label: "TVA"),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANNULER")),
            ElevatedButton(onPressed: () {
              final q = double.tryParse(qteC.text) ?? 1;
              final p = double.tryParse(pxC.text) ?? 0;
              onAdded(InvoiceItem(product: prodC.text, quantity: q, unitPriceHT: p, tvaRate: tva));
              Navigator.pop(ctx);
            }, child: const Text("AJOUTER")),
          ],
        ),
      ),
    );
  }

  static void showPaymentDialog({
    required BuildContext context,
    required Invoice invoice,
    required List<Account> accounts,
    required Function(String, DateTime, double, String, double) onPaid,
  }) {
    final t = AppLocalizations.of(context);
    final amtC = TextEditingController(text: invoice.remainingAmount.toStringAsFixed(2));
    final rateC = TextEditingController(text: "1.0");
    DateTime payDate = DateTime.now();
    String curr = invoice.currency;
    String? bankId;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.applyPaymentAction, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(controller: amtC, keyboardType: TextInputType.number, decoration: _getInputDecoration(t.amount_label, isDark: isDark)),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: payDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (d != null) setS(() => payDate = d);
                },
                child: InputDecorator(decoration: _getInputDecoration(t.dateLabel, isDark: isDark), child: Text(DateFormat('dd/MM/yyyy').format(payDate))),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: bankId,
                items: accounts.where((a) => a.number.startsWith('512')).map((a) => DropdownMenuItem(value: a.number, child: Text("${a.number} - ${a.name}", style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (v) => setS(() => bankId = v),
                decoration: _getInputDecoration("Compte Bancaire", isDark: isDark),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, minimumSize: const Size(double.infinity, 48)),
                onPressed: () {
                  if (bankId == null) return;
                  final amt = double.tryParse(amtC.text) ?? 0;
                  final rate = double.tryParse(rateC.text) ?? 1.0;
                  onPaid(bankId!, payDate, amt, curr, rate);
                  Navigator.pop(ctx);
                },
                child: Text(t.validate.toUpperCase(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showFnpForm({
    required BuildContext context,
    required List<Entity> entities,
    required List<Supplier> suppliers,
    required List<Account> accounts,
    required Function(Invoice) onSave,
  }) {
    final t = AppLocalizations.of(context);
    final desC = TextEditingController();
    final htC = TextEditingController();
    String? entId = entities.isNotEmpty ? entities.first.id : null;
    String? supId;
    String? accId;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.fnp_label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: entId,
                items: entities.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
                onChanged: (v) => setS(() => entId = v),
                decoration: _getInputDecoration("Entité", isDark: isDark),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: supId,
                items: suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                onChanged: (v) => setS(() => supId = v),
                decoration: _getInputDecoration(t.supplier_label, isDark: isDark),
              ),
              const SizedBox(height: 12),
              TextField(controller: desC, decoration: _getInputDecoration(t.desc_label, isDark: isDark)),
              const SizedBox(height: 12),
              TextField(controller: htC, keyboardType: TextInputType.number, decoration: _getInputDecoration(t.ht_label, isDark: isDark)),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final res = await _showAccountSearch(context, accounts: accounts);
                  if (res != null) setS(() => accId = res);
                },
                child: InputDecorator(decoration: _getInputDecoration(t.chartOfAccounts, isDark: isDark), child: Text(accId ?? "Choisir...")),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, minimumSize: const Size(double.infinity, 48)),
                onPressed: () {
                  if (entId == null || supId == null || accId == null) return;
                  final ht = double.tryParse(htC.text) ?? 0;
                  final sup = suppliers.firstWhere((s) => s.id == supId);
                  onSave(Invoice(
                    id: "FNP-${DateTime.now().millisecondsSinceEpoch}",
                    number: "FNP-${DateFormat('yyyyMM').format(DateTime.now())}",
                    supplierOrClientName: sup.name,
                    supplierOrClientId: sup.id,
                    amountHT: ht,
                    tva: ht * 0.2,
                    amountTTC: ht * 1.2,
                    date: DateTime.now(),
                    type: InvoiceType.achat,
                    entityId: entId!,
                    designation: desC.text,
                    expenseAccount: accId,
                    status: InvoiceStatus.pending,
                  ));
                  Navigator.pop(ctx);
                },
                child: Text(t.save.toUpperCase(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- FORMULAIRE DE SAISIE DE JOURNAL (OD) ---
  static void showJournalEntryForm({
    required BuildContext context,
    JournalEntry? entry,
    String? nextOdNumber,
    bool isReadOnly = false,
    required List<Entity> entities,
    required List<Account> accounts,
    required List<Supplier> partners,
    List<CostCenter> costCenters = const [],
    required Function(JournalEntry) onSave,
    Function(String)? onEntityChanged,
  }) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    DateTime entryDate = entry?.date ?? DateTime.now();
    String? entityId = entry?.entityId ?? (entities.isNotEmpty ? entities.first.id : null);
    String journalNumber = entry?.journalNumber ?? nextOdNumber ?? "OD-0001";
    final _journalNumberController = TextEditingController(text: journalNumber);
    String? reference = entry?.reference;
    String selectedCurrency = entry?.currency ?? 'EUR';

    List<JournalLine> lines = entry != null ? List.from(entry.lines) : [
      JournalLine(accountCode: '', description: '', debit: 0, credit: 0),
      JournalLine(accountCode: '', description: '', debit: 0, credit: 0),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {

          double totalDebit = lines.fold(0, (sum, l) => sum + l.debit);
          double totalCredit = lines.fold(0, (sum, l) => sum + l.credit);
          double diff = (totalDebit - totalCredit).abs();
          bool isBalanced = diff < 0.01;

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.9,
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(entry == null ? t.journal_entries : t.edit, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  IconButton(icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black), onPressed: () => Navigator.pop(ctx)),
                ]),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(children: [
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        isDense: true,
                        dropdownColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13),
                        value: entityId,
                        items: entities.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
                        onChanged: isReadOnly ? null : (v) {
                          setS(() => entityId = v);
                          if (onEntityChanged != null && v != null) onEntityChanged(v);
                        },
                        decoration: _getInputDecoration("Entité", isDark: isDark, dense: true),
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: InkWell(
                          onTap: isReadOnly ? null : () async {
                            final d = await showDatePicker(context: context, initialDate: entryDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (d != null) setS(() => entryDate = d);
                          },
                          child: InputDecorator(decoration: _getInputDecoration(t.dateLabel, isDark: isDark, dense: true), child: Text(DateFormat('dd/MM/yyyy').format(entryDate), style: const TextStyle(fontSize: 12))),
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(
                          readOnly: true,
                          onChanged: (v) => journalNumber = v,
                          controller: _journalNumberController,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 12),
                          decoration: _getInputDecoration("N° Journal (Généré auto)", isDark: isDark, dense: true),
                        )),
                      ]),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        isDense: true,
                        dropdownColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13),
                        value: selectedCurrency,
                        items: ['EUR', 'USD', 'GBP', 'CHF', 'FCFA'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: isReadOnly ? null : (v) => setS(() => selectedCurrency = v!),
                        decoration: _getInputDecoration("Devise", isDark: isDark, dense: true),
                      ),
                      const SizedBox(height: 20),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text("LIGNES D'ÉCRITURE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        if (!isReadOnly) TextButton.icon(onPressed: () => setS(() => lines.add(JournalLine(accountCode: '', description: ''))), icon: const Icon(Icons.add, size: 16), label: const Text("Ajouter ligne", style: TextStyle(fontSize: 11))),
                      ]),
                      const SizedBox(height: 8),
                      ...lines.asMap().entries.map((entryLine) {
                        int idx = entryLine.key;
                        JournalLine line = entryLine.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!)),
                          child: Column(children: [
                            Row(children: [
                              Expanded(flex: 2, child: InkWell(
                                onTap: isReadOnly ? null : () async {
                                  final res = await _showAccountSearch(context, accounts: accounts);
                                  if (res != null) setS(() => line.accountCode = res);
                                },
                                child: InputDecorator(decoration: _getInputDecoration("Compte", isDark: isDark, dense: true), child: Text(line.accountCode.isEmpty ? "Compte" : line.accountCode, style: const TextStyle(fontSize: 11))),
                              )),
                              const SizedBox(width: 8),
                              Expanded(flex: 3, child: TextField(
                                readOnly: isReadOnly,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 11),
                                controller: TextEditingController(text: line.description)..selection = TextSelection.fromPosition(TextPosition(offset: line.description.length)),
                                onChanged: (v) => line.description = v,
                                decoration: _getInputDecoration("Libellé", isDark: isDark, dense: true),
                              )),
                              if (!isReadOnly && lines.length > 2) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => setS(() => lines.removeAt(idx))),
                            ]),
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(child: TextField(
                                readOnly: isReadOnly,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 11),
                                controller: TextEditingController(text: line.debit == 0 ? "" : line.debit.toString()),
                                onChanged: (v) {
                                  double val = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                                  setS(() {
                                    line.debit = val;
                                    if (val > 0) line.credit = 0;
                                  });
                                },
                                decoration: _getInputDecoration("Débit", isDark: isDark, dense: true),
                              )),
                              const SizedBox(width: 8),
                              Expanded(child: TextField(
                                readOnly: isReadOnly,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 11),
                                controller: TextEditingController(text: line.credit == 0 ? "" : line.credit.toString()),
                                onChanged: (v) {
                                  double val = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                                  setS(() {
                                    line.credit = val;
                                    if (val > 0) line.debit = 0;
                                  });
                                },
                                decoration: _getInputDecoration("Crédit", isDark: isDark, dense: true),
                              )),
                            ]),
                          ]),
                        );
                      }).toList(),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: isDark ? Colors.black : Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                        child: Column(children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text("TOTAL DÉBIT", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                            Text("${totalDebit.toStringAsFixed(2)} $selectedCurrency", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                          ]),
                          const SizedBox(height: 4),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text("TOTAL CRÉDIT", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                            Text("${totalCredit.toStringAsFixed(2)} $selectedCurrency", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                          ]),
                          const Divider(),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(isBalanced ? "ÉQUILIBRÉ" : "DÉSÉQUILIBRÉ", style: TextStyle(color: isBalanced ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                            if (!isBalanced) Text("Diff: ${diff.toStringAsFixed(2)} $selectedCurrency", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: 24),
                      if (!isReadOnly) ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: isBalanced && entityId != null ? () {
                          onSave(JournalEntry(
                            id: entry?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                            entityId: entityId!,
                            journalNumber: journalNumber,
                            date: entryDate,
                            currency: selectedCurrency,
                            lines: lines,
                            reference: reference,
                          ));
                          Navigator.pop(ctx);
                        } : null,
                        child: Text(t.save.toUpperCase(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _buildTaxDropdown(
      {required double? value, required bool isReadOnly, required void Function(double?) onChanged, String label = 'TVA (%)', bool isDark = false}) {
    final rates = [0.0, 5.5, 10.0, 20.0];
    return DropdownButtonFormField<double>(
      isExpanded: true,
      isDense: true,
      dropdownColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
      value: rates.contains(value) ? value : 20.0,
      items: rates
          .map((r) =>
          DropdownMenuItem(value: r,
              child: Text("$r%", style: TextStyle(
                  color: isDark ? Colors.white : Colors.black, fontSize: 11))))
          .toList(),
      onChanged: isReadOnly ? null : onChanged,
      decoration: _getInputDecoration(label, isDark: isDark, dense: true),
    );
  }
}
