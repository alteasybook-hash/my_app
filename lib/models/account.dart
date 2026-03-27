// Dans lib/models/account.dart
class Account {
  final String id;
  final String number;
  final String name;
  final String type;
  final String? accountNumber;
  final String? currency; // <--- AJOUTEZ CETTE LIGNE

  Account({
    required this.id,
    required this.number,
    required this.name,
    required this.type,
    this.accountNumber,
    this.currency, // <--- AJOUTEZ CETTE LIGNE
  });

// N'oubliez pas de mettre à jour factory Account.fromJson et toJson si nécessaire


  factory Account.fromJson(Map<String, dynamic> json) {
    // On récupère le numéro de compte
    String num = json['number']?.toString() ?? '';

    return Account(
      id: json['id']?.toString() ?? '',
      number: num,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      // Si accountNumber est vide dans le JSON, on utilise 'number' ou 'code'
      accountNumber: json['accountNumber']?.toString() ??
          (json['code']?.toString() ?? num),
      currency: json['currency']?.toString(), // <--- AJOUTEZ CETTE LIGNE
    );
  }

  Map<String, dynamic> toJson() =>
      {
        'id': id,
        'number': number,
        'accountNumber': accountNumber ?? number,
        // Sécurité : on met le number si null
        'name': name,
        'type': type,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Account &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              number == other.number;

  @override
  int get hashCode => id.hashCode ^ number.hashCode;

  @override
  String toString() => '$number - $name';

  // Liste par défaut : Vigilance maintenue sur tous les types de comptes
  static List<Account> get defaultAccounts =>
      [
        Account(id: '1',
            number: '601',
            name: 'Achats de matières premières',
            type: 'charge'),
        Account(id: '2',
            number: '606',
            name: 'Achats non stockés (fournitures)',
            type: 'charge'),
        Account(id: '3', number: '613', name: 'Locations', type: 'charge'),
        Account(id: '4',
            number: '615',
            name: 'Entretien et réparations',
            type: 'charge'),
        Account(id: '5',
            number: '616',
            name: 'Primes d\'assurances',
            type: 'charge'),
        Account(id: '6', number: '622', name: 'Honoraires', type: 'charge'),
        Account(id: '7', number: '623', name: 'Publicité', type: 'charge'),
        Account(id: '8',
            number: '625',
            name: 'Déplacements et réceptions',
            type: 'charge'),
        Account(id: '9',
            number: '626',
            name: 'Frais postaux et télécoms',
            type: 'charge'),
        Account(id: '10',
            number: '627',
            name: 'Services bancaires',
            type: 'charge'),
        Account(id: '11',
            number: '701',
            name: 'Ventes de produits finis',
            type: 'produit'),
        Account(id: '12',
            number: '706',
            name: 'Prestations de services',
            type: 'produit'),
        Account(id: '13',
            number: '707',
            name: 'Ventes de marchandises',
            type: 'produit'),
        // LE COMPTE 512 POUR LE RAPPROCHEMENT
        Account(id: '14',
            number: '512',
            name: 'Banque',
            type: 'banque',
            accountNumber: '512000'),
        Account(id: '15', number: '401', name: 'Fournisseurs', type: 'tiers'),
        Account(id: '16', number: '411', name: 'Clients', type: 'tiers'),
      ];

  static List<Account> get allAccounts => defaultAccounts;

  static List<Account> get charges =>
      allAccounts.where((a) => a.type == 'charge').toList();

  static List<Account> get produits =>
      allAccounts.where((a) => a.type == 'produit').toList();
}