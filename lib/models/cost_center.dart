class CostCenter {
  final String id;
  final String code; // 3 chiffres
  final String serviceName;
  final String managerFirstName;
  final String managerLastName;
  final String approverName;

  CostCenter({
    required this.id,
    required this.code,
    required this.serviceName,
    required this.managerFirstName,
    required this.managerLastName,
    required this.approverName,
  });

  factory CostCenter.fromJson(Map<String, dynamic> json) {
    return CostCenter(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      serviceName: json['serviceName'] ?? '',
      managerFirstName: json['managerFirstName'] ?? '',
      managerLastName: json['managerLastName'] ?? '',
      approverName: json['approverName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'serviceName': serviceName,
    'managerFirstName': managerFirstName,
    'managerLastName': managerLastName,
    'approverName': approverName,
  };

  @override
  String toString() => '$code - $serviceName';
}
