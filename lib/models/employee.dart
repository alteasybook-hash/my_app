enum ContractType { cdi, cdd, stage }
enum EmployeeStatus { salarie, cadre, stagiaire }

class Employee {
  final String id;
  final String firstName;
  final String lastName;
  final String? email; // Ajout de l'email
  final String post;
  final EmployeeStatus status;
  final ContractType contractType;
  final DateTime startDate;
  final DateTime? endDate;
  final String address;
  final String phone;
  final String maritalStatus;
  final int childrenCount;
  final String emergencyContact;
  final bool isResigned;
  final double yearlyVacationDays;
  final double yearlyRttDays;
  final String? entityId;
  final double? baseSalary;

  Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.post,
    required this.status,
    required this.contractType,
    required this.startDate,
    this.endDate,
    required this.address,
    required this.phone,
    required this.maritalStatus,
    this.childrenCount = 0,
    required this.emergencyContact,
    this.isResigned = false,
    this.yearlyVacationDays = 25.0,
    this.yearlyRttDays = 0.0,
    this.entityId,
    this.baseSalary,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'],
      post: json['post'] ?? '',
      status: EmployeeStatus.values.firstWhere((e) => e.toString().split('.').last == json['status'], orElse: () => EmployeeStatus.salarie),
      contractType: ContractType.values.firstWhere((e) => e.toString().split('.').last == json['contractType'], orElse: () => ContractType.cdi),
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      maritalStatus: json['maritalStatus'] ?? 'Célibataire',
      childrenCount: json['childrenCount'] ?? 0,
      emergencyContact: json['emergencyContact'] ?? '',
      isResigned: json['isResigned'] ?? false,
      yearlyVacationDays: (json['yearlyVacationDays'] as num?)?.toDouble() ?? 25.0,
      yearlyRttDays: (json['yearlyRttDays'] as num?)?.toDouble() ?? 0.0,
      entityId: json['entityId'],
      baseSalary: (json['baseSalary'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'post': post,
    'status': status.toString().split('.').last,
    'contractType': contractType.toString().split('.').last,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'address': address,
    'phone': phone,
    'maritalStatus': maritalStatus,
    'childrenCount': childrenCount,
    'emergencyContact': emergencyContact,
    'isResigned': isResigned,
    'yearlyVacationDays': yearlyVacationDays,
    'yearlyRttDays': yearlyRttDays,
    'entityId': entityId,
    'baseSalary': baseSalary,
  };
}

class Absence {
  final String id;
  final String employeeId;
  final DateTime startDate;
  final DateTime endDate;
  final String type;
  final String comment;
  final bool isHalfDay;

  Absence({
    required this.id,
    required this.employeeId,
    required this.startDate,
    required this.endDate,
    required this.type,
    this.comment = '',
    this.isHalfDay = false,
  });

  factory Absence.fromJson(Map<String, dynamic> json) {
    return Absence(
      id: json['id']?.toString() ?? '',
      employeeId: json['employeeId'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      type: json['type'] ?? 'Congé',
      comment: json['comment'] ?? '',
      isHalfDay: json['isHalfDay'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employeeId': employeeId,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'type': type,
    'comment': comment,
    'isHalfDay': isHalfDay,
  };

  double get durationDays {
    if (isHalfDay) return 0.5;
    int days = 0;
    for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
      DateTime d = startDate.add(Duration(days: i));
      if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) {
        days++;
      }
    }
    return days.toDouble();
  }
}

class HRDocument {
  final String id;
  final String employeeId;
  final String title;
  final DateTime date;
  final String type;
  final String? fileName;
  final String? filePath;

  HRDocument({
    required this.id,
    required this.employeeId,
    required this.title,
    required this.date,
    required this.type,
    this.fileName,
    this.filePath,
  });

  factory HRDocument.fromJson(Map<String, dynamic> json) {
    return HRDocument(
      id: json['id']?.toString() ?? '',
      employeeId: json['employeeId'] ?? '',
      title: json['title'] ?? '',
      date: DateTime.parse(json['date']),
      type: json['type'] ?? 'Autre',
      fileName: json['fileName'],
      filePath: json['filePath'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employeeId': employeeId,
    'title': title,
    'date': date.toIso8601String(),
    'type': type,
    'fileName': fileName,
    'filePath': filePath,
  };
}
