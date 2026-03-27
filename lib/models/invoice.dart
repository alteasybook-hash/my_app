import 'package:my_app/models/payment.dart';

enum InvoiceType { achat, vente }

enum InvoiceStatus {
  pending,
  waitingValidation,
  validated,
  partiallyPaid,
  paid,
  rejected,
  deleted,
  extourned,
  kept, draft
}

class Invoice {
  final String id;
  final String number;
  final String? quoteNumber;
  final String supplierOrClientName;
  final String designation;
  final double amountHT;
  final double tva; // Taux de TVA
  final double amountTTC;
  final double amountPaid; // Montant historiquement payé (champ de base)
  final String currency;
  final DateTime date;
  final DateTime? dueDate;
  final InvoiceType type;
  final InvoiceStatus status;
  final String entityId;
  final String? assignedValidator;
  final String? expenseAccount;
  final String supplierOrClientId;
  final String? bankAccountId;
  final DateTime? paymentDate;
  final String? paymentMethod;
  final bool isReconciled; // Signifie "Matché" avec une transaction
  final DateTime? reconciledDate;
  final String? category;
  final String? reconciliationId; // ID du rapprochement mensuel finalisé
  final String? paymentTerms; // Immédiat, 15 jours, 30 jours
  final String? linkedQuoteNumber;
  final List<Payment> payments;

  Invoice({
    required this.id,
    required this.number,
    this.quoteNumber,
    required this.supplierOrClientName,
    this.designation = '',
    required this.amountHT,
    required this.tva,
    required this.amountTTC,
    this.amountPaid = 0,
    this.currency = 'EUR',
    required this.date,
    this.dueDate,
    required this.type,
    this.status = InvoiceStatus.pending,
    required this.entityId,
    this.assignedValidator,
    this.expenseAccount,
    required this.supplierOrClientId,
    this.bankAccountId,
    this.paymentDate,
    this.paymentMethod,
    this.isReconciled = false,
    this.reconciledDate,
    this.category,
    this.reconciliationId,
    this.paymentTerms,
    this.linkedQuoteNumber,
    this.payments = const [],
  });

  /// Calcule le total payé en cumulant la liste des paiements détaillés avec conversion
  double get totalPaid {
    if (payments.isEmpty) return amountPaid;
    
    final double sum = payments.fold(0.0, (sum, p) {
      // 1. Si la facture est en EUR (devise de base de la comptabilité)
      // On utilise le montant converti du paiement (amountBaseCurrency)
      if (currency == 'EUR') {
        return sum + p.amountBaseCurrency;
      }
      
      // 2. Si le paiement est dans la même devise que la facture (ex: Facture USD, Paiement USD)
      if (p.currency == currency) {
        return sum + p.amount;
      }
      
      // 3. Cas complexe : Facture en USD, Paiement en GBP.
      // Dans ce cas, on devrait techniquement convertir le montant base (EUR) vers la devise facture.
      // Pour l'instant, on simplifie en prenant le montant converti si Invoice n'est pas EUR mais Paiement l'est.
      return sum + p.amountBaseCurrency;
    });
    
    return double.parse(sum.toStringAsFixed(2));
  }

  double get remainingAmount {
    final res = amountTTC - totalPaid;
    return res > 0.001 ? double.parse(res.toStringAsFixed(2)) : 0.0;
  }
  
  bool get isPaid => remainingAmount <= 0.01;

