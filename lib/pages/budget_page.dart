import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as ex;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../models/budget_models.dart';
import '../models/entity.dart';
import '../models/invoice.dart';
import '../models/journal_entry.dart';
import '../models/cost_center.dart';
import '../services/api_service.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final ApiService _apiService = ApiService();
  final Color primaryColor = const Color(0xFF49F6C7);
  final Color darkCardColor = const Color(0xFF232435);
  
  List<Entity> _entities = [];
  Entity? _selectedEntity;
  EntityBudget? _budget;
  bool _isLoading = true;
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<CostCenter> _costCenters = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    _entities = await _apiService.fetchEntities();
    _costCenters = await _apiService.fetchCostCenters();
    if (_entities.isNotEmpty) {
      _selectedEntity = _entities.firstWhere((e) => e.isDefault, orElse: () => _entities.first);
      await _loadBudget();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadBudget() async {
    if (_selectedEntity == null) return;
    
    EntityBudget? budgetDef = await _apiService.fetchEntityBudget(_selectedEntity!.id);
    if (budgetDef == null) {
      budgetDef = EntityBudget(entityId: _selectedEntity!.id, totalBudget: 0.0, departments: [], monthlyExpenses: []);
    }
    
    final allAchats = await _apiService.fetchInvoices(InvoiceType.achat);
    final allJournalEntries = await _apiService.fetchJournalEntries();
    
    final monthAchats = allAchats.where((inv) => 
      inv.entityId == _selectedEntity!.id && 
      inv.date.year == _focusedMonth.year && 
      inv.date.month == _focusedMonth.month
    ).toList();
    
    final monthJournalEntries = allJournalEntries.where((entry) => 
      entry.entityId == _selectedEntity!.id && 
      entry.date.year == _focusedMonth.year && 
      entry.date.month == _focusedMonth.month
    ).toList();

    List<DepartmentBudget> finalDepartments = [];
    
    for (var cc in _costCenters) {
      double actualSpent = 0.0;
      actualSpent += monthAchats
          .where((inv) => inv.costCenterCode == cc.code)
          .fold(0.0, (sum, inv) => sum + inv.amountHT);
          
      for (var entry in monthJournalEntries) {
        for (var line in entry.lines) {
          if (line.costCenterCode == cc.code) {
            actualSpent += (line.debit - line.credit);
          }
        }
      }

      final existing = budgetDef.departments.firstWhere(
        (d) => d.id == cc.id || d.name == cc.serviceName || d.id == cc.code,
        orElse: () => DepartmentBudget(id: cc.id, name: cc.serviceName, percentage: 0.0),
      );
      
      finalDepartments.add(DepartmentBudget(
        id: cc.id,
        name: cc.serviceName,
        percentage: existing.percentage,
        spent: actualSpent,
        color: Colors.primaries[_costCenters.indexOf(cc) % Colors.primaries.length],
        customForecast: existing.customForecast,
      ));
    }

    final locale = Localizations.localeOf(context).toString();
    List<MonthlyExpense> history = [];
    for (int i = 5; i >= 0; i--) {
      DateTime m = DateTime(_focusedMonth.year, _focusedMonth.month - i, 1);
      double totalMonth = allAchats.where((inv) => 
        inv.entityId == _selectedEntity!.id && inv.date.year == m.year && inv.date.month == m.month
      ).fold(0.0, (sum, inv) => sum + inv.amountHT);
      
      for (var entry in allJournalEntries.where((e) => e.entityId == _selectedEntity!.id && e.date.year == m.year && e.date.month == m.month)) {
        for (var line in entry.lines) {
          if (line.costCenterCode != null) totalMonth += (line.debit - line.credit);
        }
      }
      
      history.add(MonthlyExpense(
        month: DateFormat('MMM', locale).format(m),
        amount: totalMonth,
      ));
    }

    setState(() {
      _budget = EntityBudget(
        entityId: _selectedEntity!.id,
        totalBudget: budgetDef!.totalBudget,
        departments: finalDepartments,
        monthlyExpenses: history,
        customGlobalForecast: budgetDef.customGlobalForecast,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.grey[50],
      appBar: AppBar(
        title: _buildEntitySelector(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf_outlined, color: isDark ? primaryColor : Colors.black),
            onPressed: _exportBudgetPdf,
            tooltip: t.export_pdf,
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: isDark ? Colors.white70 : Colors.black54),
            onPressed: () => _showGlobalBudgetSettings(),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildMonthNavigator(),
              Expanded(
                child: _budget == null 
                  ? Center(child: Text(t.select_entity_to_view))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOverrunAlert(),
                          _buildGlobalBudgetCard(),
                          const SizedBox(height: 24),
                          _buildQuickInsights(),
                          const SizedBox(height: 24),
                          _buildDepartmentList(),
                          const SizedBox(height: 24),
                          _buildHistoryChart(),
                          const SizedBox(height: 32),
                          _buildExportSection(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
              ),
            ],
          ),
    );
  }

  Widget _buildOverrunAlert() {
    final t = AppLocalizations.of(context);
    List<String> overruns = [];
    for (var dept in _budget!.departments) {
      final allocated = dept.getAllocatedAmount(_budget!.totalBudget);
      if (allocated > 0 && dept.spent > allocated) {
        overruns.add(dept.name);
      }
    }

    if (overruns.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "${t.budgetAlertTitle} : ${t.budgetAlertMsg}${overruns.join(', ')}${t.budgetAlertSuffix}",
              style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigator() {
    final locale = Localizations.localeOf(context).toString();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: darkCardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: Icon(Icons.chevron_left, color: primaryColor), onPressed: () => _changeMonth(-1)),
          Text(
            "${DateFormat('MMMM', locale).format(_focusedMonth).toUpperCase()} ${_focusedMonth.year}",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1),
          ),
          IconButton(icon: Icon(Icons.chevron_right, color: primaryColor), onPressed: () => _changeMonth(1)),
        ],
      ),
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
      _loadBudget();
    });
  }

  Widget _buildEntitySelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButtonHideUnderline(
      child: DropdownButton<Entity>(
        value: _selectedEntity,
        dropdownColor: isDark ? const Color(0xFF232435) : Colors.white,
        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        items: _entities.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
        onChanged: (v) { if (v != null) { setState(() { _selectedEntity = v; _loadBudget(); }); } },
      ),
    );
  }

  Widget _buildGlobalBudgetCard() {
    final t = AppLocalizations.of(context);
    final spent = _budget!.getTotalSpent();
    final remaining = _budget!.getTotalRemaining();
    final percentage = _budget!.getConsumptionPercentage();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: darkCardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(t.allocations, _budget!.totalBudget, Colors.white),
              _buildStatItem(t.actual_spent, spent, Colors.orangeAccent),
              _buildStatItem(t.available, remaining, remaining < 0 ? Colors.redAccent : primaryColor),
            ],
          ),
          const SizedBox(height: 25),
          Stack(
            children: [
              Container(height: 10, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(5))),
              FractionallySizedBox(
                widthFactor: percentage.clamp(0.0, 1.0),
                child: Container(height: 10, decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.6)]),
                  borderRadius: BorderRadius.circular(5),
                )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.consumption_rate, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
              Text("${(percentage * 100).toStringAsFixed(1)}%", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, double val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("${NumberFormat('#,###').format(val)} €", style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildQuickInsights() {
    final t = AppLocalizations.of(context);
    final now = DateTime.now();
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final daysElapsed = _focusedMonth.year == now.year && _focusedMonth.month == now.month ? now.day : daysInMonth;
    
    double totalForecast = 0;
    if (_budget!.customGlobalForecast != null) {
      totalForecast = _budget!.customGlobalForecast!;
    } else {
      for (var dept in _budget!.departments) {
        totalForecast += dept.getForecast(daysInMonth, daysElapsed);
      }
    }

    return Row(
      children: [
        Expanded(child: InkWell(
          onTap: () => _showEditGlobalForecastDialog(), 
          child: _buildInfoBox(t.forecast_provision, "${totalForecast.toStringAsFixed(0)} €", Icons.trending_up, Colors.blueAccent)
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildInfoBox(t.rh.toUpperCase(), _budget!.departments.length.toString(), Icons.hub, primaryColor)),
      ],
    );
  }

  Widget _buildInfoBox(String title, String val, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
            Text(val, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
          ]),
        ],
      ),
    );
  }

  Widget _buildDepartmentList() {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.analysis_by_service, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.2, color: Colors.blueGrey)),
        const SizedBox(height: 12),
        ..._budget!.departments.map((dept) {
          final allocated = dept.getAllocatedAmount(_budget!.totalBudget);
          final remaining = dept.getRemaining(_budget!.totalBudget);
          final isOver = remaining < 0 && allocated > 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isDark ? darkCardColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isOver ? Colors.redAccent.withOpacity(0.5) : Colors.transparent),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(backgroundColor: dept.color.withOpacity(0.1), child: Icon(Icons.pie_chart, color: dept.color, size: 18)),
              title: Text(dept.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${t.budget}: ${allocated.toStringAsFixed(0)} € | ${t.actual_expenses}: ${dept.spent.toStringAsFixed(0)} €", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  if (isOver) Text(t.budgetAlertTitle, style: const TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("${remaining.toStringAsFixed(0)} €", style: TextStyle(fontWeight: FontWeight.bold, color: remaining < 0 ? Colors.redAccent : Colors.greenAccent)),
                  Text(t.rest, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                ],
              ),
              onTap: () => _showEditForecastDialog(dept),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildHistoryChart() {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.expense_history_6_months, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.2, color: Colors.blueGrey)),
        const SizedBox(height: 16),
        Container(
          height: 180,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: isDark ? darkCardColor : Colors.white, borderRadius: BorderRadius.circular(20)),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _budget!.monthlyExpenses.fold(0.0, (max, e) => e.amount > max ? e.amount : max) * 1.2,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                  if (v.toInt() >= 0 && v.toInt() < _budget!.monthlyExpenses.length) {
                    return Text(_budget!.monthlyExpenses[v.toInt()].month, style: const TextStyle(fontSize: 9, color: Colors.grey));
                  }
                  return const SizedBox.shrink();
                })),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: _budget!.monthlyExpenses.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: e.value.amount, color: primaryColor, width: 14, borderRadius: BorderRadius.circular(4))])).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExportSection() {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.budget_bilan_title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.2, color: Colors.blueGrey)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildExportButton(t.export_pdf, Icons.picture_as_pdf, Colors.redAccent, _exportBudgetPdf)),
            const SizedBox(width: 12),
            Expanded(child: _buildExportButton(t.export_excel, Icons.table_view, Colors.green, _exportExcel)),
          ],
        ),
      ],
    );
  }

  Widget _buildExportButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.15),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  Future<void> _exportBudgetPdf() async {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font, bold: boldFont),
      build: (context) => [
        pw.Header(level: 0, child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text(t.budget_bilan_title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey)),
          pw.Text(DateFormat('MMMM yyyy', locale).format(_focusedMonth).toUpperCase()),
        ])),
        pw.SizedBox(height: 20),
        pw.Text("${t.entity_label} : ${_selectedEntity?.name ?? 'N/A'}"),
        pw.Divider(),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text("${t.budget_envelope} : ${NumberFormat('#,###').format(_budget!.totalBudget)} €"),
            pw.Text("${t.real_consumption} : ${NumberFormat('#,###').format(_budget!.getTotalSpent())} €"),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text("${t.variation} : ${NumberFormat('#,###').format(_budget!.getTotalRemaining())} €", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _budget!.getTotalRemaining() < 0 ? PdfColors.red : PdfColors.green)),
            pw.Text("${t.execution_rate} : ${(_budget!.getConsumptionPercentage() * 100).toStringAsFixed(1)}%"),
          ]),
        ]),
        pw.SizedBox(height: 30),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
          headers: [t.service, t.budget, t.real_consumption, t.gap, t.forecast],
          data: _budget!.departments.map((d) {
            final alloc = d.getAllocatedAmount(_budget!.totalBudget);
            final forecast = d.getForecast(DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day, _focusedMonth.day);
            return [
              d.name,
              "${alloc.toStringAsFixed(0)} €",
              "${d.spent.toStringAsFixed(0)} €",
              "${(alloc - d.spent).toStringAsFixed(0)} €",
              "${forecast.toStringAsFixed(0)} €"
            ];
          }).toList(),
        ),
        pw.Footer(padding: const pw.EdgeInsets.only(top: 20), leading: pw.Text("alt. Accounting - Reporting Financier Avancé", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)))
      ],
    ));

    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'Bilan_Provision_${_selectedEntity?.name}.pdf');
  }

  Future<void> _exportExcel() async {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    var excel = ex.Excel.createExcel();
    var sheet = excel['FORECASTING'];
    
    sheet.appendRow([ex.TextCellValue('${t.budget_bilan_title} - ${DateFormat('MMMM yyyy', locale).format(_focusedMonth)}')]);
    sheet.appendRow([ex.TextCellValue(t.entity_label), ex.TextCellValue(_selectedEntity?.name ?? 'N/A')]);
    sheet.appendRow([ex.TextCellValue('')]);
    sheet.appendRow([ex.TextCellValue(t.service), ex.TextCellValue(t.allocated_budget), ex.TextCellValue(t.actual_expenses), ex.TextCellValue(t.variation), ex.TextCellValue(t.forecast_end_month)]);

    for (var d in _budget!.departments) {
      final alloc = d.getAllocatedAmount(_budget!.totalBudget);
      final forecast = d.getForecast(DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day, _focusedMonth.day);
      sheet.appendRow([
        ex.TextCellValue(d.name),
        ex.DoubleCellValue(alloc),
        ex.DoubleCellValue(d.spent),
        ex.DoubleCellValue(alloc - d.spent),
        ex.DoubleCellValue(forecast),
      ]);
    }

    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/Forecasting_${_selectedEntity?.name}.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(excel.save()!);
    await Share.shareXFiles([XFile(filePath)], text: 'Export Forecasting Excel');
  }

  void _showEditGlobalForecastDialog() {
    final t = AppLocalizations.of(context);
    final now = DateTime.now();
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final daysElapsed = _focusedMonth.year == now.year && _focusedMonth.month == now.month ? now.day : daysInMonth;
    
    double autoForecast = 0;
    for (var dept in _budget!.departments) {
      autoForecast += dept.getForecast(daysInMonth, daysElapsed);
    }
    
    final controller = TextEditingController(text: (_budget!.customGlobalForecast ?? autoForecast).toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.global_provision),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.override_provision_msg, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(labelText: t.expected_provision_hint, border: const OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            Text("${t.system_calculation} : ${autoForecast.toStringAsFixed(0)} €", style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () {
            setState(() {
              _budget!.customGlobalForecast = null;
              _apiService.updateEntityBudget(_budget!);
            });
            Navigator.pop(ctx);
          }, child: Text(t.auto_btn)),
          ElevatedButton(onPressed: () {
            setState(() {
              _budget!.customGlobalForecast = double.tryParse(controller.text);
              _apiService.updateEntityBudget(_budget!);
            });
            Navigator.pop(ctx);
          }, child: Text(t.save_btn)),
        ],
      ),
    );
  }

  void _showEditForecastDialog(DepartmentBudget? dept) {
    if (dept == null) return;
    final t = AppLocalizations.of(context);
    final now = DateTime.now();
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final daysElapsed = _focusedMonth.year == now.year && _focusedMonth.month == now.month ? now.day : daysInMonth;
    
    double autoForecast = dept.getForecast(daysInMonth, daysElapsed);
    final controller = TextEditingController(text: (dept.customForecast ?? autoForecast).toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("${t.edit_provision} : ${dept.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.adjust_forecast_msg, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(labelText: t.expected_provision_hint, border: const OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            Text("${t.auto_system_calculation} : ${autoForecast.toStringAsFixed(0)} €", style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () {
            setState(() {
              dept.customForecast = null; 
              _apiService.updateEntityBudget(_budget!);
            });
            Navigator.pop(ctx);
          }, child: Text(t.auto_btn)),
          ElevatedButton(onPressed: () {
            setState(() {
              dept.customForecast = double.tryParse(controller.text);
              _apiService.updateEntityBudget(_budget!);
            });
            Navigator.pop(ctx);
          }, child: Text(t.save_btn)),
        ],
      ),
    );
  }

  void _showGlobalBudgetSettings() {
    final t = AppLocalizations.of(context);
    double total = _budget!.totalBudget;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.envelope_control),
        content: TextField(
          decoration: InputDecoration(labelText: t.entity_global_budget, suffixText: "€", border: const OutlineInputBorder()),
          keyboardType: TextInputType.number,
          controller: TextEditingController(text: total.toString()),
          onChanged: (v) => total = double.tryParse(v) ?? total,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel.toUpperCase())),
          ElevatedButton(onPressed: () { setState(() { _budget!.totalBudget = total; _apiService.updateEntityBudget(_budget!); }); Navigator.pop(ctx); }, child: Text(t.validate.toUpperCase())),
        ],
      ),
    );
  }
}
