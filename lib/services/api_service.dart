import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/task.dart';
import '../models/invoice.dart';
import '../models/entity.dart';
import '../models/employee.dart';
import '../models/supplier.dart';
import '../models/journal_entry.dart';
import '../models/history_entry.dart';
import '../models/account_fr.dart';
import '../models/bank_account.dart';
import '../models/bank_transaction.dart';
import '../models/reconciliation_record.dart';
import '../models/budget_models.dart';
import '../models/cost_center.dart';
import '../models/account_us.dart';
import '../models/account_uk.dart';
import '../models/account_de.dart';
import '../models/payment.dart';
import '../ai/accounting_ai.dart';
import '../services/local_ocr_service.dart';


class ApiService {
  // --- SINGLETON PATTERN ---
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    final String key = dotenv.env['GEMINI_API_KEY'] ?? '';
    aiProvider = AccountingAI(apiKey: key);
    _initFuture = _loadFromStorage();
  }

  late Future<void> _initFuture;
  static const String baseUrl = 'http://10.0.2.2:3001';
  static const String aiUrl = 'http://10.0.2.2:3001';

  late final AccountingAI aiProvider;
  String? _token;
  bool _isLoaded = false;

  // --- CACHES ---
  final List<Invoice> _invoicesCache = [];
  final List<Task> _tasksCache = [];
  final List<Employee> _employeesCache = [];
  final List<Supplier> _suppliersCache = [];
  final List<Supplier> _customersCache = [];
  final List<Entity> _entitiesCache = [];
  final List<InvoicingConfig> _invoicingConfigsCache = [];
  final List<JournalEntry> _journalCache = [];
  final List<Map<String, dynamic>> _quotesCache = [];
  final List<String> _notifications = [];
  final List<dynamic> _eventsCache = [];
  final List<HistoryEntry> _historyCache = [];
  final List<Absence> _absencesCache = [];
  final List<HRDocument> _hrDocsCache = [];
  final List<CostCenter> _costCentersCache = [];
  final List<BankTransaction> _bankTransactionsCache = [];
  final List<ReconciliationRecord> _reconciliationsCache = [];
  final List<EntityBudget> _budgetsCache = [];
  final List<BankAccount> _bankAccountsCache = [];
  final Map<String, List<double>> _customTaxes = {};
  final List<Account> _customAccountsCache = [];
  final Map<String, dynamic> _trDataCache = {};
  final List<Map<String, dynamic>> _companyDocsCache = [];

  bool _isLoadedFromStorage = false;
  String _activeAccountingPlan = 'France (PCG)';
  String? _adminPin;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${_token ?? ""}',
  };

  Future<void> _ensureLoaded() async {
    await _initFuture;
    if (!_isLoaded) {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('jwt_token');
      if (_token != null) _isLoaded = true;
    }
  }

  // --- AUTHENTIFICATION ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _token = data['access_token'] ?? data['token'];
        if (_token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', _token!);
          _isLoaded = true;
          return {'success': true};
        }
      }
      return {'success': false, 'message': 'Email ou mot de passe incorrect'};
    } catch (e) { return {'success': false, 'message': 'Erreur : $e'}; }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/api/auth/register'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(data));
      return {'success': response.statusCode == 200 || response.statusCode == 201};
    } catch (e) { return {'success': false, 'message': e.toString()}; }
  }

  // --- IA ---
  Future<String> askAI(String question, String context) async {
    await _ensureLoaded();
    try {
      final response = await http.post(Uri.parse('$aiUrl/api/ai/ask'), headers: _headers, body: jsonEncode({
        'question': question,
        'context': context,
        'entityId': 1
      })
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body)['answer'] ?? "Pas de réponse.";
      }
    } catch (e) { debugPrint("Fallback IA local."); }

    return await aiProvider.chatWithContext(
      userMessage: question,
      invoices: _invoicesCache,
      budgets: _budgetsCache,
      entities: _entitiesCache,
      employees: _employeesCache,
      currentPlan: _activeAccountingPlan,
    );
  }

  Future<Map<String, dynamic>> scanInvoiceWithAI(String path) async {
    try {
      // 1. OCR LOCAL
      final localResult = await LocalOCRService().processImage(path);

      // 2. Si résultat vide ou douteux → IA
      if (localResult['amountTTC'] == 0 || localResult['supplierName'] == null) {
        final aiResult = await aiProvider.extractInvoiceDataFromPath(path);
        return aiResult;
      }

      return localResult;
    } catch (e) {
      // fallback IA
      return await aiProvider.extractInvoiceDataFromPath(path);
    }
  }


  // --- FACTURES ---
  Future<List<Invoice>> fetchInvoices(InvoiceType type) async {
    await _ensureLoaded();
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/invoices?type=${type.toString().split('.').last}'), headers: _headers);
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        final fetched = data.map((i) => Invoice.fromJson(i)).toList();
        for (var inv in fetched) {
          int idx = _invoicesCache.indexWhere((i) => i.id == inv.id);
          if (idx != -1) { _invoicesCache[idx] = inv; } else { _invoicesCache.add(inv); }
        }
        await _saveToStorage();
      }
    } catch (e) {}
    return _invoicesCache.where((i) => i.type == type).toList();
  }

  Future<void> createInvoice(Invoice inv) async {
    await _ensureLoaded();
    _invoicesCache.removeWhere((i) => i.id == inv.id);
    _invoicesCache.add(inv);
    await _saveToStorage();
    try { await http.post(Uri.parse('$baseUrl/api/invoices'), headers: _headers, body: jsonEncode(inv.toJson())); } catch (e) {}
  }

  Future<void> updateInvoice(String id, Map<String, dynamic> data) async {
    await _ensureLoaded();
    int idx = _invoicesCache.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _invoicesCache[idx] = Invoice.fromJson({..._invoicesCache[idx].toJson(), ...data});
      await _saveToStorage();
    }
    try { await http.patch(Uri.parse('$baseUrl/api/invoices/$id'), headers: _headers, body: jsonEncode(data)); } catch (e) {}
  }

  Future<void> deleteInvoice(String id) async {
    await _ensureLoaded();
    _invoicesCache.removeWhere((i) => i.id == id);
    await _saveToStorage();
    try { await http.delete(Uri.parse('$baseUrl/api/invoices/$id'), headers: _headers); } catch (e) {}
  }


  Future sendInvoice(String invoiceId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/invoices/$invoiceId/send'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception("Erreur envoi facture");
    }

    return jsonDecode(response.body);
  }

  List<Account> getAccountsForEntity(Entity entity, List<Account> allAccounts) {
    // On filtre tous les comptes chargés en mémoire pour ne garder
    // que ceux qui correspondent au plan de l'entité (ex: 'UK')
    return allAccounts
        .where((acc) => acc.plan == entity.accountingPlan)
        .toList();
  }


  // --- COMPTABILITÉ & COMPTES ---
  Future<List<Account>> fetchAccounts({String? plan}) async {
    await _ensureLoaded();
    String targetPlan = plan ?? _activeAccountingPlan;
    List<Account> base;
    switch (targetPlan) {
      case 'USA (GAAP)': base = USAccounts.defaultAccounts; break;
      case 'UK (COA)': base = UKAccounts.defaultAccounts; break;
      case 'Germany (DATEV)': base = DEAccounts.defaultAccounts; break;
      default: base = Account.defaultAccounts;
    }
    return [...base, ..._customAccountsCache];
  }


  Future connectPDP({
    required String provider,
    required String apiKey,
    required String apiSecret,
    required String country,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/invoicing/pdp/connect'),
      headers: _headers,
      body: jsonEncode({
        "provider": provider,
        "apiKey": apiKey,
        "apiSecret": apiSecret,
        "country": country,
        "userId": 1
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print("Erreur: ${response.body}");
      throw Exception("Erreur connexion PDP : ${response.statusCode}");
    }
  }


  // --- ENVOI DE FACTURE VIA PDP ---
  Future<Map<String, dynamic>> sendInvoiceToPDP({
    required String provider,
    required String apiKey,
    required String apiSecret,
    required String country,
    required Map<String, dynamic> config,
    required Map<String, dynamic> invoiceData,
  }) async {
    await _ensureLoaded();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/invoicing/send'),
        headers: _headers,
        body: jsonEncode({
          "config": config,
          "invoiceData": invoiceData,
          "provider": provider,
          "apiKey": apiKey,
          "apiSecret": apiSecret,
          "country": country,
          "userId": 1,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': "Erreur serveur: ${response.statusCode}"
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }


  Future<Map<String, dynamic>> getPDPInvoiceStatus(String country, String pdpId) async {
    await _ensureLoaded();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/invoicing/status/$country/$pdpId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'status': 'UNKNOWN'};
    } catch (e) {
      return {'status': 'ERROR', 'message': e.toString()};
    }
  }

  // --- NOTIFICATIONS ---
  Future<List<dynamic>> fetchNotifications() async {
    await _ensureLoaded();
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/notifications'), headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _notifications.clear();
        _notifications.addAll(data as Iterable<String>);
        await _saveToStorage();
      }
    } catch (e) {
      debugPrint("Erreur notifications: $e");
    }
    return _notifications;
  }

  // --- RECHERCHE GLOBALE ---
  Future<Map<String, List<dynamic>>> searchAll(String query) async {
    await _ensureLoaded();
    final q = query.toLowerCase();
    return {
      // Note: On utilise 'supplier' car 'vendor' n'existe pas dans ton modèle Invoice
      'invoices': _invoicesCache.where((i) => (i.supplier ?? "").toLowerCase().contains(q)).toList(),
      'employees': _employeesCache.where((e) => (e.firstName ?? "").toLowerCase().contains(q)).toList(),
    };
  }


  // Vérification de statut (Une seule version suffit)
  Future<Map<String, dynamic>> checkInvoiceStatus(String country, String pdpId) async {
    await _ensureLoaded();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/invoicing/status/$country/$pdpId'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'UNKNOWN', 'error': e.toString()};
    }
  }


  Future<void> createAccount(Account a) async { await _ensureLoaded(); _customAccountsCache.add(a); await _saveToStorage(); }
  Future<void> deleteAccount(String id) async { await _ensureLoaded(); _customAccountsCache.removeWhere((a) => a.id == id); await _saveToStorage(); }
  Future<String> getActiveAccountingPlan() async { await _ensureLoaded(); return _activeAccountingPlan; }
  Future<void> setActiveAccountingPlan(String plan) async { _activeAccountingPlan = plan; await _saveToStorage(); }

  Future<List<JournalEntry>> fetchJournalEntries() async { await _ensureLoaded(); return List.from(_journalCache); }
  Future<void> createJournalEntry(JournalEntry e) async { await _ensureLoaded(); _journalCache.add(e); await _saveToStorage(); }
  Future<void> updateJournalEntry(String id, JournalEntry e) async {
    await _ensureLoaded();
    int idx = _journalCache.indexWhere((je) => je.id == id);
    if (idx != -1) { _journalCache[idx] = e; await _saveToStorage(); }
  }
  Future<void> deleteJournalEntry(String id) async { await _ensureLoaded(); _journalCache.removeWhere((je) => je.id == id); await _saveToStorage(); }

  // --- TAXES ---
  List<double> getTaxesForCountry(String country) => _customTaxes[country] ?? _getDefaultTaxesForCountry(country);
  
  List<double> _getDefaultTaxesForCountry(String country) {
    switch (country.toLowerCase()) {
      case 'france': return [0.0, 2.1, 5.5, 10.0, 20.0];
      case 'uk': return [0.0, 5.0, 20.0];
      case 'germany':
      case 'allemagne': return [0.0, 7.0, 19.0];
      case 'usa': return [0.0, 4.0, 6.0, 8.0, 10.0]; // Approximate Sales Tax
      default: return [0.0, 20.0];
    }
  }

  Future<void> addTaxRate(String country, double rate) async {
    await _ensureLoaded();
    _customTaxes[country] ??= _getDefaultTaxesForCountry(country);
    if (!_customTaxes[country]!.contains(rate)) {
      _customTaxes[country]!.add(rate);
      await _saveToStorage();
    }
  }

  Future<void> deleteTaxRate(String country, double rate) async {
    await _ensureLoaded();
    _customTaxes[country] ??= _getDefaultTaxesForCountry(country);
    _customTaxes[country]!.remove(rate);
    await _saveToStorage();
  }

  // --- EMPLOYEES & RH ---
  Future<List<Employee>> fetchEmployees() async { await _ensureLoaded(); return List.from(_employeesCache); }
  Future<void> createEmployee(Employee e) async { await _ensureLoaded(); _employeesCache.add(e); await _saveToStorage(); }
  Future<void> updateEmployee(String id, Map<String, dynamic> d) async {
    await _ensureLoaded();
    int idx = _employeesCache.indexWhere((e) => e.id == id);
    if (idx != -1) { _employeesCache[idx] = Employee.fromJson({..._employeesCache[idx].toJson(), ...d}); await _saveToStorage(); }
  }
  Future<void> deleteEmployee(String id) async { await _ensureLoaded(); _employeesCache.removeWhere((e) => e.id == id); await _saveToStorage(); }

  // --- ENTITIES & QUOTES ---
  Future<List<Entity>> fetchEntities() async { await _ensureLoaded(); return List.from(_entitiesCache); }
  Future<void> createEntity(Entity e) async { await _ensureLoaded(); _entitiesCache.add(e); await _saveToStorage(); }
  Future<void> updateEntity(String id, Map<String, dynamic> d) async { await _ensureLoaded(); int idx = _entitiesCache.indexWhere((e) => e.id == id); if (idx != -1) { _entitiesCache[idx] = Entity.fromJson({..._entitiesCache[idx].toJson(), ...d}); await _saveToStorage(); } }

  // --- INVOICING CONFIGS ---
  Future<List<InvoicingConfig>> fetchInvoicingConfigs() async { await _ensureLoaded(); return List.from(_invoicingConfigsCache); }
  Future<void> createInvoicingConfig(InvoicingConfig c) async { await _ensureLoaded(); _invoicingConfigsCache.add(c); await _saveToStorage(); }
  Future<void> updateInvoicingConfig(String id, InvoicingConfig c) async {
    await _ensureLoaded();
    int idx = _invoicingConfigsCache.indexWhere((config) => config.id == id);
    if (idx != -1) { _invoicingConfigsCache[idx] = c; await _saveToStorage(); }
  }
  Future<void> deleteInvoicingConfig(String id) async { await _ensureLoaded(); _invoicingConfigsCache.removeWhere((c) => c.id == id); await _saveToStorage(); }

  Future<List<Map<String, dynamic>>> fetchQuotes() async { await _ensureLoaded(); return List.from(_quotesCache); }
  Future<void> createQuote(Map<String, dynamic> q) async { await _ensureLoaded(); _quotesCache.add(q); await _saveToStorage(); }
  Future<void> deleteQuote(String id) async { _quotesCache.removeWhere((q) => q['id'] == id); await _saveToStorage(); }
  Future<void> updateEstimateStatus(String id, String s) async {
    await _ensureLoaded();
    int idx = _quotesCache.indexWhere((q) => q['id'] == id);
    if (idx != -1) { _quotesCache[idx]['status'] = s; await _saveToStorage(); }
  }

  // --- TASKS & EVENTS ---
  Future<List<Task>> fetchTasks() async { await _ensureLoaded(); return List.from(_tasksCache); }
  Future<void> createTask(Task t) async { await _ensureLoaded(); _tasksCache.add(t); await _saveToStorage(); }
  Future<void> updateTask(String id, Map<String, dynamic> d) async {
    await _ensureLoaded();
    int idx = _tasksCache.indexWhere((t) => t.id == id);
    if (idx != -1) { _tasksCache[idx] = Task.fromJson({..._tasksCache[idx].toJson(), ...d}); await _saveToStorage(); }
  }
  Future<void> deleteTask(String id) async { await _ensureLoaded(); _tasksCache.removeWhere((t) => t.id == id); await _saveToStorage(); }

  Future<List<dynamic>> fetchEvents() async { await _ensureLoaded(); return List.from(_eventsCache); }
  Future<void> createEvent(Map<String, dynamic> d) async { await _ensureLoaded(); _eventsCache.add(d); await _saveToStorage(); }
  Future<void> updateEvent(String id, Map<String, dynamic> d) async {
    await _ensureLoaded();
    int idx = _eventsCache.indexWhere((e) => e['id'].toString() == id);
    if (idx != -1) { _eventsCache[idx] = {..._eventsCache[idx], ...d}; await _saveToStorage(); }
  }
  Future<void> deleteEvent(String id) async { await _ensureLoaded(); _eventsCache.removeWhere((e) => e['id'].toString() == id); await _saveToStorage(); }

  // --- PERSISTENCE ---
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('invoices_db',
        jsonEncode(_invoicesCache.map((i) => i.toJson()).toList()));
    await prefs.setString('employees_db',
        jsonEncode(_employeesCache.map((e) => e.toJson()).toList()));
    await prefs.setString('entities_db',
        jsonEncode(_entitiesCache.map((e) => e.toJson()).toList()));
    await prefs.setString('invoicing_configs_db',
        jsonEncode(_invoicingConfigsCache.map((c) => c.toJson()).toList()));
    await prefs.setString('customers_db',
        jsonEncode(_customersCache.map((c) => c.toJson()).toList()));

    await prefs.setString('suppliers_db', jsonEncode(
        _suppliersCache
            .map((s) => s.toJson())
            .toList())); // Vérifie si tu l'as aussi
    await prefs.setString('journal_db',
        jsonEncode(_journalCache.map((j) => j.toJson()).toList()));
    await prefs.setString(
        'tasks_db', jsonEncode(_tasksCache.map((t) => t.toJson()).toList()));
    await prefs.setString('events_db', jsonEncode(_eventsCache));
    await prefs.setString('quotes_db', jsonEncode(_quotesCache));
    await prefs.setString('notifications_db', jsonEncode(_notifications));
    await prefs.setString('active_accounting_plan_db', _activeAccountingPlan);
    await prefs.setString('custom_accounts_db',
        jsonEncode(_customAccountsCache.map((a) => a.toJson()).toList()));
    await prefs.setString('custom_taxes_db', jsonEncode(_customTaxes));
    await prefs.setString('tr_data_db', jsonEncode(_trDataCache));
    await prefs.setString('company_docs_db', jsonEncode(_companyDocsCache));
    await prefs.setString('cost_centers_db', jsonEncode(_costCentersCache.map((cc) => cc.toJson()).toList()));
    if (_adminPin != null) await prefs.setString('admin_pin_db', _adminPin!);
  }

  Future<void> _loadFromStorage() async {
    if (_isLoadedFromStorage) return;
    final prefs = await SharedPreferences.getInstance();
    _adminPin = prefs.getString('admin_pin_db');
    _activeAccountingPlan = prefs.getString('active_accounting_plan_db') ?? 'France (PCG)';

    _loadCache(prefs, 'invoices_db', _invoicesCache, (data) => Invoice.fromJson(data));
    _loadCache(prefs, 'employees_db', _employeesCache, (data) => Employee.fromJson(data));
    _loadCache(prefs, 'entities_db', _entitiesCache, (data) => Entity.fromJson(data));
    _loadCache(prefs, 'invoicing_configs_db', _invoicingConfigsCache, (data) => InvoicingConfig.fromJson(data));
    _loadCache(prefs, 'suppliers_db', _suppliersCache, (data) => Supplier.fromJson(data));
    _loadCache(prefs, 'customers_db', _customersCache, (data) => Supplier.fromJson(data));
    _loadCache(prefs, 'journal_db', _journalCache, (data) => JournalEntry.fromJson(data));
    _loadCache(prefs, 'tasks_db', _tasksCache, (data) => Task.fromJson(data));
    _loadCache(prefs, 'custom_accounts_db', _customAccountsCache, (data) => Account.fromJson(data));
    _loadCache(prefs, 'cost_centers_db', _costCentersCache, (data) => CostCenter.fromJson(data));

    String? ev = prefs.getString('events_db'); if (ev != null) { _eventsCache.clear(); _eventsCache.addAll(List<dynamic>.from(jsonDecode(ev))); }
    String? qt = prefs.getString('quotes_db'); if (qt != null) { _quotesCache.clear(); _quotesCache.addAll(List<Map<String, dynamic>>.from(jsonDecode(qt))); }
    String? nt = prefs.getString('notifications_db'); if (nt != null) { _notifications.clear(); _notifications.addAll(List<String>.from(jsonDecode(nt))); }
    String? tr = prefs.getString('tr_data_db'); if (tr != null) { _trDataCache.clear(); _trDataCache.addAll(Map<String, dynamic>.from(jsonDecode(tr))); }
    String? cd = prefs.getString('company_docs_db'); if (cd != null) { _companyDocsCache.clear(); _companyDocsCache.addAll(List<Map<String, dynamic>>.from(jsonDecode(cd))); }

    String? taxes = prefs.getString('custom_taxes_db');
    if (taxes != null) {
      _customTaxes.clear();
      Map<String, dynamic> decoded = jsonDecode(taxes);
      decoded.forEach((key, value) { _customTaxes[key] = List<double>.from(value); });
    }

    // --- INITIALIZE DEFAULT COST CENTERS IF EMPTY ---
    if (_costCentersCache.isEmpty) {
      _costCentersCache.addAll([
        CostCenter(id: 'cc-100', code: '100', serviceName: 'RH', managerFirstName: 'Admin', managerLastName: 'RH', approverName: 'Direction'),
        CostCenter(id: 'cc-200', code: '200', serviceName: 'Finance', managerFirstName: 'Admin', managerLastName: 'Finance', approverName: 'CFO'),
        CostCenter(id: 'cc-300', code: '300', serviceName: 'Marketing', managerFirstName: 'Admin', managerLastName: 'Marketing', approverName: 'CMO'),
      ]);
      await _saveToStorage();
    }

    _isLoadedFromStorage = true;
  }

  void _loadCache<T>(SharedPreferences prefs, String key, List<T> cache, T Function(dynamic) fromJson) {
    try {
      String? data = prefs.getString(key);
      if (data != null) {
        List decoded = jsonDecode(data);
        cache.clear();
        cache.addAll(decoded.map((item) => fromJson(item)).toList());
      }
    } catch (e) { debugPrint("Erreur chargement cache $key : $e"); }
  }

  Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _invoicesCache.clear();
    _tasksCache.clear();
    _employeesCache.clear();
    _suppliersCache.clear();
    _customersCache.clear();
    _entitiesCache.clear();
    _invoicingConfigsCache.clear();
    _journalCache.clear();
    _quotesCache.clear();
    _notifications.clear();
    _eventsCache.clear();
    _historyCache.clear();
    _absencesCache.clear();
    _hrDocsCache.clear();
    _costCentersCache.clear();
    _bankTransactionsCache.clear();
    _reconciliationsCache.clear();
    _budgetsCache.clear();
    _bankAccountsCache.clear();
    _customTaxes.clear();
    _customAccountsCache.clear();
    _trDataCache.clear();
    _companyDocsCache.clear();
    _isLoadedFromStorage = false;
    _token = null;
    
    // Re-initialize defaults
    await _loadFromStorage();
  }

  // --- DIVERS ---
  Future<void> importFullDatabase(String jsonString) async { await _ensureLoaded(); }
  Future<String> exportFullDatabase() async { await _ensureLoaded(); return jsonEncode({'version': '1.1', 'invoices': _invoicesCache.map((i) => i.toJson()).toList()}); }
  Future<List<Supplier>> fetchSuppliers() async { await _ensureLoaded(); return _suppliersCache; }
  Future<void> createSupplier(Supplier s) async { _suppliersCache.add(s); await _saveToStorage(); }
  Future<List<Supplier>> fetchCustomers() async { await _ensureLoaded(); return _customersCache; }
  Future<void> createCustomer(Supplier s) async { _customersCache.add(s); await _saveToStorage(); }
  Future<List<Absence>> fetchAbsences() async { await _ensureLoaded(); return _absencesCache; }
  Future<void> createAbsence(Absence a) async { _absencesCache.add(a); await _saveToStorage(); }
  Future<void> deleteAbsence(String id) async { _absencesCache.removeWhere((a) => a.id == id); await _saveToStorage(); }
  Future<List<HRDocument>> fetchHrDocuments() async { await _ensureLoaded(); return _hrDocsCache; }
  Future<void> addHrDocument(HRDocument d) async { _hrDocsCache.add(d); await _saveToStorage(); }
  Future<void> deleteHrDocument(String id) async { _hrDocsCache.removeWhere((d) => d.id == id); await _saveToStorage(); }
  Future<EntityBudget?> fetchEntityBudget(String id) async { await _ensureLoaded(); try { return _budgetsCache.firstWhere((b) => b.entityId == id); } catch(e) { return null; } }
  Future<void> updateEntityBudget(EntityBudget b) async { _budgetsCache.add(b); await _saveToStorage(); }
  Future<List<CostCenter>> fetchCostCenters() async { await _ensureLoaded(); return _costCentersCache; }
  Future<void> createCostCenter(CostCenter c) async { _costCentersCache.add(c); await _saveToStorage(); }
  Future<void> deleteCostCenter(String id) async { _costCentersCache.removeWhere((c) => c.id == id); await _saveToStorage(); }
  Future<String?> getAdminPin() async { await _ensureLoaded(); return _adminPin; }
  Future<void> updateAdminPin(String p) async { _adminPin = p; await _saveToStorage(); }
  Future<void> addNotification(String n) async { _notifications.insert(0, n); await _saveToStorage(); }
  Future<void> clearNotifications() async { _notifications.clear(); await _saveToStorage(); }
  Future<Map<String, dynamic>> getTRData() async { await _ensureLoaded(); return _trDataCache; }
  Future<void> saveTRData(String k, dynamic v) async { _trDataCache[k] = v; await _saveToStorage(); }
  Future<List<Map<String, dynamic>>> fetchCompanyDocuments() async { await _ensureLoaded(); return _companyDocsCache; }
  Future<void> addCompanyDocument(Map<String, dynamic> d) async { _companyDocsCache.add(d); await _saveToStorage(); }
  Future<void> deleteCompanyDocument(String id) async { _companyDocsCache.removeWhere((d) => d['id'] == id); await _saveToStorage(); }
  Future<List<BankAccount>> fetchBankAccounts() async { await _ensureLoaded(); return _bankAccountsCache; }
  Future<void> createBankAccount(BankAccount a) async { _bankAccountsCache.add(a); await _saveToStorage(); }
  Future<List<BankTransaction>> fetchBankTransactions() async { await _ensureLoaded(); return _bankTransactionsCache; }
  Future<void> createBankTransaction(BankTransaction t) async { _bankTransactionsCache.add(t); await _saveToStorage(); }
  Future<void> updateBankTransaction(String id, Map<String, dynamic> d) async { await _ensureLoaded(); int idx = _bankTransactionsCache.indexWhere((t) => t.id == id); if (idx != -1) _bankTransactionsCache[idx] = BankTransaction.fromJson({..._bankTransactionsCache[idx].toJson(), ...d}); await _saveToStorage(); }
  Future<void> deleteBankTransactions(List<String> ids) async { _bankTransactionsCache.removeWhere((t) => ids.contains(t.id)); await _saveToStorage(); }
  Future<List<HistoryEntry>> fetchHistory() async { await _ensureLoaded(); return _historyCache; }
  Future<void> createHistoryEntry(HistoryEntry e) async { _historyCache.add(e); await _saveToStorage(); }
  Future<void> deleteHistoryEntry(String id) async { _historyCache.removeWhere((e) => e.id == id); await _saveToStorage(); }
  Future<List<ReconciliationRecord>> fetchReconciliations() async { await _ensureLoaded(); return _reconciliationsCache; }
  Future<void> createReconciliation(ReconciliationRecord r) async { _reconciliationsCache.add(r); await _saveToStorage(); }
  Future<void> deleteReconciliation(String id) async { _reconciliationsCache.removeWhere((r) => r.id == id); await _saveToStorage(); }
  Future<void> createPayment(Payment p) async { await _ensureLoaded(); }
  Future<void> logout() async { final prefs = await SharedPreferences.getInstance(); await prefs.remove('jwt_token'); _token = null; _isLoaded = false; }
}
