import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as ex;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_localizations.dart';
import '../../models/employee.dart';
import '../../models/entity.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class RhPage extends StatefulWidget {
  const RhPage({super.key});

  @override
  State<RhPage> createState() => _RhPageState();
}

class _RhPageState extends State<RhPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final Color primaryColor = const Color(0xFF49F6C7);

  List<Employee> _employees = [];
  List<Absence> _absences = [];
  List<Entity> _entities = [];
  List<HRDocument> _hrDocuments = [];
  Map<String, dynamic> _trData = {};
  bool _isLoading = true;

  DateTime _selectedAbsenceDate = DateTime.now();
  DateTime _selectedTrDate = DateTime.now();

  final Map<String, List<String>> _completedTasks = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final employees = await _apiService.fetchEmployees();
    final absences = await _apiService.fetchAbsences();
    final entities = await _apiService.fetchEntities();
    final trData = await _apiService.getTRData();
    final hrDocs = await _apiService.fetchHrDocuments();
    if (mounted) {
      setState(() {
        _employees = employees;
        _absences = absences;
        _entities = entities;
        _trData = trData;
        _hrDocuments = hrDocs;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  InputDecoration _getInputDecoration(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      filled: true,
      fillColor: isDark ? const Color(0xFF2A2B3D) : Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  double _calculateProratedRights(Employee e, double annualFullRights) {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    if (e.startDate.isAfter(DateTime(now.year, 12, 31))) return 0.0;
    DateTime effectiveStart = e.startDate.isBefore(startOfYear) ? startOfYear : e.startDate;
    int monthsWorked = 12 - effectiveStart.month + 1;
    double prorated = (annualFullRights / 12) * monthsWorked;
    return (prorated * 2).round() / 2;
  }

  double _calculateTakenDays(String employeeId, String type) {
    double total = 0;
    for (var a in _absences.where((a) => a.employeeId == employeeId && a.type == type)) {
      total += a.durationDays;
    }
    return total;
  }

  double _calculateAutoTR(Employee e, DateTime date) {
    DateTime monthEnd = DateTime(date.year, date.month + 1, 0);
    if (e.startDate.isAfter(monthEnd)) return 0.0;
    double workedDaysCount = 0;
    int daysInMonth = monthEnd.day;
    for (int i = 1; i <= daysInMonth; i++) {
      DateTime currentDay = DateTime(date.year, date.month, i);
      if (currentDay.isBefore(DateTime(e.startDate.year, e.startDate.month, e.startDate.day))) continue;
      if (currentDay.weekday == DateTime.saturday || currentDay.weekday == DateTime.sunday) continue;
      var dayAbsences = _absences.where((a) => a.employeeId == e.id && !currentDay.isBefore(DateTime(a.startDate.year, a.startDate.month, a.startDate.day)) && !currentDay.isAfter(DateTime(a.endDate.year, a.endDate.month, a.endDate.day)));
      if (dayAbsences.isEmpty) { workedDaysCount += 1.0; }
      else if (dayAbsences.any((a) => a.isHalfDay)) { workedDaysCount += 0.5; }
    }
    return workedDaysCount;
  }

  double _getTRValue(Employee e) {
    String key = "${e.id}_${_selectedTrDate.month}_${_selectedTrDate.year}";
    if (_trData.containsKey(key) && _trData[key]['manualValue'] != null) { return double.tryParse(_trData[key]['manualValue'].toString()) ?? 0.0; }
    return _calculateAutoTR(e, _selectedTrDate);
  }

  bool _isTRValidated(String employeeId) {
    String key = "${employeeId}_${_selectedTrDate.month}_${_selectedTrDate.year}";
    return _trData.containsKey(key) && _trData[key]['validated'] == true;
  }

  Future<void> _exportTRExcel() async {
    final activeEmployees = _employees.where((e) => !e.isResigned && _isTRValidated(e.id)).toList();
    if (activeEmployees.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez cocher au moins un salarié pour l'export."))); return; }
    final excel = ex.Excel.createExcel(); final sheet = excel['Titres-Resto'];
    sheet.appendRow([ex.TextCellValue('Nom'), ex.TextCellValue('Prénom'), ex.TextCellValue('Nombre de Titres'), ex.TextCellValue('Date')]);
    for (var e in activeEmployees) { final value = _getTRValue(e); sheet.appendRow([ex.TextCellValue(e.lastName), ex.TextCellValue(e.firstName), ex.DoubleCellValue(value), ex.TextCellValue("${_selectedTrDate.month}/${_selectedTrDate.year}")]); }
    final dir = await getTemporaryDirectory(); final file = File('${dir.path}/TitresResto_${_selectedTrDate.month}_${_selectedTrDate.year}.xlsx'); await file.writeAsBytes(excel.encode()!); await Share.shareXFiles([XFile(file.path)], text: 'Export Titres-Resto Excel');
  }

  Future<void> _exportTRCsv() async {
    final activeEmployees = _employees.where((e) => !e.isResigned && _isTRValidated(e.id)).toList();
    if (activeEmployees.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez cocher au moins un salarié pour l'export."))); return; }
    String csv = "lastName;firstName;quantity;date\n";
    for (var e in activeEmployees) { final value = _getTRValue(e); csv += "${e.lastName};${e.firstName};$value;${_selectedTrDate.month}/${_selectedTrDate.year}\n"; }
    final dir = await getTemporaryDirectory(); final file = File('${dir.path}/TitresResto_${_selectedTrDate.month}_${_selectedTrDate.year}.csv'); await file.writeAsString(csv); await Share.shareXFiles([XFile(file.path)], text: 'Export Titres-Resto CSV (Swile)');
  }

  void _showEmployeeDetails(Employee e) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final proratedVacation = _calculateProratedRights(e, e.yearlyVacationDays);
    final proratedRtt = _calculateProratedRights(e, e.yearlyRttDays);
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => Container(height: MediaQuery.of(context).size.height * 0.8, decoration: BoxDecoration(color: isDark ? const Color(0xFF121212) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))), padding: const EdgeInsets.all(24), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${e.firstName} ${e.lastName}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), _buildStatusChip(e)]), const SizedBox(height: 8), Text(e.post, style: TextStyle(fontSize: 16, color: Colors.grey[600], fontStyle: FontStyle.italic)), const Divider(height: 32), _buildDetailRow(Icons.business, t.entreprise, _entities.firstWhere((ent) => ent.id == e.entityId, orElse: () => Entity(id: '', name: 'Inconnue', idNumber: '', email: '', address: '', phone: '')).name), _buildDetailRow(Icons.calendar_today, t.hiringDate, DateFormat('dd/MM/yyyy').format(e.startDate)), _buildDetailRow(Icons.assignment_ind, 'Contrat', e.contractType.toString().split('.').last.toUpperCase()), _buildDetailRow(Icons.phone, t.phone, e.phone.isEmpty ? 'Non renseigné' : e.phone), _buildDetailRow(Icons.home, t.address, e.address.isEmpty ? 'Non renseignée' : e.address), _buildDetailRow(Icons.email, 'Email', (e.email == null || e.email!.isEmpty) ? 'Non renseigné' : e.email!), _buildDetailRow(Icons.family_restroom, 'Situation', e.maritalStatus), _buildDetailRow(Icons.contact_phone, 'Urgence', e.emergencyContact.isEmpty ? 'Non renseigné' : e.emergencyContact), const SizedBox(height: 24), Text('${t.totalProrated} (Workday style)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 12), _buildStatLine('Congés Payés', proratedVacation, _calculateTakenDays(e.id, 'Congé')), _buildStatLine('RTT', proratedRtt, _calculateTakenDays(e.id, 'RTT')), const SizedBox(height: 32), SizedBox(width: double.infinity, height: 50, child: OutlinedButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)))]))));
  }

  Widget _buildStatusChip(Employee e) {
    final t = AppLocalizations.of(context);
    final bool isOnboarding = e.startDate.isAfter(DateTime.now());
    Color color = e.isResigned ? Colors.red : (isOnboarding ? Colors.orange : Colors.green);
    String label = e.isResigned ? t.resigned : (isOnboarding ? t.upcoming : t.active);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(20), border: Border.all(color: color)), child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)));
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [Icon(icon, size: 20, color: Colors.grey), const SizedBox(width: 12), Text('$label : ', style: const TextStyle(fontWeight: FontWeight.bold)), Expanded(child: Text(value, style: TextStyle(color: value.contains('Non renseigné') ? Colors.red : (isDark ? Colors.white : Colors.black))))]));
  }

  void _showOnboardingForm() {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstNameC = TextEditingController(); final lastNameC = TextEditingController(); final postC = TextEditingController(); DateTime startD = DateTime.now().add(const Duration(days: 1)); String? selectedEntityId; ContractType contract = ContractType.cdi;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => StatefulBuilder(builder: (context, setM) => Container(height: MediaQuery.of(context).size.height * 0.9, decoration: BoxDecoration(color: isDark ? const Color(0xFF121212) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))), padding: const EdgeInsets.all(24), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))), Text(t.onboarding, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const Divider(height: 32), _buildLabel('${t.selectEntity} *'), DropdownButtonFormField<String>(dropdownColor: isDark ? const Color(0xFF232435) : Colors.white, style: TextStyle(color: isDark ? Colors.white : Colors.black), items: _entities.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(), onChanged: (v) => setM(() => selectedEntityId = v), decoration: _getInputDecoration(t.selectEntity)), const SizedBox(height: 24), _buildField(firstNameC, '${t.firstName} *'), _buildField(lastNameC, '${t.lastName} *'), _buildField(postC, '${t.post} *'), Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel(t.contractType), DropdownButtonFormField<ContractType>(dropdownColor: isDark ? const Color(0xFF232435) : Colors.white, style: TextStyle(color: isDark ? Colors.white : Colors.black), value: contract, items: ContractType.values.map((c) => DropdownMenuItem(value: c, child: Text(c.toString().split('.').last.toUpperCase()))).toList(), onChanged: (v) => setM(() => contract = v!), decoration: _getInputDecoration(t.contractType))])), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel(t.arrivalDate), OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () async { final d = await showDatePicker(context: context, initialDate: startD, firstDate: DateTime.now(), lastDate: DateTime(2100)); if (d != null) setM(() => startD = d); }, child: Text('${startD.day}/${startD.month}/${startD.year}'))]))]), const SizedBox(height: 32), SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: isDark ? primaryColor : Colors.black, foregroundColor: isDark ? Colors.black : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () async { if (firstNameC.text.isEmpty || lastNameC.text.isEmpty || selectedEntityId == null) return; final emp = Employee(id: DateTime.now().millisecondsSinceEpoch.toString(), firstName: firstNameC.text.trim(), lastName: lastNameC.text.trim(), post: postC.text.trim(), status: EmployeeStatus.salarie, contractType: contract, startDate: startD, address: '', phone: '', maritalStatus: 'Célibataire', emergencyContact: '', entityId: selectedEntityId); await _apiService.createEmployee(emp); _loadData(); if (context.mounted) Navigator.pop(context); }, child: Text(t.launchOnboarding, style: const TextStyle(fontWeight: FontWeight.bold))))])))));
  }

  void _showAddEmployeeForm({Employee? employeeToEdit}) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstNameC = TextEditingController(text: employeeToEdit?.firstName); final lastNameC = TextEditingController(text: employeeToEdit?.lastName); final emailC = TextEditingController(text: employeeToEdit?.email); final postC = TextEditingController(text: employeeToEdit?.post); final vacationC = TextEditingController(text: employeeToEdit?.yearlyVacationDays.toString() ?? '25'); final rttC = TextEditingController(text: employeeToEdit?.yearlyRttDays.toString() ?? '5'); final addressC = TextEditingController(text: employeeToEdit?.address); final phoneC = TextEditingController(text: employeeToEdit?.phone); final emergencyC = TextEditingController(text: employeeToEdit?.emergencyContact); EmployeeStatus status = employeeToEdit?.status ?? EmployeeStatus.salarie; ContractType contract = employeeToEdit?.contractType ?? ContractType.cdi; String maritalStatus = employeeToEdit?.maritalStatus ?? 'Célibataire'; String? selectedEntityId = employeeToEdit?.entityId; DateTime startD = employeeToEdit?.startDate ?? DateTime.now(); DateTime? endD = employeeToEdit?.endDate;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => StatefulBuilder(builder: (context, setM) => Container(height: MediaQuery.of(context).size.height * 0.95, decoration: BoxDecoration(color: isDark ? const Color(0xFF121212) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))), padding: const EdgeInsets.all(24), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))), Text(employeeToEdit == null ? t.newEmployee : t.edit, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const Divider(height: 32), _buildLabel('${t.selectEntity} *'), DropdownButtonFormField<String>(dropdownColor: isDark ? const Color(0xFF232435) : Colors.white, style: TextStyle(color: isDark ? Colors.white : Colors.black), value: selectedEntityId, items: _entities.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(), onChanged: (v) => setM(() => selectedEntityId = v), decoration: _getInputDecoration(t.selectEntity)), const SizedBox(height: 24), _buildField(firstNameC, '${t.firstName} *'), _buildField(lastNameC, '${t.lastName} *'), _buildField(emailC, '${t.email} *'), _buildField(postC, '${t.post} *'), Row(children: [Expanded(child: _buildField(vacationC, t.vacationRights, keyboardType: TextInputType.number)), const SizedBox(width: 12), Expanded(child: _buildField(rttC, t.rttRights, keyboardType: TextInputType.number))]), Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel(t.status), DropdownButtonFormField<EmployeeStatus>(dropdownColor: isDark ? const Color(0xFF232435) : Colors.white, style: TextStyle(color: isDark ? Colors.white : Colors.black), value: status, items: EmployeeStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.toString().split('.').last.toUpperCase()))).toList(), onChanged: (v) => setM(() => status = v!), decoration: _getInputDecoration(t.status))])), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel(t.contractType), DropdownButtonFormField<ContractType>(dropdownColor: isDark ? const Color(0xFF232435) : Colors.white, style: TextStyle(color: isDark ? Colors.white : Colors.black), value: contract, items: ContractType.values.map((c) => DropdownMenuItem(value: c, child: Text(c.toString().split('.').last.toUpperCase()))).toList(), onChanged: (v) => setM(() => contract = v!), decoration: _getInputDecoration(t.contractType))]))]), const SizedBox(height: 24), Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel(t.hiringDate), OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () async { final d = await showDatePicker(context: context, initialDate: startD, firstDate: DateTime(2000), lastDate: DateTime(2100)); if (d != null) setM(() => startD = d); }, child: Text('${startD.day}/${startD.month}/${startD.year}'))])), if (contract != ContractType.cdi) ...[const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel(t.endDate + ' *'), OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () async { final d = await showDatePicker(context: context, initialDate: endD ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (d != null) setM(() => endD = d); }, child: Text(endD == null ? 'Choisir' : '${endD!.day}/${endD!.month}/${endD!.year}'))]))]]), const SizedBox(height: 24), _buildField(addressC, t.address), _buildField(phoneC, t.phone, keyboardType: TextInputType.phone), _buildField(emergencyC, t.emergencyContact), const SizedBox(height: 32), SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () async { if (firstNameC.text.isEmpty || lastNameC.text.isEmpty || selectedEntityId == null) return; final emp = Employee(id: employeeToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(), firstName: firstNameC.text.trim(), lastName: lastNameC.text.trim(), email: emailC.text.trim(), post: postC.text.trim(), status: status, contractType: contract, startDate: startD, endDate: endD, address: addressC.text.trim(), phone: phoneC.text.trim(), maritalStatus: maritalStatus, childrenCount: 0, emergencyContact: emergencyC.text.trim(), isResigned: employeeToEdit?.isResigned ?? false, yearlyVacationDays: double.tryParse(vacationC.text) ?? 25.0, yearlyRttDays: double.tryParse(rttC.text) ?? 5.0, entityId: selectedEntityId); if (employeeToEdit == null) { await _apiService.createEmployee(emp); } else { await _apiService.updateEmployee(emp.id, emp.toJson()); } _loadData(); if (context.mounted) Navigator.pop(context); }, child: Text(t.save, style: const TextStyle(fontWeight: FontWeight.bold))))])))));
  }

  void _showAddAbsenceForm() {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Employee? selectedEmp; String type = 'Congé'; DateTime start = DateTime.now(); DateTime end = DateTime.now(); bool isHalfDay = false; final commentC = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => StatefulBuilder(builder: (context, setM) { double solde = 0; if (selectedEmp != null) { double totalDroits = type == 'Congé' ? _calculateProratedRights(selectedEmp!, selectedEmp!.yearlyVacationDays) : (type == 'RTT' ? _calculateProratedRights(selectedEmp!, selectedEmp!.yearlyRttDays) : 0); double dejaPris = _calculateTakenDays(selectedEmp!.id, type); double dureeSelection = isHalfDay ? 0.5 : 0; if (!isHalfDay) { for (int i = 0; i <= end.difference(start).inDays; i++) { DateTime d = start.add(Duration(days: i)); if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) dureeSelection++; } } solde = totalDroits - dejaPris - dureeSelection; } return Container(height: MediaQuery.of(context).size.height * 0.85, decoration: BoxDecoration(color: isDark ? const Color(0xFF121212) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))), padding: const EdgeInsets.all(24), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))), Text(t.newAbsence, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const Divider(height: 32), _buildLabel('Salarié *'), DropdownButtonFormField<Employee>(dropdownColor: isDark ? const Color(0xFF232435) : Colors.white, style: TextStyle(color: isDark ? Colors.white : Colors.black), items: _employees.where((e) => !e.isResigned).map((e) => DropdownMenuItem(value: e, child: Text('${e.firstName} ${e.lastName}'))).toList(), onChanged: (v) => setM(() => selectedEmp = v), decoration: _getInputDecoration('Salarié')), const SizedBox(height: 24), _buildLabel(t.absenceMotif), DropdownButtonFormField<String>(dropdownColor: isDark ? const Color(0xFF232435) : Colors.white, style: TextStyle(color: isDark ? Colors.white : Colors.black), value: type, items: ['Congé', 'RTT', 'Arrêt Maladie', 'Accident Travail', 'Absence non justifiée'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setM(() => type = v!), decoration: _getInputDecoration('Motif')), SwitchListTile(title: Text(t.halfDay), value: isHalfDay, onChanged: (v) => setM(() => isHalfDay = v), activeThumbColor: primaryColor), const SizedBox(height: 12), Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel(isHalfDay ? 'Le' : 'Du'), OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () async { final d = await showDatePicker(context: context, initialDate: start, firstDate: DateTime(2020), lastDate: DateTime(2100)); if (d != null) setM(() { start = d; if (isHalfDay) end = d; }); }, child: Text('${start.day}/${start.month}/${start.year}'))])), if (!isHalfDay) ...[const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('Au (inclus)'), OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () async { final d = await showDatePicker(context: context, initialDate: end, firstDate: DateTime(2020), lastDate: DateTime(2100)); if (d != null) setM(() => end = d); }, child: Text('${end.day}/${end.month}/${end.year}'))]))]]), if (selectedEmp != null && (type == 'Congé' || type == 'RTT')) ...[const SizedBox(height: 24), Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: solde < 0 ? Colors.red.withAlpha(25) : primaryColor.withAlpha(25), borderRadius: BorderRadius.circular(12), border: Border.all(color: solde < 0 ? Colors.red : primaryColor)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Solde après saisie :'), Text('${solde.toStringAsFixed(1)} j', style: const TextStyle(fontWeight: FontWeight.bold))]))], const SizedBox(height: 24), _buildField(commentC, 'Commentaire'), const SizedBox(height: 32), SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: isDark ? primaryColor : Colors.black, foregroundColor: isDark ? Colors.black : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () async { if (selectedEmp == null) return; await _apiService.createAbsence(Absence(id: DateTime.now().millisecondsSinceEpoch.toString(), employeeId: selectedEmp!.id, startDate: start, endDate: end, type: type, comment: commentC.text, isHalfDay: isHalfDay)); _loadData(); if (context.mounted) Navigator.pop(context); }, child: Text(t.saveAbsence, style: const TextStyle(fontWeight: FontWeight.bold))))]))); }));
  }

  void _showEditTRDialog(Employee e, double currentValue) {
    final t = AppLocalizations.of(context);
    final controller = TextEditingController(text: currentValue.toString()); showDialog(context: context, builder: (ctx) => AlertDialog(title: Text('${t.correctionFor}${e.firstName}'), content: TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Nombre de tickets final')), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)), ElevatedButton(onPressed: () async { String key = "${e.id}_${_selectedTrDate.month}_${_selectedTrDate.year}"; Map<String, dynamic> current = _trData[key] ?? {}; current['manualValue'] = double.tryParse(controller.text) ?? currentValue; await _apiService.saveTRData(key, current); if (context.mounted) Navigator.pop(ctx); _loadData(); }, child: Text(t.save))]));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context); final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = isDark ? const Color(0xFF121212) : Colors.white;
    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(backgroundColor: scaffoldColor, elevation: 0, leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: isDark ? primaryColor : const Color(0xFF232435)), onPressed: () => Navigator.pop(context)), title: Text(t.rh, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)), bottom: TabBar(controller: _tabController, isScrollable: true, labelColor: isDark ? primaryColor : Colors.black, unselectedLabelColor: Colors.grey, indicatorColor: primaryColor, tabs: [Tab(text: t.employees), Tab(text: t.absences), Tab(text: t.documents), Tab(text: t.trResto)])),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : TabBarView(controller: _tabController, children: [_buildEmployeeList(), _buildAbsenceList(), _buildDocsView(), _buildTRView()]),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildEmployeeList() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (_employees.where((e) => !e.startDate.isAfter(DateTime.now())).isNotEmpty)
        ..._employees.where((e) => !e.startDate.isAfter(DateTime.now())).map((e) => _buildEmployeeCard(e)),
      if (_employees.where((e) => e.startDate.isAfter(DateTime.now())).isNotEmpty) ...[
        const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Row(children: [Expanded(child: Divider(color: Colors.grey, thickness: 0.5)), Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('BIENTÔT ARRIVÉS (ONBOARDING)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2))), Expanded(child: Divider(color: Colors.grey, thickness: 0.5))])),
        ..._employees.where((e) => e.startDate.isAfter(DateTime.now())).map((e) => _buildEmployeeCard(e, isOnboarding: true))
      ],
      const SizedBox(height: 100)
    ]);
  }

  Widget _buildEmployeeCard(Employee e, {bool isOnboarding = false}) {
    final t = AppLocalizations.of(context);
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    // Calculs des soldes
    double congTaken = _calculateTakenDays(e.id, 'Congé');
    double rttTaken = _calculateTakenDays(e.id, 'RTT');
    double proratedCongRights = _calculateProratedRights(
        e, e.yearlyVacationDays);
    double proratedRttRights = _calculateProratedRights(e, e.yearlyRttDays);
    final bool isInfoIncomplete = e.address.isEmpty || e.phone.isEmpty ||
        e.emergencyContact.isEmpty;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: isDark ? const Color(0xFF232435) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: e.isResigned
                ? Colors.red.withAlpha(50)
                : (isDark ? Colors.white10 : Colors.black12)
        ),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: e.isResigned
              ? Colors.grey[200]
              : (isOnboarding ? Colors.orange[50] : primaryColor.withAlpha(50)),
          child: Icon(
              Icons.person,
              color: e.isResigned ? Colors.grey : (isDark
                  ? primaryColor
                  : Colors.black)
          ),
        ),
        title: Text(
          '${e.firstName} ${e.lastName}',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              decoration: e.isResigned ? TextDecoration.lineThrough : null,
              color: isDark ? Colors.white : Colors.black
          ),
        ),
        subtitle: Text(
          e.post,
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'view') _showEmployeeDetails(e);
            if (v == 'edit') _showAddEmployeeForm(employeeToEdit: e);
            if (v == 'toggle_resign') {
              await _apiService.updateEmployee(
                  e.id, {'isResigned': !e.isResigned});
              _loadData();
            }
          },
          itemBuilder: (ctx) =>
          [
            PopupMenuItem(value: 'view', child: Text(t.viewFile)),
            PopupMenuItem(value: 'edit', child: Text(t.edit)),
            PopupMenuItem(value: 'toggle_resign',
                child: Text(e.isResigned ? t.reanimate : t.resign)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isOnboarding) ...[
                  Text(
                    t.preparationOnboarding,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.orange
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Checklist Onboarding
                  ...List.generate(7, (index) {
                    final taskNumber = index + 1;
                    // Utilisation d'une String simple car onboardingTask n'est pas une fonction
                    final String taskLabel = "${t.onboarding} #$taskNumber";
                    final bool isDone = _completedTasks[e.id]?.contains(
                        taskLabel) ?? false;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: isDone,
                              activeColor: Colors.orange,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _completedTasks
                                        .putIfAbsent(e.id, () => [])
                                        .add(taskLabel);
                                  } else {
                                    _completedTasks[e.id]?.remove(taskLabel);
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              taskLabel,
                              style: TextStyle(
                                fontSize: 13,
                                decoration: isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isDone ? Colors.grey : (isDark ? Colors
                                    .white70 : Colors.black87),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 32),
                ],

                // Statistiques des congés
                _buildStatLine(t.paidLeave, proratedCongRights, congTaken),
                const SizedBox(height: 8),
                _buildStatLine('RTT', proratedRttRights, rttTaken),

                if (isInfoIncomplete) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                          Icons.warning_amber_rounded, color: Colors.orange,
                          size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.contactIncomplete,
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildStatLine(String label, double? rights, double taken) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark; String value = taken.toStringAsFixed(1); if (rights != null) value = "$taken ${t.taken} / ${rights - taken} ${t.remaining} (${t.totalProrated}: $rights)";
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)), Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white : Colors.black))]);
  }

  Widget _buildMonthNavigator(DateTime current, Function(DateTime) onUpdate) {
    final locale = Localizations.localeOf(context).toString();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF232435), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: Icon(Icons.chevron_left, color: primaryColor), onPressed: () => onUpdate(DateTime(current.year, current.month - 1))),
          Text("${DateFormat('MMMM', locale).format(current).toUpperCase()} - ${current.year}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          IconButton(icon: Icon(Icons.chevron_right, color: primaryColor), onPressed: () => onUpdate(DateTime(current.year, current.month + 1))),
        ],
      ),
    );
  }

  Widget _buildAbsenceList() {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredAbsences = _absences.where((a) => a.startDate.month == _selectedAbsenceDate.month && a.startDate.year == _selectedAbsenceDate.year).toList();
    return Column(children: [
      _buildMonthNavigator(_selectedAbsenceDate, (d) => setState(() => _selectedAbsenceDate = d)),
      Expanded(child: filteredAbsences.isEmpty ? Center(child: Text(t.absencesMsg)) : ListView.builder(padding: const EdgeInsets.all(16), itemCount: filteredAbsences.length, itemBuilder: (context, index) { final a = filteredAbsences[index]; final emp = _employees.firstWhere((e) => e.id == a.employeeId, orElse: () => Employee(id: '', firstName: 'Inconnu', lastName: '', post: '', status: EmployeeStatus.salarie, contractType: ContractType.cdi, startDate: DateTime.now(), address: '', phone: '', maritalStatus: '', emergencyContact: '')); return Card(margin: const EdgeInsets.only(bottom: 12), color: isDark ? const Color(0xFF232435) : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? Colors.white10 : Colors.black12)), child: ListTile(title: Text('${emp.firstName} ${emp.lastName}', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)), subtitle: Text('${a.type} - ${a.isHalfDay ? t.halfDay : "${a.durationDays}j"}', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)), trailing: IconButton(icon: Icon(Icons.delete_outline, color: isDark ? Colors.redAccent : Colors.black), onPressed: () async { await _apiService.deleteAbsence(a.id); _loadData(); }))); }))
    ]);
  }

  void _showAddHrDocForm() {
    final t = AppLocalizations.of(context);
    final titleC = TextEditingController(); String? selectedEmpId; String type = 'Contrat'; String? pickedFileName; String? pickedFilePath;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => StatefulBuilder(builder: (context, setM) { bool isFormValid = titleC.text.trim().isNotEmpty && selectedEmpId != null && pickedFilePath != null; final isDark = Theme.of(context).brightness == Brightness.dark; return Container(padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom), decoration: BoxDecoration(color: isDark ? const Color(0xFF121212) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t.hrNewDoc, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 24), _buildLabel('Salarié concerné *'), DropdownButtonFormField<String>(dropdownColor: isDark ? const Color(0xFF232435) : Colors.white, style: TextStyle(color: isDark ? Colors.white : Colors.black), value: selectedEmpId, items: _employees.map((e) => DropdownMenuItem(value: e.id, child: Text('${e.firstName} ${e.lastName}'))).toList(), onChanged: (v) => setM(() => selectedEmpId = v), decoration: _getInputDecoration('Salarié')), const SizedBox(height: 24), _buildLabel('Titre du document *'), TextField(controller: titleC, style: TextStyle(color: isDark ? Colors.white : Colors.black), onChanged: (_) => setM(() {}), decoration: _getInputDecoration('Ex: Contrat de travail')), const SizedBox(height: 24), _buildDropdownField(t.docType, type, ['Contrat', 'Bulletin de paie', 'Attestation', 'Autre'], true, (v) => setM(() => type = v!)), const SizedBox(height: 24), _buildLabel(t.fileSource), InkWell(onTap: () async { try { FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx']); if (result != null && result.files.single.path != null) { setM(() { pickedFileName = result.files.single.name; pickedFilePath = result.files.single.path; if (titleC.text.isEmpty) { titleC.text = pickedFileName!.split('.').first; } }); } } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur sélecteur : $e'))); } }, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: pickedFilePath != null ? Colors.green : Colors.grey.shade300), borderRadius: BorderRadius.circular(12), color: isDark ? const Color(0xFF232435) : Colors.grey.shade50), child: Row(children: [Icon(Icons.cloud_upload_outlined, color: pickedFilePath != null ? Colors.green : primaryColor), const SizedBox(width: 12), Expanded(child: Text(pickedFileName ?? t.pickFile, style: TextStyle(color: pickedFileName == null ? Colors.grey : (isDark ? Colors.white : Colors.black))))]))), const SizedBox(height: 32), SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: isFormValid ? primaryColor : Colors.grey[300], foregroundColor: isFormValid ? Colors.black : Colors.grey[600], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () async { if (!isFormValid) return; final newDoc = HRDocument(id: DateTime.now().millisecondsSinceEpoch.toString(), employeeId: selectedEmpId!, title: titleC.text.trim(), date: DateTime.now(), type: type, fileName: pickedFileName, filePath: pickedFilePath); await _apiService.addHrDocument(newDoc); _loadData(); if (context.mounted) Navigator.pop(context); }, child: Text(t.save, style: const TextStyle(fontWeight: FontWeight.bold)))), const SizedBox(height: 16)]))); }));
  }

  Widget _buildDocsView() {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark; if (_employees.isEmpty) return Center(child: Text(t.noEmployees));
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: _employees.length, itemBuilder: (context, index) { final e = _employees[index]; final docs = _hrDocuments.where((d) => d.employeeId == e.id).toList(); return ExpansionTile(leading: const Icon(Icons.folder_shared_outlined), title: Text('${e.firstName} ${e.lastName}', style: TextStyle(color: isDark ? Colors.white : Colors.black)), children: [...docs.map((d) => ListTile(leading: Icon(_getDocIcon(d.fileName), size: 18), title: Text(d.title, style: TextStyle(color: isDark ? Colors.white : Colors.black)), subtitle: Text('${d.type} • ${DateFormat('dd/MM/yyyy').format(d.date)}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.visibility_outlined, size: 20), onPressed: () => _viewDoc(d)), IconButton(icon: Icon(Icons.delete_outline, size: 20, color: isDark ? Colors.white : Colors.black), onPressed: () async { await _apiService.deleteHrDocument(d.id); _loadData(); })]))), Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: TextButton.icon(onPressed: _showAddHrDocForm, icon: const Icon(Icons.add), label: Text(t.addDocument)))]); });
  }

  IconData _getDocIcon(String? fileName) { if (fileName == null) return Icons.description_outlined; if (fileName.toLowerCase().endsWith('.pdf')) return Icons.picture_as_pdf_outlined; if (fileName.toLowerCase().contains('doc')) return Icons.description_outlined; if (fileName.toLowerCase().contains('xls')) return Icons.table_chart_outlined; return Icons.insert_drive_file_outlined; }
  void _viewDoc(HRDocument d) { showDialog(context: context, builder: (context) => AlertDialog(title: Text(d.title), content: Column(mainAxisSize: MainAxisSize.min, children: [Icon(_getDocIcon(d.fileName), size: 64, color: Colors.blue), const SizedBox(height: 16), Text('Nom : ${d.fileName ?? "N/A"}'), Text('Type : ${d.type}')]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))])); }

  Widget _buildTRView() {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark; final activeEmployees = _employees.where((e) => !e.isResigned).toList();
    return Column(children: [
      _buildMonthNavigator(_selectedTrDate, (d) => setState(() => _selectedTrDate = d)),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton.icon(onPressed: _exportTRCsv, icon: const Icon(Icons.file_download_outlined, size: 18), label: const Text('CSV')), const SizedBox(width: 8), TextButton.icon(onPressed: _exportTRExcel, icon: const Icon(Icons.table_view_outlined, size: 18), label: const Text('EXCEL'))])),
      Expanded(child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: activeEmployees.length, itemBuilder: (context, index) { final e = activeEmployees[index]; final value = _getTRValue(e); final isValidated = _isTRValidated(e.id); return Card(elevation: 0, color: isDark ? const Color(0xFF232435) : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isValidated ? Colors.green.withAlpha(75) : (isDark ? Colors.white10 : Colors.black12))), child: ListTile(title: Text('${e.firstName} ${e.lastName}', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)), subtitle: Text('$value${t.trCalculated}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: Icon(Icons.edit_note, color: isValidated ? Colors.grey : Colors.blue), onPressed: isValidated ? null : () => _showEditTRDialog(e, value)), IconButton(icon: Icon(isValidated ? Icons.check_circle : Icons.check_circle_outline, color: isValidated ? Colors.green : Colors.grey), onPressed: () async { String key = "${e.id}_${_selectedTrDate.month}_${_selectedTrDate.year}"; Map<String, dynamic> current = _trData[key] ?? {}; current['validated'] = !isValidated; await _apiService.saveTRData(key, current); _loadData(); })]))); }))
    ]);
  }

  Widget? _buildFab() {
    final t = AppLocalizations.of(context);
    if (_tabController.index == 0) { return Column(mainAxisSize: MainAxisSize.min, children: [FloatingActionButton.extended(heroTag: 'onboarding', onPressed: _showOnboardingForm, label: Text(t.onboarding), icon: const Icon(Icons.rocket_launch), backgroundColor: Colors.black), const SizedBox(height: 12), FloatingActionButton.extended(heroTag: 'new_emp', onPressed: () => _showAddEmployeeForm(), label: Text(t.newEmployee), icon: const Icon(Icons.person_add), backgroundColor: primaryColor)]); }
    if (_tabController.index == 1) return FloatingActionButton.extended(onPressed: _showAddAbsenceForm, label: Text(t.newAbsence), icon: const Icon(Icons.add), backgroundColor: primaryColor);
    return null;
  }

  Widget _buildField(TextEditingController c, String l, {TextInputType keyboardType = TextInputType.text}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: TextField(
        controller: c,
        keyboardType: keyboardType,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: _getInputDecoration(l)
      )
    );
  }
  Widget _buildLabel(String l) { return Padding(padding: const EdgeInsets.only(top: 8, bottom: 8), child: Text(l, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))); }
  Widget _buildDropdownField(String label, String value, List<String> items, bool enabled, Function(String?) onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButtonFormField<String>(
      dropdownColor: isDark ? const Color(0xFF232435) : Colors.white,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: enabled ? onChanged : null,
      decoration: _getInputDecoration(label)
    );
  }
}
