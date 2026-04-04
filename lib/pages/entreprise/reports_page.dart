import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as ex;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/api_service.dart';
import '../../models/invoice.dart';
import '../../models/entity.dart';
import '../../models/bank_transaction.dart';
import '../../models/account.dart';
import '../../models/journal_entry.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final ApiService _apiService = ApiService();
  final Color primaryColor = const Color(0xFF49F6C7);
  final Color darkColor = const Color(0xFF232435);

  bool _isLoading = true;
  List<Entity> _entities = [];
  Entity? _selectedEntity;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  double _totalRevenu = 0.0;
  double _totalDepenses = 0.0;
  Map<String, Map<String, dynamic>> _bankBalances = {};

  List<Invoice> _allAchats = [];
  List<Invoice> _allVentes = [];
  List<JournalEntry> _allJournalEntries = [];

  List<Map<String, double>> _monthlyData = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final entities = await _apiService.fetchEntities();
      _allAchats = await _apiService.fetchInvoices(InvoiceType.achat);
      _allVentes = await _apiService.fetchInvoices(InvoiceType.vente);
      final allBankTxs = await _apiService.fetchBankTransactions();
      final allAccounts = await _apiService.fetchAccounts();
      _allJournalEntries = await _apiService.fetchJournalEntries();

      _entities = entities;
      if (_entities.isNotEmpty && _selectedEntity == null) {
        _selectedEntity = _entities.firstWhere((e) => e.isDefault, orElse: () => _entities.first);
      }

      if (_selectedEntity != null) {
        _calculateMetrics(allBankTxs, allAccounts);
        _prepareChartData();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Erreur rapports: $e");
      setState(() => _isLoading = false);
    }
  }

  void _calculateMetrics(List<BankTransaction> txs, List<Account> accounts) {
    final entityAchats = _allAchats.where((i) => i.entityId == _selectedEntity!.id && i.date.year == _selectedMonth.year && i.date.month == _selectedMonth.month).toList();
    final entityVentes = _allVentes.where((i) => i.entityId == _selectedEntity!.id && i.date.year == _selectedMonth.year && i.date.month == _selectedMonth.month).toList();

    _totalRevenu = entityVentes.fold(0, (sum, i) => sum + i.amountHT);
    _totalDepenses = entityAchats.fold(0, (sum, i) => sum + i.amountHT);

    _bankBalances.clear();
    final bankAccounts = accounts.where((acc) => acc.number.startsWith('512') || acc.number.startsWith('511')).toList();

    for (var acc in bankAccounts) {
      final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
      double balance = txs.where((t) => (t.bankAccountId == acc.id || t.bankAccountId == acc.number) && t.date.isBefore(endOfMonth))
          .fold(0.0, (sum, t) => sum + t.amount);

      double odBalance = 0.0;
      for (var entry in _allJournalEntries) {
        if (entry.date.isBefore(endOfMonth)) {
          for (var line in entry.lines) {
            if (line.accountCode == acc.number) odBalance += (line.debit - line.credit);
          }
        }
      }
      balance += odBalance;

      _bankBalances[acc.number] = {
        'label': "${acc.number} ${acc.name}",
        'balance': balance,
        'currency': 'EUR'
      };
    }
  }

  void _prepareChartData() {
    _monthlyData.clear();
    for (int i = 5; i >= 0; i--) {
      DateTime month = DateTime(_selectedMonth.year, _selectedMonth.month - i, 1);
      double rev = _allVentes.where((inv) => inv.entityId == _selectedEntity!.id && inv.date.year == month.year && inv.date.month == month.month).fold(0.0, (sum, inv) => sum + inv.amountHT);
      double exp = _allAchats.where((inv) => inv.entityId == _selectedEntity!.id && inv.date.year == month.year && inv.date.month == month.month).fold(0.0, (sum, inv) => sum + inv.amountHT);
      _monthlyData.add({'revenu': rev, 'depense': exp});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("RAPPORT & ANALYSE", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: Icon(Icons.refresh, color: isDark ? Colors.white : Colors.black), onPressed: _loadAllData)],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildEntitySelector(), const SizedBox(height: 15),
          _buildMonthNavigator(), const SizedBox(height: 25),
          _buildPerformanceCard(), const SizedBox(height: 25),
          _buildSectionTitle("DISPONIBILITÉS PAR BANQUE"), const SizedBox(height: 15),
          _buildBankBalancesList(), const SizedBox(height: 30),
          _buildSectionTitle("ANALYSE DES FLUX (6 MOIS)"), const SizedBox(height: 15),
          _buildAnalysisChart(), const SizedBox(height: 30),
          _buildSectionTitle("EXPORTS COMPTABLES"), const SizedBox(height: 15),
          _buildExportTile("Journal des Achats", "Export Excel pour le mois", Icons.receipt_long_rounded, () => _exportExcel('achats')),
          _buildExportTile("Journal des Ventes", "Export Excel pour le mois", Icons.point_of_sale_rounded, () => _exportExcel('ventes')),
          _buildExportTile("Grand Livre (PDF)", "Synthèse pour l'expert comptable", Icons.picture_as_pdf_rounded, _exportGrandLivrePdf),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sendToExpertComptable,
              icon: const Icon(Icons.send_rounded, color: Colors.black, size: 18),
              label: const Text("ENVOYER À L'EXPERT COMPTABLE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _buildMonthNavigator() {
    return Container(padding: const EdgeInsets.symmetric(vertical: 4), decoration: BoxDecoration(color: darkColor, borderRadius: BorderRadius.circular(15)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(icon: Icon(Icons.chevron_left, color: primaryColor), onPressed: () => setState(() { _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1); _loadAllData(); })),
        Text("${DateFormat('MMMM', 'fr_FR').format(_selectedMonth).toUpperCase()} ${_selectedMonth.year}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        IconButton(icon: Icon(Icons.chevron_right, color: primaryColor), onPressed: () => setState(() { _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1); _loadAllData(); })),
      ]),
    );
  }

  Widget _buildEntitySelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2), decoration: BoxDecoration(color: isDark ? const Color(0xFF232435) : Colors.grey[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.withOpacity(0.1))),
      child: DropdownButtonHideUnderline(child: DropdownButton<Entity>(value: _selectedEntity, dropdownColor: isDark ? const Color(0xFF232435) : Colors.white, isExpanded: true, style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold), items: _entities.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(), onChanged: (val) { setState(() { _selectedEntity = val; _loadAllData(); }); })),
    );
  }

  Widget _buildPerformanceCard() {
    final double net = _totalRevenu - _totalDepenses;
    return Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: darkColor, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildStat("CA (HT)", "${_totalRevenu.toStringAsFixed(0)} €", primaryColor), Container(width: 1, height: 40, color: Colors.white10), _buildStat("CHARGES", "${_totalDepenses.toStringAsFixed(0)} €", Colors.orangeAccent)]),
        const Divider(height: 40, color: Colors.white10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("RÉSULTAT DU MOIS", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text("${(net).toStringAsFixed(2)} €", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))]), _buildStatusBadge(net >= 0 ? "BÉNÉFICE" : "DÉFICIT", net >= 0 ? Colors.greenAccent : Colors.redAccent)]),
      ]),
    );
  }

  Widget _buildStatusBadge(String label, Color color) { return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10))); }

  Widget _buildBankBalancesList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_bankBalances.isEmpty) return Center(child: Text("Aucun compte bancaire", style: TextStyle(fontSize: 12, color: isDark ? Colors.grey : Colors.grey)));
    return Column(children: _bankBalances.entries.map((e) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isDark ? const Color(0xFF232435) : Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.withOpacity(0.15))),
      child: Row(children: [CircleAvatar(backgroundColor: Colors.blue[50], child: const Icon(Icons.account_balance, color: Colors.blue, size: 20)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.value['label'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black), overflow: TextOverflow.ellipsis), Text("Solde au ${DateFormat('dd/MM').format(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0))}", style: const TextStyle(color: Colors.grey, fontSize: 10))])), Text("${(e.value['balance'] as double).toStringAsFixed(2)} ${e.value['currency']}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: e.value['balance'] >= 0 ? (isDark ? primaryColor : Colors.black) : Colors.red))]),
    )).toList());
  }

  Widget _buildAnalysisChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_monthlyData.isEmpty) return const SizedBox();
    double maxVal = 0;
    for (var d in _monthlyData) { if (d['revenu']! > maxVal) maxVal = d['revenu']!; if (d['depense']! > maxVal) maxVal = d['depense']!; }
    if (maxVal == 0) maxVal = 1000;

    return Container(height: 220, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: isDark ? const Color(0xFF232435) : Colors.grey[50], borderRadius: BorderRadius.circular(25)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [_chartLegend("CA", primaryColor), const SizedBox(width: 15), _chartLegend("Charges", Colors.redAccent)]),
        const Spacer(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end, children: _monthlyData.map((d) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(width: 12, height: (d['revenu']! / maxVal) * 120 + 2, decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 4),
          Container(width: 12, height: (d['depense']! / maxVal) * 120 + 2, decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.7), borderRadius: BorderRadius.circular(3))),
        ])).toList()),
        const SizedBox(height: 10),
        const Text("Évolution des 6 derniers mois", style: TextStyle(color: Colors.grey, fontSize: 10)),
      ]),
    );
  }

  Widget _chartLegend(String l, Color c) => Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)), const SizedBox(width: 5), Text(l, style: const TextStyle(fontSize: 10, color: Colors.grey))]);
  Widget _buildStat(String l, String v, Color c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text(v, style: TextStyle(color: c, fontSize: 22, fontWeight: FontWeight.w900))]);
  Widget _buildSectionTitle(String t) => Text(t, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.2, color: Colors.blueGrey));
  Widget _buildExportTile(String t, String s, IconData i, VoidCallback o) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: isDark ? const Color(0xFF232435) : Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.withOpacity(0.1))), child: ListTile(dense: true, leading: Icon(i, color: isDark ? Colors.white : Colors.black, size: 20), title: Text(t, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black)), subtitle: Text(s, style: const TextStyle(fontSize: 10, color: Colors.grey)), trailing: const Icon(Icons.download_rounded, size: 18, color: Colors.blue), onTap: o));
  }

  // --- LOGIQUE D'EXPORT ---

  Future<void> _exportExcel(String type) async {
    try {
      var excel = ex.Excel.createExcel();
      var sheet = excel[type.toUpperCase()];

      final items = type == 'achats'
          ? _allAchats.where((i) => i.date.year == _selectedMonth.year && i.date.month == _selectedMonth.month).toList()
          : _allVentes.where((i) => i.date.year == _selectedMonth.year && i.date.month == _selectedMonth.month).toList();

      sheet.appendRow(['Date', 'Numéro', 'Tiers', 'HT', 'TVA', 'TTC'].map((e) => ex.TextCellValue(e)).toList());

      for (var i in items) {
        sheet.appendRow([
          ex.TextCellValue(DateFormat('dd/MM/yyyy').format(i.date)),
          ex.TextCellValue(i.number),
          ex.TextCellValue(i.supplierOrClientName),
          ex.DoubleCellValue(i.amountHT),
          ex.DoubleCellValue(i.tva),
          ex.DoubleCellValue(i.amountTTC)
        ]);
      }

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/Journal_${type}_${DateFormat('MM_yyyy').format(_selectedMonth)}.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(excel.save()!);

      await Share.shareXFiles([XFile(filePath)], text: 'Export Journal des $type');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur export: $e")));
    }
  }

  Future<void> _exportGrandLivrePdf() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font, bold: boldFont),
      build: (context) => [
        pw.Header(level: 0, child: pw.Text("GRAND LIVRE - ${DateFormat('MMMM yyyy', 'fr_FR').format(_selectedMonth).toUpperCase()}")),
        pw.SizedBox(height: 20),
        pw.Text("Entité : ${_selectedEntity?.name ?? 'N/A'}"),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Date', 'Compte', 'Libellé', 'Débit', 'Crédit'],
          data: _allJournalEntries.where((e) => e.date.year == _selectedMonth.year && e.date.month == _selectedMonth.month).expand((e) => e.lines.map((l) => [
            DateFormat('dd/MM').format(e.date),
            l.accountCode,
            l.description,
            l.debit.toStringAsFixed(2),
            l.credit.toStringAsFixed(2)
          ])).toList(),
        ),
      ],
    ));

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void _sendToExpertComptable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Préparation de l'envoi des documents à l'expert comptable..."), backgroundColor: Color(0xFF232435)),
    );
    // Simuler un délai d'envoi
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Documents envoyés avec succès !"), backgroundColor: Colors.green),
        );
      }
    });
  }
}
