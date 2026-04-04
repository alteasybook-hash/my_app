class BankTransaction {
  final String id;
  final DateTime date;
  final String description;
  final double amount; // Montant dans la devise du compte bancaire (ex: EUR)
  final String? bankAccountId; // ID de l'Account (commence par 5)
  final String? matchedDocumentId; // ID de la Facture ou JournalEntry
  final String? matchedDocumentNumber;
  final bool isReconciled;
  final String? paymentStatus; // 'partial', 'completed', 'overpaid'
  final double? remainingAmount; // Le reste à payer si partiel
  final double? surplusAmount; // Le surplus si trop payé
  final String? source; // Ajouté pour le suivi
  final String? getBankTransactions;
  final String? statementBalance;
  final String? reconciliationId;
  final String? reconciledDate;
  final String? currency; // Devise du compte bancaire

  // --- Gestion Multi-Devise (Original) ---
  final double? originalAmount;
  final String? originalCurrency;
  final double? exchangeRate;

  BankTransaction({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.isReconciled,
    this.bankAccountId,
    this.matchedDocumentId,
    this.matchedDocumentNumber,
    this.paymentStatus,
    this.remainingAmount,
    this.surplusAmount,
    this.source,
    this.getBankTransactions,
    this.statementBalance,
    this.reconciliationId,
    this.reconciledDate,
    this.currency,
    this.originalAmount,
    this.originalCurrency,
    this.exchangeRate,
  });

  BankTransaction copyWith({
    String? id,
    DateTime? date,
    String? description,
    double? amount,
    String? bankAccountId,
    String? matchedDocumentId,
    String? matchedDocumentNumber,
    bool? isReconciled,
    String? paymentStatus,
    double? remainingAmount,
    double? surplusAmount,
    String? source,
    String? getBankTransactions,
    String? statementBalance,
    String? reconciliationId,
    String? reconciledDate,
    String? currency,
    double? originalAmount,
    String? originalCurrency,
    double? exchangeRate,
  }) {
    return BankTransaction(
      id: id ?? this.id,
      date: date ?? this.date,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      isReconciled: isReconciled ?? this.isReconciled,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      matchedDocumentId: matchedDocumentId ?? this.matchedDocumentId,
      matchedDocumentNumber: matchedDocumentNumber ?? this.matchedDocumentNumber,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      surplusAmount: surplusAmount ?? this.surplusAmount,
      source: source ?? this.source,
      getBankTransactions: getBankTransactions ?? this.getBankTransactions,
      statementBalance: statementBalance ?? this.statementBalance,
      reconciliationId: reconciliationId ?? this.reconciliationId,
      reconciledDate: reconciledDate ?? this.reconciledDate,
      currency: currency ?? this.currency,
      originalAmount: originalAmount ?? this.originalAmount,
      originalCurrency: originalCurrency ?? this.originalCurrency,
      exchangeRate: exchangeRate ?? this.exchangeRate,
    );
  }

  factory BankTransaction.fromJson(Map<String, dynamic> json) {
    return BankTransaction(
      id: json['id'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      description: json['description'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      bankAccountId: json['bankAccountId'],
      matchedDocumentId: json['matchedDocumentId'],
      matchedDocumentNumber: json['matchedDocumentNumber'],
      isReconciled: json['isReconciled'] ?? false,
      paymentStatus: json['paymentStatus'],
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble(),
      surplusAmount: (json['surplusAmount'] as num?)?.toDouble(),
      source: json['source'],
      getBankTransactions: json['getBankTransactions'],
      statementBalance: json['statementBalance'],
      reconciliationId: json['reconciliationId'],
      reconciledDate: json['reconciledDate'],
      currency: json['currency'],
      originalAmount: (json['originalAmount'] as num?)?.toDouble(),
      originalCurrency: json['originalCurrency'],
      exchangeRate: (json['exchangeRate'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'description': description,
    'amount': amount,
    'bankAccountId': bankAccountId,
    'matchedDocumentId': matchedDocumentId,
    'matchedDocumentNumber': matchedDocumentNumber,
    'isReconciled': isReconciled,
    'paymentStatus': paymentStatus,
    'remainingAmount': remainingAmount,
    'surplusAmount': surplusAmount,
    'source': source,
    'getBankTransactions': getBankTransactions,
    'statementBalance': statementBalance,
    'reconciliationId': reconciliationId,
    'reconciledDate': reconciledDate,
    'currency': currency,
    'originalAmount': originalAmount,
    'originalCurrency': originalCurrency,
    'exchangeRate': exchangeRate,
  };
}
