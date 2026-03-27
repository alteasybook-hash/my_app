class JournalLine {
  String accountCode;
  String description;
  double debit;
  double credit;
  double? tvaRate; // Taux de TVA appliqué à cette ligne

  JournalLine({
    required this.accountCode,
    required this.description,
    this.debit = 0.0,
    this.credit = 0.0,
    this.tvaRate,
  });

  factory JournalLine.fromJson(Map<String, dynamic> json) {
    return JournalLine(
      accountCode: json['accountCode'] ?? '',
      description: json['description'] ?? '',
      debit: (json['debit'] as num?)?.toDouble() ?? 0.0,
      credit: (json['credit'] as num?)?.toDouble() ?? 0.0,
      tvaRate: (json['tvaRate'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'accountCode': accountCode,
    'description': description,
    'debit': debit,
    'credit': credit,
    'tvaRate': tvaRate,
  };
}

class JournalEntry {
  final String id;
  final String entityId;
  final String journalNumber;
  final DateTime date;
  final String currency;
  final List<JournalLine> lines;
  final String? reference;

  JournalEntry({
    required this.id,
    required this.entityId,
    required this.journalNumber,
    required this.date,
    this.currency = 'EUR',
    required this.lines,
    this.reference,
  });

  double get totalDebit => lines.fold(0, (sum, line) => sum + line.debit);
  double get totalCredit => lines.fold(0, (sum, line) => sum + line.credit);
  bool get isBalanced => (totalDebit - totalCredit).abs() < 0.01;

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id']?.toString() ?? '',
      entityId: json['entityId'] ?? '',
      journalNumber: json['journalNumber'] ?? '',
      date: DateTime.parse(json['date']),
      currency: json['currency'] ?? 'EUR',
      reference: json['reference'],
      lines: (json['lines'] as List?)?.map((l) => JournalLine.fromJson(l)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'entityId': entityId,
    'journalNumber': journalNumber,
    'date': date.toIso8601String(),
    'currency': currency,
    'reference': reference,
    'lines': lines.map((l) => l.toJson()).toList(),
  };
}
