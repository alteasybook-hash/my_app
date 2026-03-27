enum PaymentType { client, fournisseur }
enum PaymentStatus { pending, matched }

class Payment {
  final String id;

  // --- Gestion Multi-Devise ---
  final double amount;              // Montant dans la devise de la transaction (ex: USD)
  final String currency;            // Code devise (ex: 'USD', 'EUR')
  final double exchangeRate;        // Taux de change par rapport à la devise de base
  final double amountBaseCurrency;  // Montant stocké en devise de base (ex: EUR) pour la compta

  final DateTime date;
  final String method;              // Virement, Carte, Chèque, etc.
  final String linkedInvoiceId;     // ID de la facture associée
  final PaymentType type;           // Client (Entrée) ou Fournisseur (Sortie)
  final String bankAccountId;       // Compte bancaire concerné
  final String accountCode;         // Code comptable (ex: 512000)
  final PaymentStatus status;       // pending (à rapprocher) ou matched (rapproché)

  // --- Catégorisation ---
  final String paymentCategory;    // "facture", "partiel", "acompte"

  Payment({
    required this.id,
    required this.amount,
    this.currency = 'EUR',
    this.exchangeRate = 1.0,
    required this.amountBaseCurrency,
    required this.date,
    required this.method,
    required this.linkedInvoiceId,
    required this.type,
    this.bankAccountId = '',
    this.accountCode = '512000',
    this.status = PaymentStatus.pending,
    this.paymentCategory = "facture",
  });

  /// Indique si ce paiement doit figurer dans la page de Rapprochement Bancaire
  /// (Généralement si le compte utilisé est un compte de banque 512)
  bool get needsReconciliation => accountCode.startsWith("512") && status == PaymentStatus.pending;

  /// Factory pour créer un objet Payment à partir d'un JSON (API ou Local)
  factory Payment.fromJson(Map<String, dynamic> json) {
    // Calcul automatique de la devise de base si absente du JSON
    double amt = (json['amount'] as num?)?.toDouble() ?? 0.0;
    double rate = (json['exchangeRate'] as num?)?.toDouble() ?? 1.0;
    double amtBase = (json['amountBaseCurrency'] as num?)?.toDouble() ?? (amt * rate);

    return Payment(
      id: json['id']?.toString() ?? '',
      amount: amt,
      currency: json['currency'] ?? 'EUR',
      exchangeRate: rate,
      amountBaseCurrency: amtBase,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      method: json['method'] ?? 'Virement',
      linkedInvoiceId: json['linkedInvoiceId'] ?? '',
      type: json['type'] == 'client' ? PaymentType.client : PaymentType.fournisseur,
      bankAccountId: json['bankAccountId'] ?? '',
      accountCode: json['accountCode'] ?? '512000',
      paymentCategory: json['paymentCategory'] ?? 'facture',
      status: json['status'] == 'matched' ? PaymentStatus.matched : PaymentStatus.pending,
    );
  }

  /// Conversion de l'objet en Map pour le stockage
  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'currency': currency,
    'exchangeRate': exchangeRate,
    'amountBaseCurrency': amountBaseCurrency,
    'date': date.toIso8601String(),
    'method': method,
    'linkedInvoiceId': linkedInvoiceId,
    'type': type == PaymentType.client ? 'client' : 'fournisseur',
    'bankAccountId': bankAccountId,
    'accountCode': accountCode,
    'paymentCategory': paymentCategory,
    'status': status == PaymentStatus.matched ? 'matched' : 'pending',
  };

  /// Permet de copier l'objet en modifiant certains champs (ex: lors du rapprochement)
  Payment copyWith({
    PaymentStatus? status,
    String? bankAccountId,
    double? amountBaseCurrency,
  }) {
    return Payment(
      id: this.id,
      amount: this.amount,
      currency: this.currency,
      exchangeRate: this.exchangeRate,
      amountBaseCurrency: amountBaseCurrency ?? this.amountBaseCurrency,
      date: this.date,
      method: this.method,
      linkedInvoiceId: this.linkedInvoiceId,
      type: this.type,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      accountCode: this.accountCode,
      paymentCategory: this.paymentCategory,
      status: status ?? this.status,
    );
  }
}