class Entity {
  final String id;
  final String name;
  final String idNumber;
  final String? vatNumber;
  final String email;
  final String address;
  final String? accountingPlan;
  final String country; // 🔥 un seul pays
  final String? invoicingType; // "pdp" ou "classic"
  final String? pdpProvider;   // "sage", "pennylane"
  final String currency;
  final bool isDefault;
  final String? logoPath;
  final String? phone;

  Entity({
    required this.id,
    required this.name,
    required this.idNumber,
    this.vatNumber,
    required this.email,
    required this.address,
    this.accountingPlan,
    required this.country,
    this.invoicingType,
    this.pdpProvider,
    this.currency = 'EUR',
    this.isDefault = false,
    this.logoPath,
    this.phone,
  });

  factory Entity.fromJson(Map<String, dynamic> json) {
    String country = json['country'] ?? 'France';


    return Entity(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      idNumber: json['idNumber'] ?? '',
      vatNumber: json['vatNumber'],
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      accountingPlan: json['accountingPlan'],
      currency: json['currency'] ?? 'EUR',
      isDefault: json['isDefault'] ?? false,
      logoPath: json['logoPath'],
      phone: json['phone'],
      country: country,
      invoicingType: json['invoicingType'],
      pdpProvider: json['pdpProvider'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'idNumber': idNumber,
    'vatNumber': vatNumber,
    'email': email,
    'address': address,
    'accountingPlan': accountingPlan,
    'currency': currency,
    'isDefault': isDefault,
    'logoPath': logoPath,
    'phone': phone,
    'country': country,
    'invoicingType': invoicingType,
    'pdpProvider': pdpProvider,
  };
}
