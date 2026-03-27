enum FnpStatus { provisioned, reversed }

class FnpItem {
  final String id;
  final String supplierName;
  final double estimatedAmount;
  final DateTime month;
  final FnpStatus status;
  final String entityId;

  FnpItem({
    required this.id,
    required this.supplierName,
    required this.estimatedAmount,
    required this.month,
    this.status = FnpStatus.provisioned,
    required this.entityId,
  });

  factory FnpItem.fromJson(Map<String, dynamic> json) {
    return FnpItem(
      id: json['id'],
      supplierName: json['supplierName'],
      estimatedAmount: json['estimatedAmount'].toDouble(),
      month: DateTime.parse(json['month']),
      status: FnpStatus.values.firstWhere((e) => e.toString().split('.').last == json['status']),
      entityId: json['entityId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'supplierName': supplierName,
    'estimatedAmount': estimatedAmount,
    'month': month.toIso8601String(),
    'status': status.toString().split('.').last,
    'entityId': entityId,
  };
}
