import 'package:intl/intl.dart';

class ReconciliationRecord {
  final String id;
  final String bankAccountId;
  final DateTime month;
  final double statementBalance;
  final double softwareBalance;
  final double difference;
  final List<String> invoiceIds;
  final List<String> bankTxIds;
  final DateTime reconciledAt;
  final double totalAmount;


  ReconciliationRecord({
    required this.id,
    required this.bankAccountId,
    required this.month,
    required this.statementBalance,
    required this.softwareBalance,
    required this.difference,
    required this.invoiceIds,
    required this.bankTxIds,
    required this.reconciledAt,
    this.totalAmount = 0.0,
  });

  String get monthKey => DateFormat('MM/yyyy').format(month);

  ReconciliationRecord copyWith({
    String? id,
    String? bankAccountId,
    DateTime? month,
    double? statementBalance,
    double? softwareBalance,
    double? difference,
    List<String>? invoiceIds,
    List<String>? bankTxIds,
    DateTime? reconciledAt,
    double? totalAmount,
  }) {
    return ReconciliationRecord(
      id: id ?? this.id,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      month: month ?? this.month,
      statementBalance: statementBalance ?? this.statementBalance,
      softwareBalance: softwareBalance ?? this.softwareBalance,
      difference: difference ?? this.difference,
      invoiceIds: invoiceIds ?? this.invoiceIds,
      bankTxIds: bankTxIds ?? this.bankTxIds,
      reconciledAt: reconciledAt ?? this.reconciledAt,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

  factory ReconciliationRecord.fromJson(Map<String, dynamic> json) {
    return ReconciliationRecord(
      id: json['id'],
      bankAccountId: json['bankAccountId'],
      month: DateTime.parse(json['month']),
      statementBalance: (json['statementBalance'] as num).toDouble(),
      softwareBalance: (json['softwareBalance'] as num).toDouble(),
      difference: (json['difference'] as num).toDouble(),
      invoiceIds: List<String>.from(json['invoiceIds'] ?? []),
      bankTxIds: List<String>.from(json['bankTxIds'] ?? []),
      reconciledAt: DateTime.parse(json['reconciledAt']),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bankAccountId': bankAccountId,
    'month': month.toIso8601String(),
    'statementBalance': statementBalance,
    'softwareBalance': softwareBalance,
    'difference': difference,
    'invoiceIds': invoiceIds,
    'bankTxIds': bankTxIds,
    'reconciledAt': reconciledAt.toIso8601String(),
    'totalAmount': totalAmount,
  };
}
