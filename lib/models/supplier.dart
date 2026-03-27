class Supplier {
  final String id;
  final String name;
  final String address;
  final String email;
  final String expenseAccount;
  final String paymentTerms; // Immediat, 15 jours, 30 jours
  final String? siret;
  final String? vatin; // N° TVA Intra

  Supplier({
    required this.id,
    required this.name,
    required this.address,
    required this.email,
    this.expenseAccount = '401',
    required this.paymentTerms,
    this.siret,
    this.vatin,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      email: json['email'] ?? '',
      expenseAccount: json['expenseAccount'] ?? (json['type'] == 'customer' ? '411' : '401'),
      paymentTerms: json['paymentTerms'] ?? '30 jours',
      siret: json['siret'],
      vatin: json['vatin'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'email': email,
    'expenseAccount': expenseAccount,
    'paymentTerms': paymentTerms,
    'siret': siret,
    'vatin': vatin,
  };
}
