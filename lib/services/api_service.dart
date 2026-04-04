import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/task.dart';
import '../models/invoice.dart';
import '../models/entity.dart';
import '../models/employee.dart';
import '../models/supplier.dart';
import '../models/journal_entry.dart';
import '../models/history_entry.dart';
import '../models/account.dart';
import '../models/payment.dart';
import '../models/bank_account.dart';
import '../models/bank_transaction.dart';
import '../models/reconciliation_record.dart';
import '../ai/accounting_ai.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3001';

  late final AccountingAI aiProvider;

  ApiService() {
    final String key = dotenv.get('GEMINI_API_KEY', fallback: '');

    if (key.isEmpty) {
      debugPrint(
          'ERREUR : La clé API Gemini est vide. Vérifiez votre fichier .env');
    }

    aiProvider = AccountingAI(apiKey: key);
  }

  // --- CACHES STATIQUES ---
  static final List<Entity> _entitiesCache = [];
  static final List<Supplier> _suppliersCache = [];
  static final List<Supplier> _customersCache = [];
  static final List<Invoice> _invoicesCache = [];
  static final List<JournalEntry> _journalCache = [];
  static final List<Map<String, dynamic>> _quotesCache = [];
  static final List<BankAccount> _bankAccountsCache = [];
  static final List<HistoryEntry> _historyCache = [];
  static final List<Employee> _employeesCache = [];
  static final List<Absence> _absencesCache = [];
  static final List<Task> _tasksCache = [];
  static final List<HRDocument> _hrDocsCache = [];
  static final Map<String, dynamic> _trDataCache = {};
  static final List<String> _notifications = [];
  static final List<ReconciliationRecord> _reconciliationsCache = [];
  static final List<Account> _customAccountsCache = [];
  static final List<BankTransaction> _bankTransactionsCache = [];
  static final List<Map<String, dynamic>> _companyDocsCache = [];
  static final List<dynamic> _eventsCache = [];

  static final Map<String, List<double>> _customTaxes = {
    'France': [0.0, 2.1, 5.5, 10.0, 20.0],
    'UK': [0.0, 5.0, 20.0],
    'Germany': [0.0, 7.0, 19.0],
    'Spain': [0.0, 4.0, 10.0, 21.0],
    'Italy': [0.0, 4.0, 5.0, 10.0, 22.0],
    'Portugal': [0.0, 6.0, 13.0, 23.0],
    'Belgium': [0.0, 6.0, 12.0, 21.0],
    'Luxembourg': [0.0, 3.0, 8.0, 14.0, 17.0],
    'Switzerland': [0.0, 2.6, 3.8, 8.1],
    'USA': [0.0, 4.0, 6.25, 8.875],
  };

  static bool _isLoadedFromStorage = false;
  static String? _adminPin;

  List<double> getTaxesForCountry(String country) {
    String key = country;
    if (country == 'Allemagne') key = 'Germany';
    return _customTaxes[key] ?? [0.0, 20.0];
  }

  Future<void> addTaxRate(String country, double rate) async {
    await _ensureLoaded();
    String key = country;
    if (country == 'Allemagne') key = 'Germany';
    if (!_customTaxes.containsKey(key)) _customTaxes[key] = [];
    if (!_customTaxes[key]!.contains(rate)) {
      _customTaxes[key]!.add(rate);
      _customTaxes[key]!.sort();
      await _saveToStorage();
    }
  }

  Future<void> _ensureLoaded() async {
    if (!_isLoadedFromStorage) {
      await _loadFromStorage();
    }
  }

  Future<List<Account>> fetchAccounts() async {
    await _ensureLoaded();
    return [...Account.defaultAccounts, ..._customAccountsCache];
  }

  Future<void> createAccount(Account account) async {
    await _ensureLoaded();
    int idx = _customAccountsCache.indexWhere((a) => a.id == account.id);
    if (idx != -1) {
      _customAccountsCache[idx] = account; // Mise à jour si l'ID existe déjà
    } else {
      // Si c'est un nouveau numéro de compte, on vérifie s'il existe déjà par numéro
      int numIdx = _customAccountsCache.indexWhere((a) => a.number == account.number);
      if (numIdx != -1) {
        _customAccountsCache[numIdx] = account;
      } else {
        _customAccountsCache.add(account);
      }
    }
    await _saveToStorage();
  }

  Future<void> deleteAccount(String id) async {
    await _ensureLoaded();
    _customAccountsCache.removeWhere((a) => a.id == id);
    await _saveToStorage();
  }

  Future<List<BankAccount>> fetchBankAccounts() async {
    await _ensureLoaded();
    return List.from(_bankAccountsCache);
  }

  Future<void> createBankAccount(BankAccount account) async {
    await _ensureLoaded();
    _bankAccountsCache.add(account);
    await _saveToStorage();
  }

  Future<List<Invoice>> fetchInvoices(InvoiceType type) async {
    await _ensureLoaded();
    return _invoicesCache.where((i) => i.type == type).toList();
  }

  Future<void> createInvoice(Invoice inv) async {
    await _ensureLoaded();
    _invoicesCache.add(inv);

    for (var p in inv.payments) {
      _bankTransactionsCache.add(BankTransaction(
        id: 'pay-${p.id}',
        date: p.date,
        description: "Acompte ${inv.type == InvoiceType.achat ? 'Fournisseur' : 'Client'} : ${inv.supplierOrClientName} (${inv.number})",
        amount: inv.type == InvoiceType.achat ? -p.amountBaseCurrency : p.amountBaseCurrency,
        currency: inv.currency,
        originalAmount: p.amount,
        originalCurrency: p.currency,
        exchangeRate: p.exchangeRate,
        bankAccountId: p.bankAccountId.isNotEmpty ? p.bankAccountId : inv.bankAccountId,
        isReconciled: false,
        matchedDocumentId: inv.id,
        matchedDocumentNumber: inv.number,
      ));
    }

    await _saveToStorage();
  }

  Future<void> updateInvoice(String id, Map<String, dynamic> data) async {
    await _ensureLoaded();
    int idx = _invoicesCache.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final oldInvoice = _invoicesCache[idx];
      Invoice updated = Invoice.fromJson({...oldInvoice.toJson(), ...data});
      _invoicesCache[idx] = updated;
      await _saveToStorage();
    }
  }

  Future<void> updateEstimateStatus(String id, String status) async {
    await _ensureLoaded();
    int idx = _quotesCache.indexWhere((e) => e['id'] == id);
    if (idx != -1) {
      _quotesCache[idx]['status'] = status;
      await _saveToStorage();
    }
  }

  Future<void> deleteInvoice(String id) async {
    await _ensureLoaded();
    int idx = _invoicesCache.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final inv = _invoicesCache[idx];
      _historyCache.add(HistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        documentId: id,
        documentNumber: inv.number,
        type: inv.type == InvoiceType.achat ? HistoryType.invoiceAchat : HistoryType.invoiceVente,
        action: HistoryAction.deleted,
        timestamp: DateTime.now(),
        data: inv.toJson(),
      ));
      _invoicesCache.removeAt(idx);
      await _saveToStorage();
    }
  }

  Future<List<BankTransaction>> fetchBankTransactions() async {
    await _ensureLoaded();
    return List.from(_bankTransactionsCache);
  }

  Future<void> createBankTransaction(BankTransaction tx) async {
    await _ensureLoaded();
    _bankTransactionsCache.add(tx);
    await _saveToStorage();
  }

  Future<void> deleteBankTransactions(List<String> ids) async {
    await _ensureLoaded();
    _bankTransactionsCache.removeWhere((t) => ids.contains(t.id));
    await _saveToStorage();
  }

  Future<void> createPayment(Payment payment) async {
    await _ensureLoaded();

    _bankTransactionsCache.add(BankTransaction(
      id: 'pay-${payment.id}',
      date: payment.date,
      description: "Paiement : ${payment.linkedInvoiceId}",
      amount: payment.type == PaymentType.fournisseur
          ? -payment.amountBaseCurrency
          : payment.amountBaseCurrency,
      currency: 'EUR',
      originalAmount: payment.amount,
      originalCurrency: payment.currency,
      exchangeRate: payment.exchangeRate,
      bankAccountId: payment.bankAccountId,
      isReconciled: false,
      matchedDocumentId: payment.linkedInvoiceId,
    ));

    int invIdx = _invoicesCache.indexWhere((i) => i.id == payment.linkedInvoiceId);
    if (invIdx != -1) {
      final inv = _invoicesCache[invIdx];
      List<Payment> updatedPayments = List.from(inv.payments)..add(payment);
      _invoicesCache[invIdx] = inv.copyWith(
        payments: updatedPayments,
        status: (inv.totalPaid + payment.amountBaseCurrency >= inv.amountTTC)
            ? InvoiceStatus.paid
            : InvoiceStatus.partiallyPaid,
      );
    } else {
      int quoteIdx = _quotesCache.indexWhere((q) => q['id'] == payment.linkedInvoiceId);
      if (quoteIdx != -1) {
        _quotesCache[quoteIdx]['status'] = 'accepted';
      }
    }

    await _saveToStorage();
  }

  Future<void> updateBankTransaction(String id, Map<String, dynamic> data) async {
    await _ensureLoaded();
    int idx = _bankTransactionsCache.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final old = _bankTransactionsCache[idx];
      final updated = BankTransaction.fromJson({...old.toJson(), ...data});
      _bankTransactionsCache[idx] = updated;

      if (data['isReconciled'] == true && old.matchedDocumentId != null) {
        int invIdx = _invoicesCache.indexWhere((i) => i.id == old.matchedDocumentId);
        if (invIdx != -1) {
          final inv = _invoicesCache[invIdx];
          if (inv.remainingAmount <= 0.01) {
            _invoicesCache[invIdx] = inv.copyWith(
              isReconciled: true,
              reconciledDate: DateTime.now(),
              status: InvoiceStatus.paid,
            );
          } else {
            _invoicesCache[invIdx] = inv.copyWith(status: InvoiceStatus.partiallyPaid);
          }
        }
      }
      await _saveToStorage();
    }
  }

  Future<List<ReconciliationRecord>> fetchReconciliations() async {
    await _ensureLoaded();
    repairHistoryAmounts();
    return List.from(_reconciliationsCache);
  }

  Future<void> createReconciliation(ReconciliationRecord record) async {
    await _ensureLoaded();

    double totalCalcul = 0.0;
    for (var txId in record.bankTxIds) {
      final tx = _bankTransactionsCache.firstWhere(
            (t) => t.id == txId,
        orElse: () =>
            BankTransaction(
              id: '',
              date: DateTime.now(),
              description: '',
              amount: 0,
              bankAccountId: '',
              isReconciled: false,
            ),
      );
      totalCalcul += tx.amount;
    }

    final updatedRecord = record.copyWith(totalAmount: totalCalcul != 0 ? totalCalcul : record.totalAmount);
    _reconciliationsCache.add(updatedRecord);

    final allIds = [...record.bankTxIds, ...record.invoiceIds];
    for (var id in allIds) {
      int idx = _bankTransactionsCache.indexWhere((t) => t.id == id);
      if (idx != -1) {
        _bankTransactionsCache[idx] =
            _bankTransactionsCache[idx].copyWith(isReconciled: true);
      }
    }

    await _saveToStorage();
  }

  void repairHistoryAmounts() {
    bool changed = false;
    for (var i = 0; i < _reconciliationsCache.length; i++) {
      var record = _reconciliationsCache[i];
      if (record.totalAmount == 0) {
        double realSum = _bankTransactionsCache
            .where((t) => record.bankTxIds.contains(t.id))
            .fold(0.0, (sum, t) => sum + t.amount);

        if (realSum == 0) {
          realSum = _bankTransactionsCache
              .where((t) => record.invoiceIds.contains(t.id))
              .fold(0.0, (sum, t) => sum + t.amount);
        }

        if (realSum != 0) {
          _reconciliationsCache[i] = record.copyWith(totalAmount: realSum);
          changed = true;
        }
      }
    }
    if (changed) {
      _saveToStorage();
    }
  }

  Future<void> deleteReconciliation(String id) async {
    await _ensureLoaded();
    _reconciliationsCache.removeWhere((r) => r.id == id);
    await _saveToStorage();
  }

  Future<List<JournalEntry>> fetchJournalEntries() async {
    await _ensureLoaded();
    return List.from(_journalCache);
  }

  Future<void> createJournalEntry(JournalEntry entry) async {
    await _ensureLoaded();
    _journalCache.add(entry);
    for (var line in entry.lines) {
      if (line.accountCode.startsWith('51')) {
        _bankTransactionsCache.add(BankTransaction(
          id: 'journal-${entry.id}-${entry.lines.indexOf(line)}',
          date: entry.date,
          description: "${entry.journalNumber} : ${line.description}",
          amount: line.debit > 0 ? line.debit : -line.credit,
          bankAccountId: line.accountCode,
          isReconciled: false,
          matchedDocumentId: entry.id,
          matchedDocumentNumber: entry.journalNumber,
        ));
      }
    }
    await _saveToStorage();
  }

  Future<void> updateJournalEntry(String id, JournalEntry entry) async {
    await _ensureLoaded();
    int idx = _journalCache.indexWhere((j) => j.id == id);
    if (idx != -1) {
      _journalCache[idx] = entry;
      _bankTransactionsCache.removeWhere((t) => t.matchedDocumentId == id);
      for (var line in entry.lines) {
        if (line.accountCode.startsWith('51')) {
          _bankTransactionsCache.add(BankTransaction(
            id: 'journal-${entry.id}-${entry.lines.indexOf(line)}',
            date: entry.date,
            description: "${entry.journalNumber} : ${line.description}",
            amount: line.debit > 0 ? line.debit : -line.credit,
            bankAccountId: line.accountCode,
            isReconciled: false,
            matchedDocumentId: entry.id,
            matchedDocumentNumber: entry.journalNumber,
          ));
        }
      }
      await _saveToStorage();
    }
  }

  Future<void> deleteJournalEntry(String id) async {
    await _ensureLoaded();
    int idx = _journalCache.indexWhere((j) => j.id == id);
    if (idx != -1) {
      final entry = _journalCache[idx];
      _historyCache.add(HistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        documentId: id,
        documentNumber: entry.journalNumber,
        type: HistoryType.journal,
        action: HistoryAction.deleted,
        timestamp: DateTime.now(),
        data: entry.toJson(),
      ));
      _journalCache.removeAt(idx);
      _bankTransactionsCache.removeWhere((t) => t.matchedDocumentId == id);
      await _saveToStorage();
    }
  }

  Future<List<Supplier>> fetchSuppliers() async { await _ensureLoaded(); return List.from(_suppliersCache); }
  Future<void> createSupplier(Supplier s) async {await _ensureLoaded();
  int idx = _suppliersCache.indexWhere((existing) => existing.id == s.id);if (idx != -1) {
    _suppliersCache[idx] = s;
  } else {
    _suppliersCache.add(s);
  }
  await _saveToStorage();
  }
  Future<List<Supplier>> fetchCustomers() async {
    await _ensureLoaded(); return List.from(_customersCache); }

  Future<void> createCustomer(Supplier s) async {
    await _ensureLoaded();
    int idx = _customersCache.indexWhere((existing) => existing.id == s.id);
    if (idx != -1) {
      _customersCache[idx] = s;
    } else {
      _customersCache.add(s);
    }
    await _saveToStorage();
  }

  Future<List<Map<String, dynamic>>> fetchQuotes() async { await _ensureLoaded(); return List.from(_quotesCache); }
  Future<void> createQuote(Map<String, dynamic> quote) async { await _ensureLoaded(); _quotesCache.add(quote); await _saveToStorage(); }
  Future<void> updateQuote(String id, Map<String, dynamic> data) async { await _ensureLoaded(); int idx = _quotesCache.indexWhere((q) => q['id'] == id); if (idx != -1) { _quotesCache[idx] = {..._quotesCache[idx], ...data}; await _saveToStorage(); } }
  Future<void> deleteQuote(String id) async {
    await _ensureLoaded();
    int idx = _quotesCache.indexWhere((q) => q['id'] == id);
    if (idx != -1) {
      final q = _quotesCache[idx];
      _historyCache.add(HistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        documentId: id,
        documentNumber: q['number'] ?? 'DEV-?',
        type: HistoryType.quote,
        action: HistoryAction.deleted,
        timestamp: DateTime.now(),
        data: q,
      ));
      _quotesCache.removeAt(idx);
      await _saveToStorage();
    }
  }

  Future<List<Entity>> fetchEntities() async {
    await _ensureLoaded(); return List.from(_entitiesCache);
  }

  Future<void> createEntity(Entity e) async {
    await _ensureLoaded(); _entitiesCache.add(e);
    await _saveToStorage(); }

  Future<void> updateEntity(String id, Map<String, dynamic> data) async {
    await _ensureLoaded();
    int idx = _entitiesCache.indexWhere((e) => e.id == id);
    if (idx != -1) { _entitiesCache[idx] = Entity.fromJson({..._entitiesCache[idx].toJson(), ...data}); await _saveToStorage(); }
  }

  Future<List<dynamic>> fetchEvents() async { await _ensureLoaded(); return _eventsCache; }
  Future<void> createEvent(Map<String, dynamic> data) async {
    await _ensureLoaded();
    if (data['id'] == null) data['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    _eventsCache.add(data);
    await _saveToStorage();
  }
  Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    await _ensureLoaded();
    int idx = _eventsCache.indexWhere((e) => e['id'].toString() == id);
    if (idx != -1) { _eventsCache[idx] = {..._eventsCache[idx], ...data}; await _saveToStorage(); }
  }
  Future<void> deleteEvent(String id) async { await _ensureLoaded(); _eventsCache.removeWhere((e) => e['id'].toString() == id); await _saveToStorage(); }

  Future<void> updateTask(String id, Map<String, dynamic> data) async {
    await _ensureLoaded();
    int idx = _tasksCache.indexWhere((t) => t.id == id);
    if (idx != -1) { _tasksCache[idx] = Task.fromJson({..._tasksCache[idx].toJson(), ...data}); await _saveToStorage(); }
  }
  Future<void> deleteTask(String id) async { await _ensureLoaded(); _tasksCache.removeWhere((t) => t.id == id); await _saveToStorage(); }

  Future<List<Task>> fetchTasks() async {
    await _ensureLoaded();
    return List.from(_tasksCache);
  }

  Future<void> createTask(Task task) async {
    await _ensureLoaded();
    _tasksCache.add(task);
    await _saveToStorage();
  }

  Future<List<Employee>> fetchEmployees() async {
    await _ensureLoaded();
    return List.from(_employeesCache);
  }

  Future<void> createEmployee(Employee e) async {
    await _ensureLoaded();
    _employeesCache.add(e);
    await _saveToStorage();
  }

  Future<void> updateEmployee(String id, Map<String, dynamic> data) async {
    await _ensureLoaded();
    int idx = _employeesCache.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _employeesCache[idx] = Employee.fromJson({..._employeesCache[idx].toJson(), ...data});
      await _saveToStorage();
    }
  }

  Future<List<Absence>> fetchAbsences() async {
    await _ensureLoaded();
    return List.from(_absencesCache);
  }

  Future<void> createAbsence(Absence a) async {
    await _ensureLoaded();
    _absencesCache.add(a);
    await _saveToStorage();
  }

  Future<void> deleteAbsence(String id) async {
    await _ensureLoaded();
    _absencesCache.removeWhere((a) => a.id == id);
    await _saveToStorage();
  }

  Future<List<HRDocument>> fetchHrDocuments() async {
    await _ensureLoaded();
    return List.from(_hrDocsCache);
  }

  Future<void> addHrDocument(HRDocument doc) async {
    await _ensureLoaded();
    _hrDocsCache.add(doc);
    await _saveToStorage();
  }

  Future<void> deleteHrDocument(String id) async {
    await _ensureLoaded();
    _hrDocsCache.removeWhere((d) => d.id == id);
    await _saveToStorage();
  }

  Future<Map<String, dynamic>> getTRData() async {
    await _ensureLoaded();
    return Map.from(_trDataCache);
  }

  Future<void> saveTRData(String key, dynamic value) async {
    await _ensureLoaded();
    _trDataCache[key] = value;
    await _saveToStorage();
  }

  Future<List<Map<String, dynamic>>> fetchCompanyDocuments() async {
    await _ensureLoaded();
    return List.from(_companyDocsCache);
  }

  Future<void> addCompanyDocument(Map<String, dynamic> doc) async {
    await _ensureLoaded();
    _companyDocsCache.add(doc);
    await _saveToStorage();
  }

  Future<void> deleteCompanyDocument(String id) async {
    await _ensureLoaded();
    _companyDocsCache.removeWhere((d) => d['id'] == id);
    await _saveToStorage();
  }

  Future<void> addNotification(String n) async { await _ensureLoaded(); _notifications.insert(0, n); await _saveToStorage(); }

  Future<String?> getAdminPin() async {
    await _ensureLoaded();
    return _adminPin;
  }

  Future<void> updateAdminPin(String pin) async {
    await _ensureLoaded();
    _adminPin = pin;
    await _saveToStorage();
  }

  Future<List<HistoryEntry>> fetchHistory() async {
    await _ensureLoaded(); return List.from(_historyCache);
  }

  Future<void> createHistoryEntry(HistoryEntry entry) async {
    await _ensureLoaded();
    _historyCache.add(entry);
    await _saveToStorage();
  }

  Future<void> deleteHistoryEntry(String id) async {
    await _ensureLoaded();
    _historyCache.removeWhere((e) => e.id == id);
    await _saveToStorage();
  }

  Future<void> restoreHistoryEntry(String id) async {
    await _ensureLoaded();
    int idx = _historyCache.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final entry = _historyCache[idx];
      if (entry.data != null) {
        switch (entry.type) {
          case HistoryType.invoiceAchat:
          case HistoryType.invoiceVente:
            _invoicesCache.add(Invoice.fromJson(entry.data!));
            break;
          case HistoryType.quote:
            _quotesCache.add(entry.data!);
            break;
          case HistoryType.journal:
            _journalCache.add(JournalEntry.fromJson(entry.data!));
            break;
          case HistoryType.supplier:
            _suppliersCache.add(Supplier.fromJson(entry.data!));
            break;
          case HistoryType.customer:
            _customersCache.add(Supplier.fromJson(entry.data!));
            break;
          case HistoryType.employee:
            _employeesCache.add(Employee.fromJson(entry.data!));
            break;
          case HistoryType.absence:
            _absencesCache.add(Absence.fromJson(entry.data!));
            break;
          case HistoryType.hrDocument:
            _hrDocsCache.add(HRDocument.fromJson(entry.data!));
            break;
          case HistoryType.entity:
            _entitiesCache.add(Entity.fromJson(entry.data!));
            break;
          case HistoryType.companyDoc:
            _companyDocsCache.add(entry.data!);
            break;
          case HistoryType.event:
            _eventsCache.add(entry.data!);
            break;
          default:
            break;
        }
      }
      _historyCache.removeAt(idx);
      await _saveToStorage();
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('invoices_db',
          jsonEncode(_invoicesCache.map((i) => i.toJson()).toList()));
      await prefs.setString('bank_accounts_db',
          jsonEncode(_bankAccountsCache.map((b) => b.toJson()).toList()));
      await prefs.setString('bank_transactions_db',
          jsonEncode(_bankTransactionsCache.map((t) => t.toJson()).toList()));
      await prefs.setString('journal_db',
          jsonEncode(_journalCache.map((j) => j.toJson()).toList()));
      await prefs.setString('suppliers_db',
          jsonEncode(_suppliersCache.map((s) => s.toJson()).toList()));
      await prefs.setString('customers_db',
          jsonEncode(_customersCache.map((s) => s.toJson()).toList()));
      await prefs.setString('quotes_db', jsonEncode(_quotesCache));
      await prefs.setString('entities_db',
          jsonEncode(_entitiesCache.map((e) => e.toJson()).toList()));
      await prefs.setString('reconciliations_db',
          jsonEncode(_reconciliationsCache.map((r) => r.toJson()).toList()));
      await prefs.setString('custom_accounts_db',
          jsonEncode(_customAccountsCache.map((a) => a.toJson()).toList()));
      await prefs.setString('history_db',
          jsonEncode(_historyCache.map((h) => h.toJson()).toList()));

      await prefs.setString(
          'tasks_db', jsonEncode(_tasksCache.map((t) => t.toJson()).toList()));
      await prefs.setString('employees_db',
          jsonEncode(_employeesCache.map((e) => e.toJson()).toList()));
      await prefs.setString('absences_db',
          jsonEncode(_absencesCache.map((a) => a.toJson()).toList()));
      await prefs.setString(
          'events_db', jsonEncode(_eventsCache));
      await prefs.setString('hr_docs_db',
          jsonEncode(_hrDocsCache.map((d) => d.toJson()).toList()));
      await prefs.setString('company_docs_db', jsonEncode(_companyDocsCache));
      await prefs.setString('tr_data_db', jsonEncode(_trDataCache));
      await prefs.setString('custom_taxes_db', jsonEncode(_customTaxes));

      if (_adminPin != null) await prefs.setString('admin_pin_db', _adminPin!);

      debugPrint('Sauvegarde complète réussie !');
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde : $e');
    }
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _loadCache(prefs, 'invoices_db', _invoicesCache, (data) =>
          Invoice.fromJson(data));
      _loadCache(prefs, 'bank_accounts_db', _bankAccountsCache, (data) =>
          BankAccount.fromJson(data));
      _loadCache(
          prefs, 'bank_transactions_db', _bankTransactionsCache, (data) =>
          BankTransaction.fromJson(data));
      _loadCache(prefs, 'journal_db', _journalCache, (data) =>
          JournalEntry.fromJson(data));
      _loadCache(prefs, 'suppliers_db', _suppliersCache, (data) =>
          Supplier.fromJson(data));
      _loadCache(prefs, 'customers_db', _customersCache, (data) =>
          Supplier.fromJson(data));
      _loadCache(prefs, 'entities_db', _entitiesCache, (data) =>
          Entity.fromJson(data));
      _loadCache(prefs, 'reconciliations_db', _reconciliationsCache, (data) =>
          ReconciliationRecord.fromJson(data));
      _loadCache(prefs, 'custom_accounts_db', _customAccountsCache, (data) =>
          Account.fromJson(data));
      _loadCache(prefs, 'history_db', _historyCache, (data) =>
          HistoryEntry.fromJson(data));

      _loadCache(prefs, 'tasks_db', _tasksCache, (data) => Task.fromJson(data));
      _loadCache(prefs, 'employees_db', _employeesCache, (data) =>
          Employee.fromJson(data));
      _loadCache(prefs, 'absences_db', _absencesCache, (data) =>
          Absence.fromJson(data));
      _loadCache(prefs, 'hr_docs_db', _hrDocsCache, (data) =>
          HRDocument.fromJson(data));

      String? q = prefs.getString('quotes_db');
      if (q != null) {
        _quotesCache.clear();
        _quotesCache.addAll(List<Map<String, dynamic>>.from(jsonDecode(q)));
      }

      String? ev = prefs.getString('events_db');
      if (ev != null) {
        _eventsCache.clear();
        _eventsCache.addAll(List<dynamic>.from(jsonDecode(ev)));
      }

      String? tr = prefs.getString('tr_data_db');
      if (tr != null) {
        _trDataCache.clear();
        _trDataCache.addAll(Map<String, dynamic>.from(jsonDecode(tr)));
      }

      String? tx = prefs.getString('custom_taxes_db');
      if (tx != null) {
        Map<String, dynamic> decoded = jsonDecode(tx);
        _customTaxes.clear();
        decoded.forEach((key, value) {
          _customTaxes[key] = List<double>.from(value);
        });
      }

      _adminPin = prefs.getString('admin_pin_db');
      _isLoadedFromStorage = true;
      debugPrint('Chargement complet réussi !');
    } catch (e) {
      debugPrint('ApiService load error: $e');
      _isLoadedFromStorage = true;
    }
  }

  void _loadCache<T>(SharedPreferences prefs, String key, List<T> cache,
      T Function(dynamic) fromJson) {
    String? data = prefs.getString(key);
    if (data != null) {
      List decoded = jsonDecode(data);
      cache.clear();
      cache.addAll(decoded.map((item) => fromJson(item)).toList());
    }
  }
}
