class Task {
  final String id;
  final String title;
  final String deadline; // ISO Date string
  final bool isDone;
  final String userId;
  final String? assignedToId;
  final String? assignedToName;

  Task({
    required this.id,
    required this.title,
    required this.deadline,
    this.isDone = false,
    required this.userId,
    this.assignedToId,
    this.assignedToName,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      deadline: json['deadline'] ?? '',
      isDone: json['isDone'] ?? false,
      userId: json['userId'] ?? '',
      assignedToId: json['assignedToId'],
      assignedToName: json['assignedToName'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'deadline': deadline,
    'isDone': isDone,
    'userId': userId,
    'assignedToId': assignedToId,
    'assignedToName': assignedToName,
  };

  Task copyWith({
    String? id,
    String? title,
    String? deadline,
    bool? isDone,
    String? userId,
    String? assignedToId,
    String? assignedToName,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      deadline: deadline ?? this.deadline,
      isDone: isDone ?? this.isDone,
      userId: userId ?? this.userId,
      assignedToId: assignedToId ?? this.assignedToId,
      assignedToName: assignedToName ?? this.assignedToName,
    );
  }
}
