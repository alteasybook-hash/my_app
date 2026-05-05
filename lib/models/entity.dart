class Entity {
  final String id;
  final String name;
  final String idNumber;
  final String? vatNumber;
  final String email;
  final String address;
  final String? accountingPlan;
  final String country;
  final String? invoicingType; // "pdp", "classic", etc.
  final String? invoicingConfigId; // Link to a specific config in settings
  final List<String> currencies;
  final bool isDefault;
  final String? logoPath;
  final String? phone;

  // Default accounts for automatic accounting
  final String? defaultSaleAccount; // e.g., "707"
  final String? defaultPurchaseAccount; // e.g., "607"
  final String? defaultVatPayableAccount; // e.g., "44571"
  final String? defaultVatReceivableAccount; // e.g., "44566"
  final String? defaultCustomerAccountPrefix; // e.g., "411"
  final String? defaultSupplierAccountPrefix; // e.g., "401"

  // Getter for compatibility with parts of the app expecting a single currency
  String get currency => currencies.isNotEmpty ? currencies.first : 'EUR';

  Entity({
    required this.id,
    required this.name,
    required this.idNumber,
    this.vatNumber,
    required this.email,
    required this.address,
    this.accountingPlan,
    this.country = 'France',
    this.invoicingType,
    this.invoicingConfigId,
    this.currencies = const ['EUR'],
    this.isDefault = false,
    this.logoPath,
    this.phone,
    this.defaultSaleAccount = '707',
    this.defaultPurchaseAccount = '601',
    this.defaultVatPayableAccount = '44571',
    this.defaultVatReceivableAccount = '44566',
    this.defaultCustomerAccountPrefix = '411',
    this.defaultSupplierAccountPrefix = '401',
  });

  factory Entity.fromJson(Map<String, dynamic> json) {
    String country = 'France';
    if (json['country'] != null) {
      country = json['country'];
    } else if (json['countries'] != null && (json['countries'] as List).isNotEmpty) {
      country = json['countries'][0];
    }

    List<String> currencies = ['EUR'];
    if (json['currencies'] != null) {
      currencies = List<String>.from(json['currencies']);
    } else if (json['currency'] != null) {
      currencies = [json['currency']];
    }

    return Entity(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      idNumber: json['idNumber'] ?? '',
      vatNumber: json['vatNumber'],
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      accountingPlan: json['accountingPlan'],
      country: country,
      invoicingType: json['invoicingType'],
      invoicingConfigId: json['invoicingConfigId'],
      currencies: currencies,
      isDefault: json['isDefault'] ?? false,
      logoPath: json['logoPath'],
      phone: json['phone'],
      defaultSaleAccount: json['defaultSaleAccount'] ?? '707',
      defaultPurchaseAccount: json['defaultPurchaseAccount'] ?? '601',
      defaultVatPayableAccount: json['defaultVatPayableAccount'] ?? '44571',
      defaultVatReceivableAccount: json['defaultVatReceivableAccount'] ?? '44566',
      defaultCustomerAccountPrefix: json['defaultCustomerAccountPrefix'] ?? '411',
      defaultSupplierAccountPrefix: json['defaultSupplierAccountPrefix'] ?? '401',
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
    'country': country,
    'invoicingType': invoicingType,
    'invoicingConfigId': invoicingConfigId,
    'currencies': currencies,
    'isDefault': isDefault,
    'logoPath': logoPath,
    'phone': phone,
    'defaultSaleAccount': defaultSaleAccount,
    'defaultPurchaseAccount': defaultPurchaseAccount,
    'defaultVatPayableAccount': defaultVatPayableAccount,
    'defaultVatReceivableAccount': defaultVatReceivableAccount,
    'defaultCustomerAccountPrefix': defaultCustomerAccountPrefix,
    'defaultSupplierAccountPrefix': defaultSupplierAccountPrefix,
  };
}

class InvoicingConfig {
  final String id;
  final String name; // Name of the configuration (e.g. "Sage Production")
  final String country;
  final String provider; // "sage", "pennylane", "chorus", etc.
  final String? apiKey;
  final String? apiSecret;
  final String? endpoint;

  InvoicingConfig({
    required this.id,
    required this.name,
    required this.country,
    required this.provider,
    this.apiKey,
    this.apiSecret,
    this.endpoint,
  });

  factory InvoicingConfig.fromJson(Map<String, dynamic> json) {
    return InvoicingConfig(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      provider: json['provider'] ?? '',
      apiKey: json['apiKey'],
      apiSecret: json['apiSecret'],
      endpoint: json['endpoint'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'country': country,
    'provider': provider,
    'apiKey': apiKey,
    'apiSecret': apiSecret,
    'endpoint': endpoint,
  };
}