  Invoice copyWith({
    String? id,
    String? number,
    String? quoteNumber,
    String? supplierOrClientName,
    String? designation,
    double? amountHT,
    double? tva,
    double? amountTTC,
    double? amountPaid,
    String? currency,
    DateTime? date,
    DateTime? dueDate,
    InvoiceType? type,
    InvoiceStatus? status,
    String? entityId,
    String? assignedValidator,
    String? expenseAccount,
    String? supplierOrClientId,
    String? bankAccountId,
    DateTime? paymentDate,
    String? paymentMethod,
    bool? isReconciled,
    DateTime? reconciledDate,
    String? category,
    String? reconciliationId,
    String? paymentTerms,
    String? linkedQuoteNumber,
    List<Payment>? payments,
  }) {
    return Invoice(
      id: id ?? this.id,
      number: number ?? this.number,
      quoteNumber: quoteNumber ?? this.quoteNumber,
      supplierOrClientName: supplierOrClientName ?? this.supplierOrClientName,
      designation: designation ?? this.designation,
      amountHT: amountHT ?? this.amountHT,
      tva: tva ?? this.tva,
      amountTTC: amountTTC ?? this.amountTTC,
      amountPaid: amountPaid ?? this.amountPaid,
      currency: currency ?? this.currency,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      type: type ?? this.type,
      status: status ?? this.status,
      entityId: entityId ?? this.entityId,
      assignedValidator: assignedValidator ?? this.assignedValidator,
      expenseAccount: expenseAccount ?? this.expenseAccount,
      supplierOrClientId: supplierOrClientId ?? this.supplierOrClientId,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isReconciled: isReconciled ?? this.isReconciled,
      reconciledDate: reconciledDate ?? this.reconciledDate,
      category: category ?? this.category,
      reconciliationId: reconciliationId ?? this.reconciliationId,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      linkedQuoteNumber: linkedQuoteNumber ?? this.linkedQuoteNumber,
      payments: payments ?? this.payments,
    );
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id']?.toString() ?? '',
      number: json['number'] ?? '',
      quoteNumber: json['quoteNumber'],
      supplierOrClientName: json['supplierOrClientName'] ?? '',
      designation: json['designation'] ?? '',
      amountHT: double.tryParse(json['amountHT']?.toString() ?? '0') ?? 0,
      tva: double.tryParse(json['tva']?.toString() ?? '0') ?? 0,
      amountTTC: double.tryParse(json['amountTTC']?.toString() ?? '0') ?? 0,
      amountPaid: double.tryParse(json['amountPaid']?.toString() ?? '0') ?? 0,
      currency: json['currency'] ?? 'EUR',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      type: json['type'] == 'vente' ? InvoiceType.vente : InvoiceType.achat,
      status: InvoiceStatus.values.firstWhere(
            (e) => e.toString().split('.').last == json['status'],
        orElse: () => InvoiceStatus.pending,
      ),
      entityId: json['entityId'] ?? '',
      assignedValidator: json['assignedValidator'],
      expenseAccount: json['expenseAccount'],
      supplierOrClientId: json['supplierOrClientId'] ?? '',
      bankAccountId: json['bankAccountId'],
      paymentDate: json['paymentDate'] != null ? DateTime.parse(json['paymentDate']) : null,
      paymentMethod: json['paymentMethod'],
      isReconciled: json['isReconciled'] ?? false,
      reconciledDate: json['reconciledDate'] != null ? DateTime.parse(json['reconciledDate']) : null,
      category: json['category'],
      reconciliationId: json['reconciliationId'],
      paymentTerms: json['paymentTerms'],
      linkedQuoteNumber: json['linkedQuoteNumber'],
      payments: (json['payments'] as List?)
          ?.map((p) => Payment.fromJson(p))
          .toList() ?? [],
    );
  }

  String? get comment => null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'quoteNumber': quoteNumber,
    'supplierOrClientName': supplierOrClientName,
    'designation': designation,
    'amountHT': amountHT,
    'tva': tva,
    'amountTTC': amountTTC,
    'amountPaid': totalPaid, // On sauvegarde le total réel calculé
    'currency': currency,
    'date': date.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'type': type.toString().split('.').last,
    'status': status.toString().split('.').last,
    'entityId': entityId,
    'assignedValidator': assignedValidator,
    'expenseAccount': expenseAccount,
    'supplierOrClientId': supplierOrClientId,
    'bankAccountId': bankAccountId,
    'paymentDate': paymentDate?.toIso8601String(),
    'paymentMethod': paymentMethod,
    'isReconciled': isReconciled,
    'reconciledDate': reconciledDate?.toIso8601String(),
    'category': category,
    'reconciliationId': reconciliationId,
    'paymentTerms': paymentTerms,
    'linkedQuoteNumber': linkedQuoteNumber,
    'payments': payments.map((p) => p.toJson()).toList(),
  };
}
