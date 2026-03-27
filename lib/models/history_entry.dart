// lib/models/history_entry.dart

enum HistoryType {
  invoiceAchat,
  invoiceVente,
  quote,
  journal,
  partner,
  supplier,
  customer,
  employee,
  absence,
  hrDocument,
  entity,
  companyDoc,
  report,
  security,
  event
}

enum HistoryAction {
  deleted,
  modified,
  created,
  restored
}

class HistoryEntry {
  final String id;
  final String documentId;
  final String documentNumber;
  final HistoryType type;
  final HistoryAction action;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  HistoryEntry({
    required this.id,
    required this.documentId,
    required this.documentNumber,
    required this.type,
    required this.action,
    required this.timestamp,
    this.data,
  });

  Map<String, dynamic> toJson() =>
      {
        'id': id,
        'documentId': documentId,
        'documentNumber': documentNumber,
        'type': type.index, // Stocke l'index (0, 1, 2...)
        'action': action.index,
        'timestamp': timestamp.toIso8601String(),
        'data': data,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) =>
      HistoryEntry(
        id: json['id'],
        documentId: json['documentId'],
        documentNumber: json['documentNumber'],
        // On récupère l'Enum à partir de l'index stocké
        type: HistoryType.values[json['type']],
        action: HistoryAction.values[json['action']],
        timestamp: DateTime.parse(json['timestamp']),
        data: json['data'],
      );
}