import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as ex;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import '../../models/invoice.dart';
import '../../models/entity.dart';
import '../../models/supplier.dart';
import '../../models/journal_entry.dart';
import '../../models/account.dart';
import '../../services/api_service.dart';
import '../../widgets/invoice_dialogs.dart';
import '../../widgets/quote_dialogs.dart';

import '../../models/payment.dart';

class PreComptaPage extends StatefulWidget {
  const PreComptaPage({super.key});

  @override
  State<PreComptaPage> createState() => _PreComptaPageState();
}

class _PreComptaPageState extends State<PreComptaPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  List<Supplier> _suppliers = [];
  List<Supplier> _customers = [];
  List<Entity> _myEntities = [];
  List<Invoice> _allInvoices = [];
  List<JournalEntry> _journalEntries = [];
  List<Account> _accounts = [];
  List<Map<String, dynamic>> _quotes = [];


  bool _isInitialLoading = true;
  String _searchQuery = "";
  int _partnersSubTab = 0;
  DateTime _focusedMonth = DateTime.now();
  final Color primaryColor = const Color(0xFF49F6C7);

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
    _loadData();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 0 && _partnersSubTab > 1) {
          setState(() { _partnersSubTab = 0; });
        } else {
          setState(() {});
        }
      }
    });
  }


  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isInitialLoading = true);

    try {
      final entities = await _apiService.fetchEntities();
      final suppliers = await _apiService.fetchSuppliers();
      final customers = await _apiService.fetchCustomers();
      final a = await _apiService.fetchInvoices(InvoiceType.achat);
      final v = await _apiService.fetchInvoices(InvoiceType.vente);
      final journal = await _apiService.fetchJournalEntries();
      final q = await _apiService.fetchQuotes();
      final accs = await _apiService.fetchAccounts();

      if (mounted) {
        setState(() {
          _myEntities = entities;
          _suppliers = suppliers;
          _customers = customers;
          _accounts = accs;
          _allInvoices = [...a, ...v]..sort((a, b) => b.date.compareTo(a.date));
          _journalEntries = journal..sort((a, b) => b.date.compareTo(a.date));
          _quotes = q;
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur chargement PreCompta: $e");
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  String _getNextOdNumber() {
    if (_journalEntries.isEmpty) return "OD-0001";
    final odEntries = _journalEntries.where((e) => e.journalNumber.startsWith("OD-")).toList();
    if (odEntries.isEmpty) return "OD-0001";
    odEntries.sort((a, b) => a.journalNumber.compareTo(b.journalNumber));
    String lastNumStr = odEntries.last.journalNumber.split('-').last;
    int lastNum = int.tryParse(lastNumStr) ?? 0;
    return "OD-${(lastNum + 1).toString().padLeft(4, '0')}";
  }

  Future<void> _deleteInvoice(Invoice inv) async {
    final confirm = await _confirmAction("Supprimer", "Voulez-vous vraiment supprimer cet élément ?");
    if (confirm) { await _apiService.deleteInvoice(inv.id); _loadData(); }
  }

  Future<void> _garderFnp(Invoice fnp) async {
    await _apiService.updateInvoice(fnp.id, {'status': 'kept'});
    final nextMonth = DateTime(fnp.date.year, fnp.date.month + 1, 1);
    final copy = fnp.copyWith(id: "fnp-kept-${DateTime.now().millisecondsSinceEpoch}", date: nextMonth, status: InvoiceStatus.pending);
    await _apiService.createInvoice(copy);
    _loadData();
  }

  Future<void> _extournerFnp(Invoice fnp) async { await _apiService.updateInvoice(fnp.id, {'status': 'extourned'}); _loadData(); }

  Future<void> _exportFnpExcel(List<Invoice> items) async {
    var excel = ex.Excel.createExcel(); var sheet = excel['FNP'];
    sheet.appendRow(['Fournisseur', 'Description', 'Compte Charge', 'HT', 'TVA', 'TTC'].map((e) => ex.TextCellValue(e)).toList());
    for (var i in items) { sheet.appendRow([ex.TextCellValue(i.supplierOrClientName), ex.TextCellValue(i.designation), ex.TextCellValue(i.expenseAccount ?? ''), ex.DoubleCellValue(i.amountHT), ex.DoubleCellValue(i.tva), ex.DoubleCellValue(i.amountTTC)]); }
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/FNP_${DateFormat('MM_yyyy').format(_focusedMonth)}.xlsx');
    await file.writeAsBytes(excel.save()!);
    await Share.shareXFiles([XFile(file.path)], text: 'Export FNP');
  }

  Widget _buildInvoiceList(InvoiceType type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _allInvoices.where((i) => !i.number.startsWith('FNP-') && i.type == type && (i.supplierOrClientName.toLowerCase().contains(_searchQuery.toLowerCase()) || i.number.toLowerCase().contains(_searchQuery.toLowerCase()))).toList();

    return Column(children: [
      if (type == InvoiceType.achat) Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), child: ElevatedButton.icon(onPressed: _scanInvoice, icon: const Icon(Icons.document_scanner, color: Colors.black), label: const Text("SCANNER UNE FACTURE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: primaryColor, minimumSize: const Size(double.infinity, 45), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
      Expanded(child: filtered.isEmpty ? const Center(child: Text("Aucune facture trouvée.")) : ListView.builder(padding: const EdgeInsets.symmetric(vertical: 12), itemCount: filtered.length, itemBuilder: (ctx, index) {
        final inv = filtered[index];
        final isPaid = inv.isPaid || inv.status == InvoiceStatus.paid;
        final isPartiallyPaid = !isPaid && inv.totalPaid > 0.01;

        bool showMonthDivider = false;
        if (index == 0) {
          showMonthDivider = true;
        } else {
          DateTime prevDate = filtered[index - 1].date;
          if (prevDate.month != inv.date.month || prevDate.year != inv.date.year) {
            showMonthDivider = true;
          }
        }

        return Column(
          children: [
            if (showMonthDivider) _buildMonthDivider(inv.date),
            Container(margin: const EdgeInsets.fromLTRB(16, 0, 16, 12), decoration: BoxDecoration(color: isDark ? const Color(0xFF232435) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white10 : Colors.grey.withAlpha(25), width: 1.2)),
              child: ListTile(
                title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(inv.supplierOrClientName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black))), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text("${inv.amountTTC.toStringAsFixed(2)} ${inv.currency}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: type == InvoiceType.achat ? Colors.red[400] : Colors.green[600])), if (!isPaid && inv.totalPaid > 0) Text("Reste: ${inv.remainingAmount.toStringAsFixed(2)} ${inv.currency}", style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold))])]),
                subtitle: Row(children: [Text(inv.number, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)), const SizedBox(width: 8), Text(DateFormat('dd/MM/yyyy').format(inv.date), style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54)), const Spacer(), if (isPartiallyPaid) _buildStatusBadge("PARTIEL", Colors.white, Colors.orange) else _buildStatusBadge(isPaid ? "PAYÉ" : (type == InvoiceType.achat ? "À RÉGLER" : "NON PAYÉ"), isPaid ? Colors.teal[700]! : Colors.orange[800]!, isPaid ? primaryColor.withValues(alpha: 0.2) : Colors.orange[50]!)]),
                trailing: PopupMenuButton<String>(onSelected: (val) async {
                  if (val == 'view') _showDetailedForm(type: type, invoiceToEdit: inv, isReadOnly: true);
                  else if (val == 'edit') _showDetailedForm(type: type, invoiceToEdit: inv);
                  else if (val == 'pay') _handlePayment(inv);
                  else if (val == 'delete') _deleteInvoice(inv);
                  else if (val == 'print') _handlePrint(inv);
                  else if (val == 'print_statement') { final list = type == InvoiceType.achat ? _suppliers : _customers; final dynamic partner = list.cast<dynamic>().firstWhere((p) => p.id == inv.supplierOrClientId, orElse: () => null); if (partner != null) await _printStatement(partner, type); else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Détails du partenaire introuvables."))); }
                }, itemBuilder: (ctx) => [_buildMenuItem('view', Icons.visibility_outlined, 'Voir'), if (!isPaid) _buildMenuItem('edit', Icons.edit_outlined, 'Modifier'), if (!isPaid) _buildMenuItem('pay', Icons.account_balance_wallet_outlined, type == InvoiceType.achat ? 'Appliquer règlement' : 'Encaisser'), _buildMenuItem('print', Icons.print_outlined, 'Imprimer'), _buildMenuItem('print_statement', Icons.print_outlined, 'État de compte'), _buildMenuItem('delete', Icons.delete_outline, 'Supprimer', color: Colors.red)]),
              ),
            ),
          ],
        );
      })),
    ]);
  }

  Widget _buildMonthDivider(DateTime date) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text(
            DateFormat('MMMM yyyy', 'fr_FR').format(date).toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.2, color: Colors.blueGrey),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Divider(thickness: 1, color: Color(0xFFEEEEEE))),
        ],
      ),
    );
  }

  Future<void> _scanInvoice() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Row(children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)), SizedBox(width: 15), Text("Analyse locale de la facture...")]), backgroundColor: Color(0xFF232435), duration: Duration(seconds: 3)));
      final data = await _apiService.aiProvider.extractInvoiceDataFromPath(path);
      if (data.containsKey('error')) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error']), backgroundColor: Colors.red)); return; }
      final scannedInvoice = Invoice(id: DateTime.now().millisecondsSinceEpoch.toString(), number: data['invoiceNumber'] ?? "SCAN-${DateFormat('HHmm').format(DateTime.now())}", supplierOrClientName: data['supplierName'] ?? "Fournisseur Inconnu", supplierOrClientId: "", amountHT: (data['amountTTC'] ?? 0.0) / 1.2, tva: (data['amountTTC'] ?? 0.0) * 0.2, amountTTC: data['amountTTC'] ?? 0.0, date: DateFormat('dd/MM/yyyy').tryParse(data['date'] ?? '') ?? DateTime.now(), dueDate: null, type: InvoiceType.achat, entityId: _myEntities.isNotEmpty ? _myEntities.first.id : "", designation: data['designation'] ?? "Scan automatique (Local)");
      _showDetailedForm(type: InvoiceType.achat, invoiceToEdit: scannedInvoice);
    }
  }

  void _handlePayment(Invoice inv) {
    InvoiceDialogs.showPaymentDialog(context: context, invoice: inv, accounts: _accounts, onPaid: (bankId, date, amount, currency, rate) async {
      final double amtBase = (currency == inv.currency) ? amount : (amount * rate);
      final double newTotalPaid = inv.totalPaid + amtBase;
      final bool isFullyPaid = (inv.amountTTC - newTotalPaid).abs() < 0.05 || newTotalPaid >= inv.amountTTC;
      final p = Payment(id: DateTime.now().millisecondsSinceEpoch.toString(), amount: amount, currency: currency, exchangeRate: rate, amountBaseCurrency: amtBase, date: date, method: 'Virement', linkedInvoiceId: inv.id, type: inv.type == InvoiceType.achat ? PaymentType.fournisseur : PaymentType.client, bankAccountId: bankId);
      if (inv.linkedQuoteNumber != null && inv.linkedQuoteNumber!.isNotEmpty) { final linkedQuote = _quotes.firstWhere((q) => q['number'].toString() == inv.linkedQuoteNumber.toString(), orElse: () => {}); if (linkedQuote.isNotEmpty) await _apiService.updateEstimateStatus(linkedQuote['id'], 'signé'); }
      await _apiService.createPayment(p);
      await _apiService.updateInvoice(inv.id, {'status': isFullyPaid ? 'paid' : 'partiallyPaid', 'bankAccountId': bankId, 'reconciledDate': date.toIso8601String(), 'isReconciled': true, 'totalPaid': newTotalPaid});
      await _apiService.updateEstimateStatus(inv.id, 'accepted');
      _loadData();
    });
  }

  void _showDetailedForm({required InvoiceType type, Invoice? invoiceToEdit, bool isReadOnly = false}) {
    InvoiceDialogs.showInvoiceForm(context: context, type: type, invoiceToEdit: invoiceToEdit, isReadOnly: isReadOnly, entities: _myEntities, partners: type == InvoiceType.achat ? _suppliers : _customers, accounts: _accounts, quotes: _quotes, onSave: (inv) async { final bool exists = _allInvoices.any((item) => item.id == inv.id); if (exists) await _apiService.updateInvoice(inv.id, inv.toJson()); else await _apiService.createInvoice(inv); _loadData(); }, onTriggerIA: (l, a, p, s) => {});
  }

  Future<bool> _confirmAction(String title, String message) async { return await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: Text(title), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("ANNULER")), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("CONFIRMER"))])) ?? false; }

  @override
  Widget build(BuildContext context) {
    bool showNavigator = _tabController.index == 2 || _tabController.index == 3;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(backgroundColor: isDark ? const Color(0xFF232435) : Colors.white, elevation: 0, title: _buildSearchBar(), bottom: TabBar(controller: _tabController, labelColor: isDark ? primaryColor : Colors.black, unselectedLabelColor: Colors.grey, indicatorColor: primaryColor, tabs: const [Tab(text: "Achats"), Tab(text: "Ventes"), Tab(text: "Journal"), Tab(text: "FNP")])),
      body: _isInitialLoading ? const Center(child: CircularProgressIndicator()) : Column(children: [if (showNavigator) _buildMonthNavigator(), Expanded(child: TabBarView(controller: _tabController, children: [_buildPartnersMainView(InvoiceType.achat), _buildPartnersMainView(InvoiceType.vente), _buildJournalList(), _buildFnpView()]))]),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildMonthNavigator() {
    return Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), padding: const EdgeInsets.symmetric(vertical: 4), decoration: BoxDecoration(color: const Color(0xFF232435), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [IconButton(icon: Icon(Icons.chevron_left, color: primaryColor), onPressed: () => setState(() { _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1); })), Text("${DateFormat('MMMM', 'fr_FR').format(_focusedMonth).toUpperCase()} - ${_focusedMonth.year}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)), IconButton(icon: Icon(Icons.chevron_right, color: primaryColor), onPressed: () => setState(() { _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1); }))]),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(height: 38, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: TextField(style: TextStyle(color: isDark ? Colors.white : Colors.black), onChanged: (v) => setState(() => _searchQuery = v), decoration: InputDecoration(hintText: "Rechercher...", hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey), prefixIcon: Icon(Icons.search, size: 18, color: isDark ? primaryColor : Colors.grey), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 8))));
  }

  Widget _buildPartnersMainView(InvoiceType type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [Container(padding: const EdgeInsets.symmetric(vertical: 4), decoration: BoxDecoration(color: isDark ? Colors.black : Colors.white, border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.grey.withAlpha(25)))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_buildSubTabButton("Factures", 0), _buildSubTabButton(type == InvoiceType.achat ? "Fournisseurs" : "Clients", 1), if (type == InvoiceType.vente) _buildSubTabButton("Devis", 2)])), Expanded(child: _partnersSubTab == 0 ? _buildInvoiceList(type) : _partnersSubTab == 1 ? _buildPartnersList(type) : _buildQuotesList())]);
  }

  Widget _buildSubTabButton(String label, int index) {
    bool isActive = _partnersSubTab == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(onTap: () => setState(() => _partnersSubTab = index), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: isActive ? primaryColor.withValues(alpha: 0.3) : Colors.transparent, borderRadius: BorderRadius.circular(15)), child: Text(label, style: TextStyle(color: isActive ? (isDark ? primaryColor : Colors.black) : Colors.grey[600], fontWeight: isActive ? FontWeight.bold : FontWeight.normal, fontSize: 12))));
  }

  Widget _buildJournalList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _journalEntries.where((e) => e.date.year == _focusedMonth.year && e.date.month == _focusedMonth.month).toList();
    if (filtered.isEmpty) return const Center(child: Text("Aucune écriture pour ce mois."));
    return ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), itemCount: filtered.length, itemBuilder: (context, index) {
      final entry = filtered[index];
      bool showMonthDivider = false;
      if (index == 0) { showMonthDivider = true; } else { DateTime prevDate = filtered[index - 1].date; if (prevDate.month != entry.date.month || prevDate.year != entry.date.year) { showMonthDivider = true; } }

      return Column(
        children: [
          if (showMonthDivider) _buildMonthDivider(entry.date),
          Container(margin: const EdgeInsets.symmetric(vertical: 2), decoration: BoxDecoration(color: isDark ? const Color(0xFF232435) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: isDark ? Border.all(color: Colors.white10) : Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5))),
            child: ListTile(
              onTap: () => _viewEntry(entry),
              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              title: Row(children: [
                Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(DateFormat('dd/MM').format(entry.date), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)), Text(entry.journalNumber, style: TextStyle(fontSize: 9, color: isDark ? Colors.white54 : Colors.grey[600]))])),
                Expanded(flex: 3, child: Text(entry.lines.isNotEmpty ? entry.lines.first.description : "-", style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87), overflow: TextOverflow.ellipsis)),
                Expanded(flex: 2, child: Text("${entry.totalDebit.toStringAsFixed(2)} ${entry.currency}", textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? primaryColor : Colors.blueGrey))),
              ]),
              trailing: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 20, color: isDark ? Colors.white : Colors.grey),
                onSelected: (val) {
                  if (val == 'edit') _editEntry(entry);
                  if (val == 'delete') _deleteEntry(entry.id);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text("Modifier")])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text("Supprimer", style: TextStyle(color: Colors.red))])),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSmallActionBtn(IconData icon, Color color, VoidCallback onPressed) { return SizedBox(width: 32, child: IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: Icon(icon, color: color, size: 18), onPressed: onPressed)); }
  void _viewEntry(JournalEntry entry) { InvoiceDialogs.showJournalEntryForm(context: context, entry: entry, isReadOnly: true, entities: _myEntities, accounts: _accounts, onSave: (_) {}); }
  void _editEntry(JournalEntry entry) { InvoiceDialogs.showJournalEntryForm(context: context, entry: entry, entities: _myEntities, accounts: _accounts, onSave: (updatedEntry) async { await _apiService.updateJournalEntry(entry.id, updatedEntry); _loadData(); }); }
  Future<void> _deleteEntry(String id) async { final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: Text("Supprimer"), content: Text("Voulez-vous supprimer cette écriture ?"), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("ANNULER")), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("CONFIRMER"))])) ?? false; if (confirm) { await _apiService.deleteJournalEntry(id); _loadData(); } }

  Widget _buildFnpView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentMonthKey = DateFormat('yyyyMM').format(_focusedMonth); final list = _allInvoices.where((i) { final itemMonthKey = DateFormat('yyyyMM').format(i.date); return (itemMonthKey == currentMonthKey || i.number.startsWith('FNP-')) && i.type == InvoiceType.achat; }).toList();
    double totalHT = list.fold(0, (sum, i) => sum + i.amountHT); double totalTva = list.fold(0, (sum, i) => sum + i.tva); double totalTtc = list.fold(0, (sum, i) => sum + i.amountTTC);
    Map<String, double> chargeSummary = {}; for (var item in list) { String acc = item.expenseAccount ?? '601000'; chargeSummary[acc] = (chargeSummary[acc] ?? 0) + item.amountHT; }
    return Column(children: [
      Expanded(child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: list.length, itemBuilder: (ctx, idx) {
        final item = list[idx]; final isPaid = item.status == InvoiceStatus.paid; final isKept = item.status == InvoiceStatus.kept; final isExtourned = item.status == InvoiceStatus.extourned;
        return Card(color: isDark ? const Color(0xFF232435) : Colors.white, child: ListTile(title: Row(children: [Expanded(child: Text(item.supplierOrClientName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black))), if (isPaid) _buildStatusBadge("PAYÉ", Colors.teal[700]!, primaryColor.withValues(alpha: 0.2)) else if (isKept) _buildStatusBadge("GARDÉ", Colors.blue[700]!, Colors.blue[50]!) else if (isExtourned) _buildStatusBadge("EXTOURNÉ", Colors.grey[700]!, Colors.green[50]!) else _buildStatusBadge("À RÉGLER", Colors.orange[800]!, Colors.orange[50]!)]), subtitle: Text("${item.amountTTC.toStringAsFixed(2)} €", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)), trailing: PopupMenuButton<String>(icon: Icon(Icons.more_vert, color: isDark ? Colors.white : Colors.grey), onSelected: (v) { if (v == 'keep') _garderFnp(item); if (v == 'reverse') _extournerFnp(item); if (v == 'delete') _deleteInvoice(item); }, itemBuilder: (c) => [const PopupMenuItem(value: 'keep', child: Text("Garder")), const PopupMenuItem(value: 'reverse', child: Text("Extourner")), const PopupMenuItem(value: 'delete', child: Text("Supprimer"))])));
      })),
      Container(margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16), padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: Color(0xFF232435), borderRadius: BorderRadius.all(Radius.circular(16))), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildFnpStat("TOTAL HT", "${totalHT.toStringAsFixed(2)} €"), _buildFnpStat("TOTAL TVA", "${totalTva.toStringAsFixed(2)} €"), _buildFnpStat("TOTAL TTC", "${totalTtc.toStringAsFixed(2)} €", isMain: true)]), const SizedBox(height: 12), SizedBox(width: double.infinity, child: OutlinedButton.icon(style: OutlinedButton.styleFrom(side: BorderSide(color: primaryColor), foregroundColor: primaryColor), onPressed: () => _showProvisionDetails(chargeSummary, totalHT, totalTva, totalTtc, list), icon: const Icon(Icons.analytics_outlined, size: 18), label: const Text('PROVISION EN D DÉTAIL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))))])),
    ]);
  }

  void _showProvisionDetails(Map<String, double> summary, double totalHT, double totalTva, double totalTtc, List<Invoice> allFnp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) => Container(color: isDark ? const Color(0xFF232435) : Colors.white, padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Détail des charges (Provisions)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)), IconButton(icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black), onPressed: () => Navigator.pop(ctx))]), const Divider(height: 24), ...summary.entries.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Compte ${e.key}", style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)), Text("${e.value.toStringAsFixed(2)} €", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black))]))), const Divider(height: 24), _buildDetailRow("TOTAL HT", totalHT), _buildDetailRow("TOTAL TVA", totalTva), _buildDetailRow("TOTAL TTC", totalTtc, isMain: true), const SizedBox(height: 20), Row(children: [Expanded(child: ElevatedButton.icon(onPressed: () => _exportFnpExcel(allFnp), icon: const Icon(Icons.table_view), label: const Text("EXCEL"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green))), const SizedBox(width: 8), Expanded(child: ElevatedButton.icon(onPressed: () => _handlePrintFnp(allFnp, totalHT, totalTva, totalTtc), icon: const Icon(Icons.picture_as_pdf), label: const Text("PDF"), style: ElevatedButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: 0.2))))]), const SizedBox(height: 8), SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => _passerOdProvision(allFnp), icon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.black), label: const Text("PASSER OD PROVISION", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.black)))])));
  }
  Future<void> _passerOdProvision(List<Invoice> list) async { if (list.isEmpty) return; final entry = JournalEntry(id: "od-fnp-${DateTime.now().millisecondsSinceEpoch}", entityId: _myEntities.first.id, journalNumber: "PROV-${DateFormat('MMyy').format(_focusedMonth)}", date: DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0), lines: list.map((f) => JournalLine(accountCode: f.expenseAccount ?? '601000', description: "Provision: ${f.supplierOrClientName}", debit: f.amountHT, credit: 0)).toList()); await _apiService.createJournalEntry(entry); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("OD de provision générée."), backgroundColor: Colors.green)); }

  Future<void> _handlePrintFnp(List<Invoice> items, double tht, double ttva, double tttc) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(level: 0, child: pw.Text("ÉTAT DES PROVISIONS (FNP) - ${DateFormat('MMMM yyyy', 'fr_FR').format(_focusedMonth)}")),
            pw.TableHelper.fromTextArray(data: [
              ['Fournisseur', 'Compte Charge', 'HT', 'TVA', 'TTC'],
              ...items.map((i) => [i.supplierOrClientName, i.expenseAccount ?? '', i.amountHT.toStringAsFixed(2), i.tva.toStringAsFixed(2), i.amountTTC.toStringAsFixed(2)])
            ]),
            pw.SizedBox(height: 20),
            pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text("TOTAL TTC : ${tttc.toStringAsFixed(2)} €", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)))
          ],
        );
      },
    ));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Widget _buildFnpStat(String label, String value, {bool isMain = false}) { return Column(children: [Text(label, style: TextStyle(color: isMain ? primaryColor : Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)), Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))]); }
  Widget _buildDetailRow(String label, double value, {bool isMain = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)), Text('${value.toStringAsFixed(2)} €', style: TextStyle(color: isMain ? primaryColor : (isDark ? Colors.white : Colors.black), fontWeight: isMain ? FontWeight.bold : FontWeight.normal, fontSize: isMain ? 16 : 12))]));
  }
  Widget _buildStatusBadge(String text, Color textColor, Color bgColor) { return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)), child: Text(text, style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.bold))); }
  void _showNewPartnerForm(InvoiceType type) async { final partner = await InvoiceDialogs.showPartnerForm(context: context, type: type, accounts: _accounts); if (partner != null) { if (type == InvoiceType.achat) await _apiService.createSupplier(partner); else await _apiService.createCustomer(partner); _loadData(); } }
  Widget _buildPartnersList(InvoiceType type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final list = type == InvoiceType.achat ? _suppliers : _customers;
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: list.length, itemBuilder: (ctx, idx) {
      final partner = list[idx];
      return Card(color: isDark ? const Color(0xFF232435) : Colors.white, child: ListTile(title: Text(partner.name, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)), subtitle: Text(partner.email, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)), trailing: PopupMenuButton<String>(icon: Icon(Icons.more_vert, color: isDark ? Colors.white : Colors.grey), onSelected: (val) async { if (val == 'edit') { final updated = await InvoiceDialogs.showPartnerForm(context: context, type: type, partner: partner, accounts: _accounts); if (updated != null) { if (type == InvoiceType.achat) await _apiService.createSupplier(updated); else await _apiService.createCustomer(updated); _loadData(); } } else if (val == 'print_statement') await _printStatement(partner, type); }, itemBuilder: (ctx) => [_buildMenuItem('edit', Icons.edit_outlined, 'Modifier'), _buildMenuItem('print_statement', Icons.print_outlined, 'Imprimer État de Compte', color: Colors.indigo)])));
    });
  }
  PopupMenuItem<String> _buildMenuItem(String value, IconData icon, String label, {Color? color}) { return PopupMenuItem(value: value, child: Row(children: [Icon(icon, size: 18, color: color ?? Colors.blueGrey[700]), const SizedBox(width: 12), Text(label, style: TextStyle(fontSize: 13, color: color))])); }

  Future<void> _handlePrint(Invoice inv) async {
    final entity = _myEntities.firstWhere((e) => e.id == inv.entityId, orElse: () => _myEntities.first);
    final partner = (inv.type == InvoiceType.achat ? _suppliers : _customers).firstWhere((p) => p.id == inv.supplierOrClientId, orElse: () => Supplier(id: inv.supplierOrClientId, name: inv.supplierOrClientName, address: '', email: '', paymentTerms: ''));
    final font = await PdfGoogleFonts.notoSansRegular(); final boldFont = await PdfGoogleFonts.notoSansBold(); final pdf = pw.Document();
    pdf.addPage(pw.Page(pageFormat: PdfPageFormat.a4, theme: pw.ThemeData.withFont(base: font, bold: boldFont), build: (pw.Context context) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text(entity.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)), pw.Text(entity.address, style: const pw.TextStyle(fontSize: 10)), pw.Text("Email: ${entity.email}", style: const pw.TextStyle(fontSize: 10)), if (entity.phone != null) pw.Text("Tel: ${entity.phone}", style: const pw.TextStyle(fontSize: 10)), pw.Text("SIRET : ${entity.idNumber}", style: const pw.TextStyle(fontSize: 10))]), pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [pw.Text(inv.type == InvoiceType.vente ? "FACTURE" : "REÇU D'ACHAT", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24, color: PdfColors.blue800)), pw.Text("N° ${inv.number}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text("Date: ${DateFormat('dd/MM/yyyy').format(inv.date)}"), if (inv.dueDate != null) pw.Text("Échéance: ${DateFormat('dd/MM/yyyy').format(inv.dueDate!)}", style: const pw.TextStyle(color: PdfColors.red))])]),
      pw.SizedBox(height: 50), pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [pw.Container(width: 250, padding: const pw.EdgeInsets.all(10), decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text("ADRESSÉ À :", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)), pw.SizedBox(height: 4), pw.Text(partner.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)), if (partner.address.isNotEmpty) pw.Text(partner.address, style: const pw.TextStyle(fontSize: 10)), if (partner.email.isNotEmpty) pw.Text("Email: ${partner.email}", style: const pw.TextStyle(fontSize: 10)), if (partner.siret != null && partner.siret!.isNotEmpty) pw.Text("SIRET: ${partner.siret}", style: const pw.TextStyle(fontSize: 10))]))]),
      pw.SizedBox(height: 40), pw.TableHelper.fromTextArray(headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white), headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800), data: <List<String>>[['Désignation / Description', 'Montant HT', 'TVA', 'Montant TTC'], [inv.designation.isNotEmpty ? inv.designation : "Prestation de services", "${inv.amountHT.toStringAsFixed(2)} €", "${inv.tva.toStringAsFixed(2)} €", "${inv.amountTTC.toStringAsFixed(2)} €"]]),
      pw.SizedBox(height: 30), pw.Align(alignment: pw.Alignment.centerRight, child: pw.Container(width: 200, child: pw.Column(children: [pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("TOTAL HT:"), pw.Text("${inv.amountHT.toStringAsFixed(2)} €")]), pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("TOTAL TVA:"), pw.Text("${inv.tva.toStringAsFixed(2)} €")]), pw.Divider(), pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("TOTAL TTC:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text("${inv.amountTTC.toStringAsFixed(2)} €", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))])]))),
      pw.Spacer(), pw.Divider(), pw.Center(child: pw.Text("Imprimé le ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())} - Document généré par votre logiciel de gestion.", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey))),
    ])));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'Facture_${inv.number}.pdf');
  }

  Future<void> _printStatement(dynamic partner, InvoiceType type) async {
    try {
      final partnerInvoices = _allInvoices.where((inv) => inv.supplierOrClientId == partner.id && inv.type == type).toList();
      List<Map<String, dynamic>> transactions = [];
      for (var inv in partnerInvoices) { transactions.add({'date': inv.date, 'type': type == InvoiceType.achat ? 'Facture Fournisseur' : 'Facture Client', 'ref': inv.number, 'amount': inv.amountTTC, 'isDebit': type == InvoiceType.vente}); if (inv.status == InvoiceStatus.paid || (inv.totalPaid > 0)) transactions.add({'date': inv.reconciledDate ?? inv.date.add(const Duration(days: 1)), 'type': 'Paiement', 'ref': 'PAY-${inv.number}', 'amount': inv.totalPaid, 'isDebit': type == InvoiceType.achat}); }
      transactions.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
      final font = await PdfGoogleFonts.notoSansRegular(); final boldFont = await PdfGoogleFonts.notoSansBold(); final pdf = pw.Document(); double runningBalance = 0;
      pdf.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, theme: pw.ThemeData.withFont(base: font, bold: boldFont), build: (context) => [
        pw.Header(level: 0, child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text("ÉTAT DE COMPTE", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)), pw.Text(partner.name, style: const pw.TextStyle(fontSize: 14))]), pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.now()))])),
        pw.SizedBox(height: 20), pw.TableHelper.fromTextArray(headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white), headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900), headers: ['Date', 'Type', 'Référence', 'Débit', 'Crédit', 'Solde'], data: transactions.map((t) { double debit = t['isDebit'] ? t['amount'] : 0; double credit = !t['isDebit'] ? t['amount'] : 0; runningBalance += (debit - credit); return [DateFormat('dd/MM/yyyy').format(t['date']), t['type'], t['ref'], debit > 0 ? "${debit.toStringAsFixed(2)} €" : "", credit > 0 ? "${credit.toStringAsFixed(2)} €" : "", "${runningBalance.toStringAsFixed(2)} €"]; }).toList()),
        pw.SizedBox(height: 30), pw.Divider(), pw.Align(alignment: pw.Alignment.centerRight, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [pw.Text("SOLDE FINAL : ${runningBalance.toStringAsFixed(2)} €", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)), pw.Text(runningBalance >= 0 ? "POSITION : DÉBITRICE" : "POSITION : CRÉDITRICE", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: runningBalance >= 0 ? PdfColors.red : PdfColors.green))]))
      ]));
      await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'Etat_Compte_${partner.name}.pdf');
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de la génération du PDF : $e"))); }
  }

  Widget? _buildFab() {
    return FloatingActionButton(backgroundColor: primaryColor, child: const Icon(Icons.add, color: Colors.black), onPressed: () {
      final isAchatTab = _tabController.index == 0; final isVenteTab = _tabController.index == 1;
      if (isAchatTab && _partnersSubTab == 1) { _showNewPartnerForm(InvoiceType.achat); return; }
      if (isVenteTab && _partnersSubTab == 1) { _showNewPartnerForm(InvoiceType.vente); return; }
      if (isVenteTab && _partnersSubTab == 2) { _showNewQuoteForm(); return; }
      switch (_tabController.index) {
        case 0: _showDetailedForm(type: InvoiceType.achat); break;
        case 1: _showDetailedForm(type: InvoiceType.vente); break;
        case 2: _showJournalEntryForm(); break;
        case 3: InvoiceDialogs.showFnpForm(context: context, entities: _myEntities, suppliers: _suppliers, accounts: _accounts, onSave: (fnp) async { await _apiService.createInvoice(fnp); _loadData(); }); break;
      }
    });
  }

  void _showNewQuoteForm({Map<String, dynamic>? quoteToEdit, bool isReadOnly = false}) {
    Invoice? quoteObject; if (quoteToEdit != null) quoteObject = Invoice(id: quoteToEdit['id']?.toString() ?? '', number: quoteToEdit['number']?.toString() ?? '', date: quoteToEdit['date'] is DateTime ? quoteToEdit['date'] : DateTime.tryParse(quoteToEdit['date']?.toString() ?? '') ?? DateTime.now(), entityId: quoteToEdit['entityId']?.toString() ?? '', supplierOrClientId: quoteToEdit['customerId']?.toString() ?? '', supplierOrClientName: quoteToEdit['clientName']?.toString() ?? 'Client inconnu', amountHT: double.tryParse(quoteToEdit['totalHT']?.toString() ?? '0') ?? 0, tva: double.tryParse(quoteToEdit['tva']?.toString() ?? '0') ?? 0, amountTTC: double.tryParse(quoteToEdit['total']?.toString() ?? '0') ?? 0, designation: quoteToEdit['designation']?.toString() ?? '', type: InvoiceType.vente, status: InvoiceStatus.draft, paymentTerms: quoteToEdit['paymentTerms']?.toString() ?? '30 jours');
    showQuoteDialog(context: context, quoteToEdit: quoteObject, suppliers: _customers, entities: _myEntities, accounts: _accounts, onSave: (Invoice updatedQuote) async { if (isReadOnly) return; final Map<String, dynamic> dataToSend = { 'id': updatedQuote.id, 'number': updatedQuote.number, 'date': updatedQuote.date.toIso8601String(), 'entityId': updatedQuote.entityId, 'customerId': updatedQuote.supplierOrClientId, 'clientName': updatedQuote.supplierOrClientName, 'totalHT': updatedQuote.amountHT, 'tva': updatedQuote.tva, 'total': updatedQuote.amountTTC, 'designation': updatedQuote.designation }; await _apiService.createQuote(dataToSend); _loadData(); });
  }

  void _showJournalEntryForm() { InvoiceDialogs.showJournalEntryForm(context: context, nextOdNumber: _getNextOdNumber(), entities: _myEntities, accounts: _accounts, onSave: (entry) async { await _apiService.createJournalEntry(entry); _loadData(); }); }
  void _deleteQuote(String id) async { final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text("Supprimer le devis"), content: const Text("Voulez-vous vraiment supprimer ce devis ?"), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("ANNULER")), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("SUPPRIMER", style: TextStyle(color: Colors.red)))])); if (confirm == true) { await _apiService.deleteQuote(id); _loadData(); } }

  Widget _buildQuotesList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _quotes.where((q) { if (_searchQuery.isEmpty) return true; final name = (q['clientName'] ?? '').toString().toLowerCase(); final num = (q['number'] ?? '').toString().toLowerCase(); return name.contains(_searchQuery.toLowerCase()) || num.contains(_searchQuery.toLowerCase()); }).toList();
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: filtered.length, itemBuilder: (ctx, index) {
      final q = filtered[index]; return Card(color: isDark ? const Color(0xFF232435) : Colors.white, margin: const EdgeInsets.only(bottom: 10), child: ListTile(onTap: () => _showQuoteDetails(q), title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(q['clientName']?.toString() ?? "Client inconnu", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black))), _buildQuoteStatusFromMap(q)]), subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Devis N° ${q['number']} - ${q['designation'].toString().split('|')[0]}", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)), Text("Montant : ${q['total']} €", style: TextStyle(color: isDark ? primaryColor : Colors.black, fontWeight: FontWeight.bold))]), trailing: PopupMenuButton<String>(icon: Icon(Icons.more_vert, color: isDark ? Colors.white : Colors.black), onSelected: (val) { if (val == 'view') _showQuoteDetails(q); if (val == 'print') _handlePrintQuote(q); if (val == 'delete') _deleteQuote(q['id']); }, itemBuilder: (ctx) => [_buildMenuItem('view', Icons.visibility_outlined, 'Voir'), _buildMenuItem('print', Icons.print_outlined, 'Imprimer'), _buildMenuItem('delete', Icons.delete_outline, 'Supprimer', color: Colors.red)])));
    });
  }

  Widget _buildQuoteStatusFromMap(Map<String, dynamic> quoteMap) {
    final Invoice? linkedInvoice = _allInvoices.cast<Invoice?>().firstWhere((inv) => inv?.linkedQuoteNumber == quoteMap['number'].toString(), orElse: () => null);
    final bool hasLinkedInvoice = linkedInvoice != null; final bool isPaid = linkedInvoice?.status == InvoiceStatus.paid; final bool isPartiallyPaid = linkedInvoice != null && !isPaid && linkedInvoice.totalPaid > 0.01;
    final String currentStatus = quoteMap['status']?.toString().toLowerCase() ?? 'brouillon';
    if (isPaid) return _badge("SIGNÉ", Colors.green); else if (isPartiallyPaid) return _badge("PAYÉ (PARTIEL)", Colors.orange); else if (hasLinkedInvoice) return _badge("FACTURÉ", Colors.blueGrey); else return Text(currentStatus.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey));
  }

  Widget _badge(String label, Color color) { return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)), child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))); }
  void _showQuoteDetails(Map<String, dynamic> quote) {
    final customerId = quote['customerId']?.toString() ?? ''; if (!_customers.any((c) => c.id == customerId) && quote['clientName'] != null) { _customers.add(Supplier(id: customerId, name: quote['clientName'], address: quote['clientAddress'] ?? '', email: '', paymentTerms: '')); }
    final entityId = quote['entityId']?.toString() ?? ''; if (!_myEntities.any((e) => e.id.toString() == entityId) && quote['entityName'] != null) { _myEntities.add(Entity(id: entityId, name: quote['entityName'], address: '', email: '', idNumber: '')); }
    final Map<String, dynamic> safeQuote = Map.from(quote); safeQuote['customerId'] = customerId; safeQuote['entityId'] = entityId; _showNewQuoteForm(quoteToEdit: safeQuote, isReadOnly: true);
  }

  Future<void> _handlePrintQuote(Map<String, dynamic> quote) async {
    final entity = _myEntities.firstWhere((e) => e.id.toString() == quote['entityId']?.toString(), orElse: () => _myEntities.isNotEmpty ? _myEntities.first : Entity(id: '', name: 'Émetteur inconnu', address: '', email: '', idNumber: ''));
    final client = _customers.firstWhere((c) => c.id.toString() == quote['customerId']?.toString(), orElse: () => Supplier(id: '', name: quote['clientName'] ?? 'Client inconnu', address: quote['clientAddress'] ?? '', email: '', paymentTerms: ''));
    final String fullDesignation = quote['designation']?.toString() ?? ''; final List<String> parts = fullDesignation.split('|'); final String title = parts[0]; final String longDescription = parts.length > 1 ? parts[1] : '';
    final pdf = pw.Document(); final font = await PdfGoogleFonts.notoSansRegular(); final boldFont = await PdfGoogleFonts.notoSansBold();
    pdf.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, theme: pw.ThemeData.withFont(base: font, bold: boldFont), build: (pw.Context context) => [
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text(entity.name.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)), pw.SizedBox(height: 2), pw.Text(entity.address, style: const pw.TextStyle(fontSize: 9)), pw.Text("SIRET : ${entity.idNumber}", style: const pw.TextStyle(fontSize: 9)), if (entity.email.isNotEmpty) pw.Text("Email : ${entity.email}", style: const pw.TextStyle(fontSize: 9))]), pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [pw.Text("DEVIS", style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey)), pw.Text("N° ${quote['number']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text("Date : ${DateFormat('dd/MM/yyyy').format(DateTime.tryParse(quote['date'].toString()) ?? DateTime.now())}")])]),
      pw.SizedBox(height: 30), pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Container(width: 250, padding: const pw.EdgeInsets.all(10), decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.5), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2))), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text("DESTINATAIRE :", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)), pw.SizedBox(height: 4), pw.Text(client.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)), if (client.address.isNotEmpty) pw.Text(client.address, style: const pw.TextStyle(fontSize: 10))]))]),
      pw.SizedBox(height: 40), pw.TableHelper.fromTextArray(border: null, headerAlignment: pw.Alignment.centerLeft, headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10), headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800), cellHeight: 30, columnWidths: {0: const pw.FlexColumnWidth(4), 1: const pw.FlexColumnWidth(1), 2: const pw.FlexColumnWidth(1), 3: const pw.FlexColumnWidth(1.2)}, headers: ['Désignation / Détails', 'HT', 'TVA', 'Total TTC'], data: [[pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 5), child: pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))), if (longDescription.isNotEmpty) pw.Padding(padding: const pw.EdgeInsets.only(bottom: 5), child: pw.Text(longDescription, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900)))]), "${quote['totalHT'] ?? quote['amountHT']} €", "${quote['tva'] ?? '0.00'} €", "${quote['total']} €"]]),
      pw.SizedBox(height: 20), pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [pw.Container(width: 180, child: pw.Column(children: [_buildTotalRow("Total HT", "${quote['totalHT'] ?? quote['amountHT']} €"), _buildTotalRow("TVA", "${quote['tva'] ?? '0.00'} €"), pw.Divider(color: PdfColors.grey400), _buildTotalRow("TOTAL TTC", "${quote['total']} €", isBold: true)]))]),
      pw.SizedBox(height: 50), pw.Text("Conditions de paiement : ${quote['paymentTerms'] ?? '30 jours'}", style: const pw.TextStyle(fontSize: 9)), pw.Text("Validité du devis : 30 jours", style: const pw.TextStyle(fontSize: 9)),
    ], footer: (pw.Context context) => pw.Center(child: pw.Text("Page ${context.pageNumber} / ${context.pagesCount} - Document généré par votre logiciel de gestion.", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)))));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'Devis_${quote['number']}.pdf');
  }
  pw.Widget _buildTotalRow(String label, String value, {bool isBold = false}) { return pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)), pw.Text(value, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: isBold ? 14 : 10))])); }
}
