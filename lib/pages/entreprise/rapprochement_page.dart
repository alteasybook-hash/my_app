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
  final AccountingAI _accountingAI = AccountingAI(apiKey: 'VOTRE_CLE_ICI');
  final Color primaryColor = const Color(0xFF49F6C7);

  // --- ÉTAT ---
  List<BankTransaction> _bankTransactions = []; // Contient TOUT (Logiciel + CSV)
  List<Account> _bankAccountsFromPlan = [];
  List<ReconciliationRecord> _pastReconciliations = [];
  Account? _selectedBankPlanAccount;

  double _softwareSoldeComptableTotal = 0.0;
  bool _isLoading = true;
  bool _isProcessingMatch = false;

  final Set<String> _selectedSoftwareIds = {};
  final Set<String> _selectedBankStatementIds = {};
  final Set<String> _selectedReconciledIds = {}; // Pour la sélection finale (onglet Rapproché)
  String _selectedAccountingStandard = "France (PCG)";
  String? _selectedEntityId;

  String formatCurrency(double amount, String currencyCode) {
    final format = NumberFormat.simpleCurrency(name: currencyCode);
    return format.format(amount);
  }

  String formatBankAmount(double amount, String? bankCurrency) {
    // Si le compte n'a pas de devise, on met EUR par défaut
    final currencyCode = bankCurrency ?? 'EUR';
    final format = NumberFormat.simpleCurrency(name: currencyCode);
    return format.format(amount);
  }


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

  // --- CHARGEMENT DES DONNÉES ---
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

  // --- LOGIQUE DE MATCHING ---
  BankTransaction? _findTransaction(String id) {
    try {
      return _bankTransactions.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  double get _softwareMatchTotal {
    double total = 0.0;
    for (var id in _selectedSoftwareIds) {
      final tx = _findTransaction(id);
      if (tx != null) {
        total += (tx.paymentStatus == 'partial' && tx.remainingAmount != null)
            ? tx.remainingAmount!
            : tx.amount;
      }
    }
    return double.parse(total.toStringAsFixed(2));
  }

  double get _bankMatchTotal {
    double total = 0.0;
    for (var id in _selectedBankStatementIds) {
      final tx = _findTransaction(id);
      if (tx != null) total += tx.amount;
    }
    return double.parse(total.toStringAsFixed(2));
  }

  // --- ACTIONS MATCHING ---
  void _runAutoMatching() {
    final pendingSoftwareTx = _bankTransactions.where((t) => !t.isReconciled && !t.id.startsWith('csv-') && !t.id.startsWith('ofx-') && (t.bankAccountId == _selectedBankPlanAccount?.id || t.bankAccountId == _selectedBankPlanAccount?.number)).toList();
    final pendingBankTx = _bankTransactions.where((t) => !t.isReconciled && (t.id.startsWith('csv-') || t.id.startsWith('ofx-')) && (t.bankAccountId == _selectedBankPlanAccount?.id || t.bankAccountId == _selectedBankPlanAccount?.number)).toList();

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

  void _undoMatching(BankTransaction tx) async {
    setState(() => _isLoading = true);
    await _apiService.updateBankTransaction(tx.id, {
      'isReconciled': false,
      'matchedDocumentId': null,
      'matchedDocumentNumber': null,
      'paymentStatus': null,
      'remainingAmount': null,
      'source': null
    });
    if (tx.matchedDocumentId != null) {
      final ids = tx.matchedDocumentId!.split(',');
      for (var id in ids) {
        await _apiService.updateBankTransaction(id, {'isReconciled': false});
      }
    }
    await _loadData();
  }

  void _validateMatching() async {
    if (_selectedSoftwareIds.isEmpty || _selectedBankStatementIds.isEmpty) return;
    setState(() => _isProcessingMatch = true);

    double totalSoftware = _softwareMatchTotal;
    double totalBank = _bankMatchTotal;

    // Récupérer les descriptions des lignes de banque pour les mettre dans "source" des lignes logiciel
    String bankLabels = _bankTransactions
        .where((t) => _selectedBankStatementIds.contains(t.id))
        .map((t) => t.description)
        .join(" / ");

    if (totalSoftware.abs() > totalBank.abs() + 0.001) {
      double resteAPayer = double.parse((totalSoftware - totalBank).toStringAsFixed(2));
      for (var id in _selectedSoftwareIds) {
        await _apiService.updateBankTransaction(id, {
          'isReconciled': false,
          'paymentStatus': 'partial',
          'remainingAmount': resteAPayer,
          'source': bankLabels
        });
      }
      for (var id in _selectedBankStatementIds) {
        await _apiService.updateBankTransaction(id, {'isReconciled': true, 'matchedDocumentId': _selectedSoftwareIds.join(','), 'paymentStatus': 'completed'});
      }
    } else {
      String status = (totalBank.abs() > totalSoftware.abs() + 0.01) ? 'overpaid' : 'completed';
      double surplus = double.parse((totalBank.abs() - totalSoftware.abs()).abs().toStringAsFixed(2));
      for (var id in _selectedSoftwareIds) {
        await _apiService.updateBankTransaction(id, {
          'isReconciled': true,
          'paymentStatus': 'completed',
          'remainingAmount': 0.0,
          'matchedDocumentId': _selectedBankStatementIds.join(','),
          'source': bankLabels
        });
      }
      for (var id in _selectedBankStatementIds) {
        await _apiService.updateBankTransaction(id, {'isReconciled': true, 'paymentStatus': status, 'surplusAmount': surplus > 0.01 ? surplus : null, 'matchedDocumentId': _selectedSoftwareIds.join(',')});
      }
    }

    setState(() {
      _selectedSoftwareIds.clear();
      _selectedBankStatementIds.clear();
      _isProcessingMatch = false;
    });
    await _loadData();
  }

  // --- UI PRINCIPALE ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(190),
        child: Column(
          children: [
            AppBar(
              title: const Text("Rapprochement Bancaire", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20), onPressed: () => Navigator.pop(context)),
              actions: [
                IconButton(icon: const Icon(Icons.auto_awesome, color: Color(0xFF49F6C7)), onPressed: _runAutoMatching),
                IconButton(icon: const Icon(Icons.file_upload_outlined, color: Colors.black), onPressed: _importCSV),
              ],
            ),
            _buildBankBanner(),
            _buildSoldeComptableTotalInfo(),
            TabBar(controller: _tabController, indicatorColor: primaryColor, labelColor: Colors.black, tabs: const [Tab(text: "À MATCHER"), Tab(text: "RAPPROCHÉ")]),
          ],
        ),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : TabBarView(controller: _tabController, children: [_buildMatchingView(), _buildReconciledView()]),
    );
  }


  Widget _buildBankBanner() {
    return Container(height: 35, color: Color(0xFF232435), padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Icon(Icons.account_balance, color: primaryColor, size: 16),
        const SizedBox(width: 8),
        Expanded(child: DropdownButton<Account>(
          value: _selectedBankPlanAccount, dropdownColor: Color(0xFF232435), isExpanded: true, underline: const SizedBox.shrink(), icon: Icon(Icons.keyboard_arrow_down, color: primaryColor),
          onChanged: (account) => setState(() { _selectedBankPlanAccount = account; _selectedSoftwareIds.clear(); _selectedBankStatementIds.clear(); _selectedReconciledIds.clear(); _loadData(); }),
          items: _bankAccountsFromPlan.map((account) => DropdownMenuItem(value: account, child: Text("${account.number} - ${account.name}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))).toList(),
        )),
      ]),
    );
  }

  Widget _buildSoldeComptableTotalInfo() {
    return Container(height: 35, padding: const EdgeInsets.symmetric(horizontal: 16), color: Colors.grey[50],
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("SOLDE COMPTABLE TOTAL (512) :", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
        Text("${_softwareSoldeComptableTotal.toStringAsFixed(2)} €", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _softwareSoldeComptableTotal < 0 ? Colors.red : Colors.green)),
      ]),
    );
  }

  Widget _buildMatchingView() {
    final softwareItems = _bankTransactions.where((t) => !t.id.startsWith('csv-') && !t.id.startsWith('ofx-') && (t.bankAccountId == _selectedBankPlanAccount?.id || t.bankAccountId == _selectedBankPlanAccount?.number) && (!t.isReconciled || t.paymentStatus == 'partial')).toList();
    final bankItems = _bankTransactions.where((t) => (t.id.startsWith('csv-') || t.id.startsWith('ofx-')) && (t.bankAccountId == _selectedBankPlanAccount?.id || t.bankAccountId == _selectedBankPlanAccount?.number) && !t.isReconciled).toList();
    return Column(children: [_buildMatchingHeader(), Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Row(children: [Expanded(child: _buildMatchingColumn("RELEVÉ BANCAIRE", Icons.account_balance, bankItems, false)), const VerticalDivider(width: 1, color: Colors.grey), Expanded(child: _buildMatchingColumn("COMPTABILITÉ (512)", Icons.computer, softwareItems, true))])) )]);
  }

  Widget _buildMatchingHeader() {
    double sTotal = _softwareMatchTotal; double bTotal = _bankMatchTotal; double diff = (sTotal - bTotal).abs(); bool isBalanced = diff <= 0.01; bool canMatch = (isBalanced || (sTotal.abs() > bTotal.abs())) && (_selectedSoftwareIds.isNotEmpty && _selectedBankStatementIds.isNotEmpty);
    return Container(margin: const EdgeInsets.all(12), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Color(0xFF232435), borderRadius: BorderRadius.circular(12), border: Border.all(color: Color(0xFF232435)!)),
      child: Row(children: [
        _buildHeaderStat("LOGICIEL", sTotal, Colors.white), const Spacer(),
        _buildHeaderStat("BANQUE", bTotal, Colors.white), const Spacer(),
        _buildHeaderStat("DIFF.", sTotal - bTotal, isBalanced ? Color(0xFF49F6C7) : Colors.orange), const SizedBox(width: 10),
        ElevatedButton(onPressed: (canMatch && !_isProcessingMatch) ? _validateMatching : null, style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), minimumSize: const Size(80, 32)), child: Text(_isProcessingMatch ? "..." : (sTotal.abs() > bTotal.abs() + 0.01 ? "PARTIEL" : "MATCHER"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)))
      ]),
    );
  }

  Widget _buildHeaderStat(String label, double value, Color color) {
    return Column(mainAxisSize: MainAxisSize.min, children: [Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)), Text("${value.toStringAsFixed(2)} €", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color))]);
  }

  Widget _buildMatchingColumn(String title, IconData icon, List<BankTransaction> items, bool isSoftwareSide) {
    return Column(children: [_buildSectionTitle(title, icon), Expanded(child: items.isEmpty ? Center(child: Text("Aucun élément", style: TextStyle(fontSize: 10, color: Colors.grey[400]))) : ListView.builder(itemCount: items.length, itemBuilder: (ctx, idx) {
        final tx = items[idx];
        final double displayAmount = (isSoftwareSide && tx.paymentStatus == 'partial' && tx.remainingAmount != null) ? tx.remainingAmount! : tx.amount;
        final bool isSelected = isSoftwareSide ? _selectedSoftwareIds.contains(tx.id) : _selectedBankStatementIds.contains(tx.id);

        return InkWell(onTap: () => setState(() { if (isSoftwareSide) { if (_selectedSoftwareIds.contains(tx.id)) _selectedSoftwareIds.remove(tx.id); else _selectedSoftwareIds.add(tx.id); } else { if (_selectedBankStatementIds.contains(tx.id)) _selectedBankStatementIds.remove(tx.id); else _selectedBankStatementIds.add(tx.id); } }),
            child: Container(margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4), padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? primaryColor : Colors.grey[200]!)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tx.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9), maxLines: 2, overflow: TextOverflow.ellipsis),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(DateFormat('dd/MM').format(tx.date), style: const TextStyle(fontSize: 8, color: Colors.grey)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatCurrency(displayAmount, tx.currency ?? 'EUR'), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: displayAmount < 0 ? Colors.red : Colors.green)),
                      if (tx.originalAmount != null && tx.originalCurrency != null && tx.originalCurrency != (tx.currency ?? 'EUR'))
                        Text("(${tx.originalAmount!.toStringAsFixed(2)} ${tx.originalCurrency})", style: const TextStyle(fontSize: 7, color: Colors.grey, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ]),
                if (isSoftwareSide && tx.paymentStatus == 'partial') Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.orange.withValues(alpha: 0.3))), child: Text("RESTE À PAYER (PARTIEL)", style: TextStyle(fontSize: 7, color: Colors.orange[900], fontWeight: FontWeight.bold)))
              ])
            )
        );
      }))]);
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 6), color: Colors.grey[50], child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 12, color: Colors.grey), const SizedBox(width: 4), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.grey))]));
  }

  // --- ONGLET RAPPROCHÉ (STYLE NETSUITE - ÉTAPE FINALE) ---


  Widget _buildReconciledView() {
    // 1. Identifier les transactions déjà archivées
    final archivedIds = _pastReconciliations
        .expand((r) => [...r.bankTxIds, ...r.invoiceIds])
        .toSet();

    // 2. Récupérer UNIQUEMENT les transactions LOGICIEL matchées mais non validées
    final currentMatchedSoftwareTxs = _bankTransactions.where((t) {
      final isFromSoftware = !t.id.startsWith('csv-') &&
          !t.id.startsWith('ofx-');

      return t.isReconciled &&
          isFromSoftware &&
          !archivedIds.contains(t.id) &&
          (t.bankAccountId == _selectedBankPlanAccount?.id ||
              t.bankAccountId == _selectedBankPlanAccount?.number);
    }).toList();

    return Column(
      children: [
        // Header avec calcul du solde dynamique
        _buildFinalValidationHeader(currentMatchedSoftwareTxs),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Text(
                  "COMPTABILITÉ - LIGNES RAPPROCHÉES (EN ATTENTE DE RAPPORT)",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Colors.grey)),
              const SizedBox(height: 8),

              if (currentMatchedSoftwareTxs.isEmpty)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                            "Aucune ligne rapprochée en attente de validation.",
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey)))),
              ...currentMatchedSoftwareTxs.map((tx) {
                final isSelected = _selectedReconciledIds.contains(tx.id);
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: isSelected
                      ? primaryColor.withValues(alpha: 0.05)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                          color: isSelected ? primaryColor : Colors
                              .grey[200]!)),
                  child: ListTile(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedReconciledIds.remove(tx.id);
                        } else {
                          _selectedReconciledIds.add(tx.id);
                        }
                      });
                    },
                    dense: true,
                    leading: Icon(
                      isSelected ? Icons.check_box : Icons
                          .check_box_outline_blank,
                      color: isSelected ? primaryColor : Colors.grey,
                    ),
                    title: Text(tx.description,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${DateFormat('dd/MM/yyyy').format(tx.date)} • Doc: ${tx.matchedDocumentNumber ?? 'Journal'}",
                            style: const TextStyle(fontSize: 10)),
                        if (tx.source != null)
                          Text("Matché avec: ${tx.source}",
                            style: TextStyle(fontSize: 9, color: Colors.blue[800], fontStyle: FontStyle.italic)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(formatCurrency(tx.amount, tx.currency ?? 'EUR'),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: tx.amount < 0 ? Colors.red : Colors.green,
                                    fontSize: 11)),
                            if (tx.originalAmount != null && tx.originalCurrency != null && tx.originalCurrency != (tx.currency ?? 'EUR'))
                              Text("${tx.originalAmount!.toStringAsFixed(2)} ${tx.originalCurrency}", style: const TextStyle(fontSize: 8, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                          onPressed: () => _showMatchDetails(tx),
                        ),
                        IconButton(
                          icon: const Icon(
                              Icons.undo, color: Colors.red, size: 18),
                          tooltip: "Annuler le rapprochement",
                          onPressed: () => _cancelMatchingPair(tx),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const Divider(height: 40),
              const Text("HISTORIQUE DES ÉTATS ET RAPPORTS",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Colors.grey)),
              const SizedBox(height: 8),

              // Liste de l'historique
              ..._pastReconciliations
                  .where((r) =>
              r.bankAccountId == _selectedBankPlanAccount?.id ||
                  r.bankAccountId == _selectedBankPlanAccount?.number)
                  .map((rec) =>
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey[200]!)),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(
                          Icons.description, color: Colors.blue),
                      title: Text(
                          DateFormat('MMMM yyyy', 'fr_FR')
                              .format(rec.month)
                              .toUpperCase(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11)),
                      subtitle: Text(
                          "${rec.bankTxIds.length} transactions • ${rec
                              .totalAmount.toStringAsFixed(2)} €",
                          style: const TextStyle(fontSize: 10)),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(
                            Icons.more_vert, size: 20, color: Colors.grey),
                        onSelected: (value) {
                          if (value == 'print') _printReconciliationReport(rec);
                          if (value == 'cancel') _cancelFullReconciliation(rec);
                          if (value == 'delete') _deleteReportOnly(rec);
                        },
                        itemBuilder: (context) =>
                        [
                          const PopupMenuItem(
                            value: 'print',
                            child: Text(
                                "Imprimer", style: TextStyle(fontSize: 12)),
                          ),
                          const PopupMenuItem(
                            value: 'cancel',
                            child: Text("Annuler (Renvoyer à matcher)",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.orange)),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text("Supprimer l'historique",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }


  void _showMatchDetails(BankTransaction softwareTx) {
    // Retrouver la ligne de banque correspondante via matchedDocumentId
    final bankTxId = softwareTx.matchedDocumentId?.split(',').first;
    final bankTx = _bankTransactions.firstWhere((t) => t.id == bankTxId, orElse: () => softwareTx);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Détails du rapprochement", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("LIGNE LOGICIEL :", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            Text(softwareTx.description, style: const TextStyle(fontSize: 12)),
            Text("Montant (Banque) : ${formatCurrency(softwareTx.amount, softwareTx.currency ?? 'EUR')}", style: const TextStyle(fontSize: 12)),
            if (softwareTx.originalAmount != null)
              Text("Montant (Facture) : ${formatCurrency(softwareTx.originalAmount!, softwareTx.originalCurrency ?? '???')}", style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            if (softwareTx.exchangeRate != null && softwareTx.exchangeRate != 1.0)
              Text("Taux appliqué : ${softwareTx.exchangeRate}", style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),

            const Divider(height: 24),
            const Text("LIGNE BANQUE (RELEVÉ) :", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            Text(bankTx.description, style: const TextStyle(fontSize: 12)),
            Text("Date banque : ${DateFormat('dd/MM/yyyy').format(bankTx.date)}", style: const TextStyle(fontSize: 12)),
            Text("Montant banque : ${formatCurrency(bankTx.amount, bankTx.currency ?? 'EUR')}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("FERMER"))],
      ),
    );
  }

  void _cancelMatchingPair(BankTransaction softwareTx) async {
    setState(() => _isLoading = true);
    try {
      // 1. Dé-reconcilier la ligne logiciel
      await _apiService.updateBankTransaction(softwareTx.id, {
        'isReconciled': false,
        'matchedDocumentId': "",
        'matchedDocumentNumber': "",
        'source': null
      });

      // 2. Dé-reconcilier la/les ligne(s) de banque liée(s)
      if (softwareTx.matchedDocumentId != null) {
        final bankIds = softwareTx.matchedDocumentId!.split(',');
        for (var id in bankIds) {
          await _apiService.updateBankTransaction(id, {'isReconciled': false, 'matchedDocumentId': ""});
        }
      }

      await _loadData();
    } catch (e) {
      debugPrint("Erreur annulation : $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- LOGIQUE D'ANNULATION COMPLÈTE ---
  void _cancelFullReconciliation(ReconciliationRecord record) async {
    setState(() => _isLoading = true);
    try {
      // On boucle sur toutes les transactions du rapport pour les renvoyer à l'onglet "A Matcher"
      for (String bankTxId in record.bankTxIds) {
        final txIndex = _bankTransactions.indexWhere((t) => t.id == bankTxId);
        if (txIndex != -1) {
          final tx = _bankTransactions[txIndex];
          final updatedTx = tx.copyWith(isReconciled: false, matchedDocumentId: "", matchedDocumentNumber: "");
          await _apiService.updateBankTransaction(tx.id, updatedTx.toJson());
        }
      }

      for (String softwareId in record.invoiceIds) {
        final txIndex = _bankTransactions.indexWhere((t) => t.id == softwareId);
        if (txIndex != -1) {
          final tx = _bankTransactions[txIndex];
          final updatedTx = tx.copyWith(isReconciled: false, matchedDocumentId: "", matchedDocumentNumber: "", source: null);
          await _apiService.updateBankTransaction(tx.id, updatedTx.toJson());
        }
      }

      await _apiService.deleteReconciliation(record.id);
      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rapprochement annulé : les lignes sont revenues dans l'onglet 'À Matcher'"), backgroundColor: Colors.orange));
    } catch (e) {
      debugPrint("Erreur lors de l'annulation complète: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }


  void _deleteReportOnly(ReconciliationRecord record) async {
    setState(() => _isLoading = true);
    try {
      // 1. Créer l'entrée dans l'historique général AVANT de supprimer
      final historyEntry = HistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        documentId: record.id,
        documentNumber: "RAPPORT-${DateFormat('MM-yyyy').format(record.month)}",
        type: HistoryType.report,
        action: HistoryAction.deleted,
        timestamp: DateTime.now(),
        data: record.toJson(),
      );
      await _apiService.createHistoryEntry(historyEntry);

      // 2. Archiver les transactions liées sans les remettre dans le flux de matching
      for (String bankTxId in record.bankTxIds) {
        final txIndex = _bankTransactions.indexWhere((t) => t.id == bankTxId);
        if (txIndex != -1) {
          final tx = _bankTransactions[txIndex];
          // On les marque comme archivées (elles ne seront plus visibles dans les onglets de rapprochement)
          final updatedTx = tx.copyWith(isReconciled: true, bankAccountId: "archived_history", description: "[ARCHIVÉ] ${tx.description}");
          await _apiService.updateBankTransaction(tx.id, updatedTx.toJson());
        }
      }

      for (String softwareId in record.invoiceIds) {
        final txIndex = _bankTransactions.indexWhere((t) => t.id == softwareId);
        if (txIndex != -1) {
          final tx = _bankTransactions[txIndex];
          final updatedTx = tx.copyWith(isReconciled: true, bankAccountId: "archived_history");
          await _apiService.updateBankTransaction(tx.id, updatedTx.toJson());
        }
      }

      // 3. Supprimer le rapport de rapprochement
      await _apiService.deleteReconciliation(record.id);

      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rapport supprimé et envoyé à l'historique général"), backgroundColor: Colors.green));
    } catch (e) {
      debugPrint("Erreur suppression: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }


  bool currentMatchedTxsEmpty(List<BankTransaction> txs) => txs.isEmpty;


  Widget _buildFinalValidationHeader(List<BankTransaction> softwareTxs) {
    double totalChecked = 0.0;
    for (var tx in softwareTxs) {
      if (_selectedReconciledIds.contains(tx.id)) {
        totalChecked += tx.amount;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: InkWell(onTap: () => _selectMonth(context), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)), child: Text(DateFormat('MMMM yyyy', 'fr_FR').format(_selectedMonth), style: const TextStyle(fontSize: 11))))),
              const SizedBox(width: 8),
              Container(padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFF49F6C7))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end,
                      children: [const Text("TOTAL SÉLECTIONNÉ",
                          style: TextStyle(fontSize: 9,
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                        Text(NumberFormat
                            .simpleCurrency(
                            name: _selectedBankPlanAccount?.currency ?? 'EUR')
                            .format(totalChecked),
                            style: const TextStyle(fontSize: 14,
                                fontWeight: FontWeight.bold))

                      ])),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _selectedReconciledIds.isNotEmpty ? () => _performFinalArchive(softwareTxs.where((t) => _selectedReconciledIds.contains(t.id)).toList(), totalChecked) : null, style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text("VALIDER L'ÉTAT ET GÉNÉRER LE RAPPORT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)))),
        ],
      ),
    );
  }


  void _performFinalArchive(List<BankTransaction> selectedSoftwareTxs, double total) async {
    setState(() => _isLoading = true);
    try {
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

      setState(() {
        _pastReconciliations.add(record);
        _selectedReconciledIds.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("État validé et rapport généré !"), backgroundColor: Colors.green));
      await _loadData();
    } catch (e) {
      debugPrint("Erreur validation: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }



  Future<void> _printReconciliationReport(ReconciliationRecord rec) async {
    final pdf = pw.Document();
    final allIds = [...rec.bankTxIds, ...rec.invoiceIds];
    final matchedTxs = _bankTransactions.where((t) => allIds.contains(t.id)).toList();

    pdf.addPage(pw.Page(pageFormat: PdfPageFormat.a4, build: (pw.Context context) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Header(level: 0, child: pw.Text("RAPPORT DE RAPPROCHEMENT BANCAIRE")),
      pw.Text("Compte : ${_selectedBankPlanAccount?.number} - ${_selectedBankPlanAccount?.name}"),
      pw.Text("Période : ${DateFormat('MMMM yyyy', 'fr_FR').format(rec.month)}"),
      pw.Divider(),
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        cellStyle: const pw.TextStyle(fontSize: 8),
        headers: ['DATE', 'DOC LOGICIEL', 'DESCRIPTION', 'MONTANT'],
        data: matchedTxs.map((t) =>
        [
          DateFormat('dd/MM/yyyy').format(t.date),
          t.matchedDocumentNumber ?? '-',
          t.description,
          NumberFormat.simpleCurrency(
              name: _selectedBankPlanAccount?.currency ?? 'EUR'
          ).format(t.amount)
        ]).toList(),
      ),
      // <-- PARENTHÈSE FERMÉE ICI POUR LE TABLEAU

      pw.SizedBox(height: 30),
      // Maintenant ce widget est un enfant direct de Column

      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          "SOLDE RELEVÉ : ${NumberFormat.simpleCurrency(
              name: _selectedBankPlanAccount?.currency ?? 'EUR'
          ).format(rec.statementBalance)}",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      ),

      ])));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: _selectedMonth, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null) setState(() => _selectedMonth = DateTime(picked.year, picked.month));
  }


  // 1. FONCTION PRINCIPALE D'IMPORTATION
  Future<void> _importCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'ofx'],
        withData: true,
      );

      if (result == null) return;

      setState(() => _isLoading = true);

      final file = result.files.first;
      final extension = file.extension?.toLowerCase();

      if (extension == 'ofx') {
        await _processOFX(file.bytes!);
      } else if (extension == 'csv') {
        await _processCSV(file.bytes!);
      } else {
        throw "Format de fichier non supporté (.${extension})";
      }

      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Importation réussie"),
              backgroundColor: Colors.green)
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur d'import : $e"),
              backgroundColor: Colors.red)
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. TRAITEMENT DU CSV (INTELLIGENT)
  Future<void> _processCSV(dynamic bytes) async {
    final content = String.fromCharCodes(bytes);
    final lines = content.split(RegExp(r'\r?\n'));
    if (lines.isEmpty) return;

    final header = lines[0].toLowerCase().split(RegExp(r'[,;]'));

    int dateIdx = header.indexWhere((h) => h.contains('date'));
    int labelIdx = header.indexWhere((h) =>
    h.contains('libellé') || h.contains('desc') || h.contains('label') ||
        h.contains('objet'));
    int amountIdx = header.indexWhere((h) =>
    h.contains('montant') || h.contains('amount') || h.contains('valeur') ||
        h.contains('débit') || h.contains('crédit'));

    if (dateIdx == -1 || amountIdx == -1) {
      throw "Colonnes 'Date' ou 'Montant' introuvables. Vérifiez l'entête du fichier.";
    }

    for (int i = 1; i < lines.length; i++) {
      if (lines[i]
          .trim()
          .isEmpty) continue;
      final row = lines[i].split(RegExp(r'[,;]'));
      if (row.length <= dateIdx || row.length <= amountIdx) continue;

      String rawAmount = row[amountIdx]
          .replaceAll(RegExp(r'[^\d,.-]'), '')
          .replaceAll(',', '.');
      double amount = double.tryParse(rawAmount) ?? 0.0;

      final tx = BankTransaction(
        id: "csv-${DateTime
            .now()
            .millisecondsSinceEpoch}-$i",
        date: _parseDate(row[dateIdx]),
        description: labelIdx != -1 ? row[labelIdx] : "Transaction CSV",
        amount: amount,
        isReconciled: false,
        bankAccountId: _selectedBankPlanAccount?.id,
      );

      await _apiService.createBankTransaction(tx);
    }
  }

  // 3. TRAITEMENT DU OFX (PARSER SIMPLE)
  Future<void> _processOFX(dynamic bytes) async {
    final content = String.fromCharCodes(bytes);

    // On cherche les blocs de transaction <STMTTRN>
    final txRegex = RegExp(r'<STMTTRN>([\s\S]*?)<\/STMTTRN>');
    final matches = txRegex.allMatches(content);

    for (var match in matches) {
      final block = match.group(1)!;

      final dateStr = RegExp(r'<DTPOSTED>(.*)').firstMatch(block)?.group(1) ??
          "";
      final amountStr = RegExp(r'<TRNAMT>(.*)').firstMatch(block)?.group(1) ??
          "0";
      final name = RegExp(r'<NAME>(.*)').firstMatch(block)?.group(1) ??
          RegExp(r'<MEMO>(.*)').firstMatch(block)?.group(1) ??
          "Transaction OFX";

      final tx = BankTransaction(
        id: "ofx-${DateTime
            .now()
            .millisecondsSinceEpoch}-${block.hashCode}",
        date: _parseDate(dateStr),
        description: name.trim(),
        amount: double.tryParse(amountStr.replaceAll(',', '.')) ?? 0.0,
        isReconciled: false,
        bankAccountId: _selectedBankPlanAccount?.id,
      );

      await _apiService.createBankTransaction(tx);
    }
  }

  // 4. ANALYSE DE LA DATE (POUR CSV ET OFX)
  DateTime _parseDate(String dateStr) {
    dateStr = dateStr.replaceAll(RegExp(r'[<>]'), '').trim();
    try {
      // Cas OFX : 20240322...
      if (dateStr.length >= 8 && !dateStr.contains('/') &&
          !dateStr.contains('-')) {
        return DateTime(
          int.parse(dateStr.substring(0, 4)),
          int.parse(dateStr.substring(4, 6)),
          int.parse(dateStr.substring(6, 8)),
        );
      }
      // Cas CSV : DD/MM/YYYY
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        return DateTime(int.parse(parts[2].split(' ')[0]), int.parse(parts[1]),
            int.parse(parts[0]));
      }
      return DateTime.parse(dateStr);
    } catch (e) {
      return DateTime.now();
    }
  }
} // Fin de la classe
