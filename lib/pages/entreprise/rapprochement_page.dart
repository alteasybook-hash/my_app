import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/bank_transaction.dart';
import '../../models/reconciliation_record.dart';
import '../../models/account.dart';
import '../../models/history_entry.dart';
import '../../services/api_service.dart';
import '../../ai/accounting_ai.dart';

class RapprochementPage extends StatefulWidget {
  const RapprochementPage({super.key});

  @override
  State<RapprochementPage> createState() => _RapprochementPageState();
}

class _RapprochementPageState extends State<RapprochementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final Color primaryColor = const Color(0xFF49F6C7);

  // --- ÉTAT ---
  List<BankTransaction> _bankTransactions = []; 
  List<Account> _bankAccountsFromPlan = [];
  List<ReconciliationRecord> _pastReconciliations = [];
  Account? _selectedBankPlanAccount;

  double _softwareSoldeComptableTotal = 0.0;
  bool _isLoading = true;
  bool _isProcessingMatch = false;

  final Set<String> _selectedSoftwareIds = {};
  final Set<String> _selectedBankStatementIds = {};
  final Set<String> _selectedReconciledIds = {}; 
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final allAccs = await _apiService.fetchAccounts();
      final recs = await _apiService.fetchReconciliations();
      final txs = await _apiService.fetchBankTransactions();

      _bankAccountsFromPlan = allAccs.where((acc) =>
      acc.number.startsWith('512') || acc.number.startsWith('511')).toList();

      if (_bankAccountsFromPlan.isNotEmpty && _selectedBankPlanAccount == null) {
        _selectedBankPlanAccount = _bankAccountsFromPlan.first;
      }

      if (_selectedBankPlanAccount != null) {
        final pendingSoftwareTx = txs.where((t) =>
        !t.id.startsWith('csv-') && !t.id.startsWith('ofx-') &&
            (t.bankAccountId == _selectedBankPlanAccount?.id || t.bankAccountId == _selectedBankPlanAccount?.number) &&
            !t.isReconciled
        ).toList();

        _softwareSoldeComptableTotal = pendingSoftwareTx.fold(0.0, (sum, t) => sum + t.amount);
      }

      setState(() {
        _pastReconciliations = recs;
        _bankTransactions = txs;
        _selectedReconciledIds.clear();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erreur chargement rapprochement: $e");
      setState(() => _isLoading = false);
    }
  }

  String formatCurrency(double amount, String currencyCode) {
    final format = NumberFormat.simpleCurrency(name: currencyCode);
    return format.format(amount);
  }

  double get _softwareMatchTotal {
    double total = 0.0;
    for (var id in _selectedSoftwareIds) {
      final tx = _bankTransactions.firstWhere((t) => t.id == id, orElse: () => BankTransaction(id: '', date: DateTime.now(), description: '', amount: 0, bankAccountId: '', isReconciled: false));
      if (tx.id.isNotEmpty) {
        total += (tx.paymentStatus == 'partial' && tx.remainingAmount != null) ? tx.remainingAmount! : tx.amount;
      }
    }
    return double.parse(total.toStringAsFixed(2));
  }

  double get _bankMatchTotal {
    double total = 0.0;
    for (var id in _selectedBankStatementIds) {
      final tx = _bankTransactions.firstWhere((t) => t.id == id, orElse: () => BankTransaction(id: '', date: DateTime.now(), description: '', amount: 0, bankAccountId: '', isReconciled: false));
      if (tx.id.isNotEmpty) total += tx.amount;
    }
    return double.parse(total.toStringAsFixed(2));
  }

  void _runAutoMatching() {
    final pendingSoftwareTx = _bankTransactions.where((t) => !t.isReconciled && !t.id.startsWith('csv-') && (t.bankAccountId == _selectedBankPlanAccount?.id || t.bankAccountId == _selectedBankPlanAccount?.number)).toList();
    final pendingBankTx = _bankTransactions.where((t) => !t.isReconciled && t.id.startsWith('csv-') && (t.bankAccountId == _selectedBankPlanAccount?.id || t.bankAccountId == _selectedBankPlanAccount?.number)).toList();

    int matchCount = 0;
    for (var bank in pendingBankTx) {
      for (var software in pendingSoftwareTx) {
        double softwareAmt = (software.paymentStatus == 'partial' && software.remainingAmount != null) ? software.remainingAmount! : software.amount;
        if ((bank.amount - softwareAmt).abs() < 0.01 && bank.date.difference(software.date).inDays.abs() <= 5) {
          _selectedBankStatementIds.add(bank.id);
          _selectedSoftwareIds.add(software.id);
          matchCount++;
          break;
        }
      }
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$matchCount correspondances suggérées")));
  }

  void _validateMatching() async {
    if (_selectedSoftwareIds.isEmpty || _selectedBankStatementIds.isEmpty) return;
    setState(() => _isProcessingMatch = true);

    double totalSoftware = _softwareMatchTotal;
    double totalBank = _bankMatchTotal;

    String bankLabels = _bankTransactions
        .where((t) => _selectedBankStatementIds.contains(t.id))
        .map((t) => t.description)
        .join(" / ");

    if (totalSoftware.abs() > totalBank.abs() + 0.001) {
      double resteAPayer = double.parse((totalSoftware - totalBank).toStringAsFixed(2));
      for (var id in _selectedSoftwareIds) {
        await _apiService.updateBankTransaction(id, {'isReconciled': false, 'paymentStatus': 'partial', 'remainingAmount': resteAPayer, 'source': bankLabels});
      }
      for (var id in _selectedBankStatementIds) {
        await _apiService.updateBankTransaction(id, {'isReconciled': true, 'matchedDocumentId': _selectedSoftwareIds.join(','), 'paymentStatus': 'completed'});
      }
    } else {
      for (var id in _selectedSoftwareIds) {
        await _apiService.updateBankTransaction(id, {'isReconciled': true, 'paymentStatus': 'completed', 'remainingAmount': 0.0, 'matchedDocumentId': _selectedBankStatementIds.join(','), 'source': bankLabels});
      }
      for (var id in _selectedBankStatementIds) {
        await _apiService.updateBankTransaction(id, {'isReconciled': true, 'paymentStatus': 'completed', 'matchedDocumentId': _selectedSoftwareIds.join(',')});
      }
    }

    setState(() {
      _selectedSoftwareIds.clear();
      _selectedBankStatementIds.clear();
      _isProcessingMatch = false;
    });
    await _loadData();
  }

  void _cancelMatchingPair(BankTransaction softwareTx) async {
    setState(() => _isLoading = true);
    await _apiService.updateBankTransaction(softwareTx.id, {'isReconciled': false, 'matchedDocumentId': "", 'matchedDocumentNumber': "", 'source': null});
    if (softwareTx.matchedDocumentId != null) {
      final bankIds = softwareTx.matchedDocumentId!.split(',');
      for (var id in bankIds) {
        await _apiService.updateBankTransaction(id, {'isReconciled': false, 'matchedDocumentId': ""});
      }
    }
    await _loadData();
  }

  void _cancelFullReconciliation(ReconciliationRecord record) async {
    setState(() => _isLoading = true);
    for (String bankTxId in record.bankTxIds) {
      await _apiService.updateBankTransaction(bankTxId, {'isReconciled': false, 'matchedDocumentId': "", 'matchedDocumentNumber': ""});
    }
    for (String softwareId in record.invoiceIds) {
      await _apiService.updateBankTransaction(softwareId, {'isReconciled': false, 'matchedDocumentId': "", 'matchedDocumentNumber': "", 'source': null});
    }
    await _apiService.deleteReconciliation(record.id);
    await _loadData();
  }

  void _deleteReportOnly(ReconciliationRecord record) async {
    await _apiService.deleteReconciliation(record.id);
    await _loadData();
  }

  void _performFinalArchive(List<BankTransaction> selectedSoftwareTxs, double total) async {
    setState(() => _isLoading = true);
    final List<String> softwareTxIds = selectedSoftwareTxs.map((t) => t.id).toList();
    final Set<String> bankTxIds = {};
    for (var tx in selectedSoftwareTxs) {
      if (tx.matchedDocumentId != null && tx.matchedDocumentId!.isNotEmpty) {
        bankTxIds.addAll(tx.matchedDocumentId!.split(','));
      }
    }
    final record = ReconciliationRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bankAccountId: _selectedBankPlanAccount?.id ?? _selectedBankPlanAccount?.number ?? '',
      month: _selectedMonth,
      statementBalance: total,
      softwareBalance: total,
      difference: 0,
      invoiceIds: softwareTxIds,
      bankTxIds: bankTxIds.toList(),
      reconciledAt: DateTime.now(),
      totalAmount: total,
    );
    await _apiService.createReconciliation(record);
    setState(() => _selectedReconciledIds.clear());
    await _loadData();
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(190),
        child: Column(
          children: [
            AppBar(
              title: Text("Rapprochement Bancaire", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              elevation: 0,
              leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: isDark ? primaryColor : Colors.black, size: 20), onPressed: () => Navigator.pop(context)),
              actions: [
                IconButton(icon: const Icon(Icons.auto_awesome, color: Color(0xFF49F6C7)), onPressed: _runAutoMatching),
                IconButton(icon: Icon(Icons.file_upload_outlined, color: isDark ? Colors.white : Colors.black), onPressed: () {}),
              ],
            ),
            _buildBankBanner(),
            _buildSoldeComptableTotalInfo(),
            TabBar(controller: _tabController, indicatorColor: primaryColor, labelColor: isDark ? primaryColor : Colors.black, unselectedLabelColor: Colors.grey, tabs: const [Tab(text: "À MATCHER"), Tab(text: "RAPPROCHÉ")]),
          ],
        ),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : TabBarView(controller: _tabController, children: [_buildMatchingView(), _buildReconciledView()]),
    );
  }

  Widget _buildBankBanner() {
    return Container(height: 35, color: const Color(0xFF232435), padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Icon(Icons.account_balance, color: primaryColor, size: 16),
        const SizedBox(width: 8),
        Expanded(child: DropdownButton<Account>(
          value: _selectedBankPlanAccount, dropdownColor: const Color(0xFF232435), isExpanded: true, underline: const SizedBox.shrink(), icon: Icon(Icons.keyboard_arrow_down, color: primaryColor),
          onChanged: (account) => setState(() { _selectedBankPlanAccount = account; _loadData(); }),
          items: _bankAccountsFromPlan.map((account) => DropdownMenuItem(value: account, child: Text("${account.number} - ${account.name}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))).toList(),
        )),
      ]),
    );
  }

  Widget _buildSoldeComptableTotalInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(height: 35, padding: const EdgeInsets.symmetric(horizontal: 16), color: isDark ? Colors.black26 : Colors.grey[50],
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("SOLDE COMPTABLE TOTAL (512) :", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
        Text("${_softwareSoldeComptableTotal.toStringAsFixed(2)} €", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _softwareSoldeComptableTotal < 0 ? Colors.red : Colors.green)),
      ]),
    );
  }

  Widget _buildMatchingView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final softwareItems = _bankTransactions.where((t) => !t.id.startsWith('csv-') && (t.bankAccountId == _selectedBankPlanAccount?.id || t.bankAccountId == _selectedBankPlanAccount?.number) && (!t.isReconciled || t.paymentStatus == 'partial')).toList();
    final bankItems = _bankTransactions.where((t) => t.id.startsWith('csv-') && (t.bankAccountId == _selectedBankPlanAccount?.id || t.bankAccountId == _selectedBankPlanAccount?.number) && !t.isReconciled).toList();
    return Column(children: [_buildMatchingHeader(), Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Row(children: [Expanded(child: _buildMatchingColumn("RELEVÉ BANCAIRE", Icons.account_balance, bankItems, false)), VerticalDivider(width: 1, color: isDark ? Colors.white10 : Colors.grey[300]), Expanded(child: _buildMatchingColumn("COMPTABILITÉ (512)", Icons.computer, softwareItems, true))])) )]);
  }

  Widget _buildMatchingHeader() {
    double sTotal = _softwareMatchTotal; double bTotal = _bankMatchTotal; double diff = (sTotal - bTotal).abs(); bool isBalanced = diff <= 0.01; bool canMatch = (isBalanced || (sTotal.abs() > bTotal.abs())) && (_selectedSoftwareIds.isNotEmpty && _selectedBankStatementIds.isNotEmpty);
    return Container(margin: const EdgeInsets.all(12), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF232435), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        _buildHeaderStat("LOGICIEL", sTotal, Colors.white), const Spacer(),
        _buildHeaderStat("BANQUE", bTotal, Colors.white), const Spacer(),
        _buildHeaderStat("DIFF.", sTotal - bTotal, isBalanced ? const Color(0xFF49F6C7) : Colors.orange), const SizedBox(width: 10),
        ElevatedButton(onPressed: (canMatch && !_isProcessingMatch) ? _validateMatching : null, style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), minimumSize: const Size(80, 32)), child: Text(_isProcessingMatch ? "..." : (sTotal.abs() > bTotal.abs() + 0.01 ? "PARTIEL" : "MATCHER"), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)))
      ]),
    );
  }

  Widget _buildHeaderStat(String label, double value, Color color) {
    return Column(mainAxisSize: MainAxisSize.min, children: [Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)), Text("${value.toStringAsFixed(2)} €", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color))]);
  }

  Widget _buildMatchingColumn(String title, IconData icon, List<BankTransaction> items, bool isSoftwareSide) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [_buildSectionTitle(title, icon), Expanded(child: items.isEmpty ? Center(child: Text("Aucun élément", style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey[400]))) : ListView.builder(itemCount: items.length, itemBuilder: (ctx, idx) {
        final tx = items[idx];
        final double displayAmount = (isSoftwareSide && tx.paymentStatus == 'partial' && tx.remainingAmount != null) ? tx.remainingAmount! : tx.amount;
        final bool isSelected = isSoftwareSide ? _selectedSoftwareIds.contains(tx.id) : _selectedBankStatementIds.contains(tx.id);
        return InkWell(onTap: () => setState(() { if (isSoftwareSide) { if (_selectedSoftwareIds.contains(tx.id)) _selectedSoftwareIds.remove(tx.id); else _selectedSoftwareIds.add(tx.id); } else { if (_selectedBankStatementIds.contains(tx.id)) _selectedBankStatementIds.remove(tx.id); else _selectedBankStatementIds.add(tx.id); } }),
            child: Container(margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4), padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: isSelected ? primaryColor.withOpacity(0.1) : (isDark ? const Color(0xFF232435) : Colors.white), borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? primaryColor : (isDark ? Colors.white10 : Colors.grey[200]!))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tx.description, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: isDark ? Colors.white : Colors.black), maxLines: 2, overflow: TextOverflow.ellipsis),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(DateFormat('dd/MM').format(tx.date), style: const TextStyle(fontSize: 8, color: Colors.grey)),
                  Text(formatCurrency(displayAmount, tx.currency ?? 'EUR'), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: displayAmount < 0 ? Colors.red : Colors.green)),
                ]),
                if (isSoftwareSide && tx.paymentStatus == 'partial') Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.orange.withOpacity(0.3))), child: Text("PARTIEL", style: TextStyle(fontSize: 7, color: Colors.orange[900], fontWeight: FontWeight.bold)))
              ])
            )
        );
      }))]);
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 6), color: isDark ? Colors.black26 : Colors.grey[50], child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 12, color: Colors.grey), const SizedBox(width: 4), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.grey))]));
  }

  Widget _buildReconciledView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final archivedIds = _pastReconciliations.expand((r) => [...r.bankTxIds, ...r.invoiceIds]).toSet();
    final currentMatchedSoftwareTxs = _bankTransactions.where((t) => t.isReconciled && !t.id.startsWith('csv-') && !archivedIds.contains(t.id) && (t.bankAccountId == _selectedBankPlanAccount?.id || t.bankAccountId == _selectedBankPlanAccount?.number)).toList();

    return Column(
      children: [
        _buildFinalValidationHeader(currentMatchedSoftwareTxs),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text("COMPTABILITÉ - LIGNES RAPPROCHÉES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? Colors.white54 : Colors.grey)),
              const SizedBox(height: 8),
              if (currentMatchedSoftwareTxs.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(20), child: Text("Aucune ligne en attente.", style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey)))),
              ...currentMatchedSoftwareTxs.map((tx) {
                final isSelected = _selectedReconciledIds.contains(tx.id);
                return Card(
                  elevation: 0, margin: const EdgeInsets.symmetric(vertical: 4),
                  color: isSelected ? primaryColor.withOpacity(0.05) : (isDark ? const Color(0xFF232435) : Colors.white),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSelected ? primaryColor : (isDark ? Colors.white10 : Colors.grey[200]!))),
                  child: ListTile(
                    onTap: () => setState(() { if (isSelected) _selectedReconciledIds.remove(tx.id); else _selectedReconciledIds.add(tx.id); }),
                    dense: true, leading: Icon(isSelected ? Icons.check_box : Icons.check_box_outline_blank, color: isSelected ? primaryColor : Colors.grey),
                    title: Text(tx.description, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? Colors.white : Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text("${DateFormat('dd/MM/yyyy').format(tx.date)} • Doc: ${tx.matchedDocumentNumber ?? 'Journal'}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(formatCurrency(tx.amount, tx.currency ?? 'EUR'), style: TextStyle(fontWeight: FontWeight.bold, color: tx.amount < 0 ? Colors.red : Colors.green, fontSize: 11)),
                      IconButton(icon: const Icon(Icons.undo, color: Colors.red, size: 18), onPressed: () => _cancelMatchingPair(tx)),
                    ]),
                  ),
                );
              }),
              const Divider(height: 40),
              Text("HISTORIQUE DES RAPPORTS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? Colors.white54 : Colors.grey)),
              const SizedBox(height: 8),
              ..._pastReconciliations.where((r) => r.bankAccountId == _selectedBankPlanAccount?.id || r.bankAccountId == _selectedBankPlanAccount?.number).map((rec) =>
                  Card(color: isDark ? const Color(0xFF232435) : Colors.white, elevation: 0, margin: const EdgeInsets.symmetric(vertical: 4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!)),
                    child: ListTile(dense: true, leading: const Icon(Icons.description, color: Colors.blue), title: Text(DateFormat('MMMM yyyy', 'fr_FR').format(rec.month).toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? Colors.white : Colors.black)), subtitle: Text("${rec.bankTxIds.length} transactions • ${rec.totalAmount.toStringAsFixed(2)} €", style: const TextStyle(fontSize: 10, color: Colors.grey)), trailing: PopupMenuButton<String>(icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey), onSelected: (v) { if (v == 'cancel') _cancelFullReconciliation(rec); if (v == 'delete') _deleteReportOnly(rec); }, itemBuilder: (c) => [const PopupMenuItem(value: 'cancel', child: Text("Annuler")), const PopupMenuItem(value: 'delete', child: Text("Supprimer"))])),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinalValidationHeader(List<BankTransaction> softwareTxs) {
    double totalChecked = 0.0;
    for (var tx in softwareTxs) { if (_selectedReconciledIds.contains(tx.id)) totalChecked += tx.amount; }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E2C) : Colors.white, border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!))),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: InkWell(onTap: () {}, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(border: Border.all(color: isDark ? Colors.white24 : Colors.grey[300]!), borderRadius: BorderRadius.circular(8)), child: Text(DateFormat('MMMM yyyy', 'fr_FR').format(_selectedMonth), style: TextStyle(fontSize: 11, color: isDark ? Colors.white : Colors.black))))),
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: isDark ? Colors.green.withOpacity(0.1) : const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8), border: Border.all(color: primaryColor)), child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text("TOTAL SÉLECTIONNÉ", style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)), Text(NumberFormat.simpleCurrency(name: _selectedBankPlanAccount?.currency ?? 'EUR').format(totalChecked), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? primaryColor : Colors.black))])),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _selectedReconciledIds.isNotEmpty ? () => _performFinalArchive(softwareTxs.where((t) => _selectedReconciledIds.contains(t.id)).toList(), totalChecked) : null, style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text("VALIDER L'ÉTAT ET GÉNÉRER LE RAPPORT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)))),
        ],
      ),
    );
  }
}
