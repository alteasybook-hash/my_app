enum ContactType { supplier, client }

class Contact {
  final String id;
  final String name;
  final String address;
  final String email;
  final String accountNumber; // 401 for suppliers, 411 for clients
  final ContactType type;

  Contact({
    required this.id,
    required this.name,
    required this.address,
    required this.email,
    required this.accountNumber,
    required this.type,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      email: json['email'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      type: json['type'] == 'client' ? ContactType.client : ContactType.supplier,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    'email': email,
    'accountNumber': accountNumber,
    'type': type == ContactType.client ? 'client' : 'supplier',
  };
}
