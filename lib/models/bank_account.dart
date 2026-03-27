class BankAccount {
  final String id;
  String name;
  String rib;
  String iban;
  String swift;
  String currency;
  String bankAddress;

  BankAccount({
    required this.id,
    required this.name,
    required this.rib,
    required this.iban,
    required this.swift,
    required this.currency,
    required this.bankAddress,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      rib: json['rib'] ?? '',
      iban: json['iban'] ?? '',
      swift: json['swift'] ?? '',
      currency: json['currency'] ?? 'EUR',
      bankAddress: json['bankAddress'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'rib': rib,
    'iban': iban,
    'swift': swift,
    'currency': currency,
    'bankAddress': bankAddress,
  };
}
