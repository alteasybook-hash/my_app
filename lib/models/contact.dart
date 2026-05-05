enum ContactType { supplier, client }

class Contact {
  final String id;
  final String name;
  final String address;
  final String email;
  final String accountNumber; // 401 for suppliers, 411 for clients
  final ContactType type;
  final String entityId; // Ajout de l'entité obligatoire

  Contact({
    required this.id,
    required this.name,
    required this.address,
    required this.email,
    required this.accountNumber,
    required this.type,
    required this.entityId,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      email: json['email'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      type: json['type'] == 'client' ? ContactType.client : ContactType.supplier,
      entityId: json['entityId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'email': email,
    'accountNumber': accountNumber,
    'type': type == ContactType.client ? 'client' : 'supplier',
    'entityId': entityId,
  };
}
