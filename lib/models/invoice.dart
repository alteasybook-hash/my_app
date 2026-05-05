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
  kept, draft, pdpReceivedByClient
}

enum PdpStatus {
  none,
  pending,    // En attente
  received,   // Reçu
  confirmed,  // Confirmé
  rejected    // Rejeté
}

class InvoiceItem {
  final String product;
  final double quantity;
  final double unitPriceHT;
  final double tvaRate;

  InvoiceItem({
    required this.product,
    required this.quantity,
    required this.unitPriceHT,
    this.tvaRate = 20.0,
  });

  double get totalHT => quantity * unitPriceHT;
  double get totalTTC => totalHT * (1 + tvaRate / 100);

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      product: json['product'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPriceHT: (json['unitPriceHT'] as num?)?.toDouble() ?? 0.0,
      tvaRate: (json['tvaRate'] as num?)?.toDouble() ?? 20.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'product': product,
    'quantity': quantity,
    'unitPriceHT': unitPriceHT,
    'tvaRate': tvaRate,
  };
}

class Invoice {
  final String id;
  final String number;
  final String? quoteNumber;
  final String supplierOrClientName;
  final String designation;
  final double amountHT;
  final double tva; 
  final double amountTTC;
  final double amountPaid;
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
  final bool isReconciled;
  final DateTime? reconciledDate;
  final String? category;
  final String? reconciliationId;
  final String? paymentTerms;
  final String? linkedQuoteNumber;
  final List<Payment> payments;
  final List<DateTime> reminderDates;
  final String? costCenterCode;
  final List<InvoiceItem> items;
  final String? siren;
  final String? vatNumber;
  final String? address;
  final String? country;
  final String? nomenclatureCode;
  final String? deliveryAddress;
  final bool isArchived;
  final DateTime? archiveDate;
  final String? fileHash;
  final PdpStatus pdpStatus;
  final DateTime? pdpSentDate;
  final String? rejectionReason; // Raison du rejet PDP

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
    this.reminderDates = const [],
    this.costCenterCode,
    this.items = const [],
    this.siren,
    this.vatNumber,
    this.address,
    this.country,
    this.nomenclatureCode,
    this.deliveryAddress,
    this.isArchived = false,
    this.archiveDate,
    this.fileHash,
    this.pdpStatus = PdpStatus.none,
    this.pdpSentDate,
    this.rejectionReason,
  });

  double get totalPaid {
    if (payments.isEmpty) return amountPaid;
    final double sum = payments.fold(0.0, (sum, p) {
      if (currency == 'EUR') return sum + p.amountBaseCurrency;
      if (p.currency == currency) return sum + p.amount;
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
    List<DateTime>? reminderDates,
    String? costCenterCode,
    List<InvoiceItem>? items,
    String? siren,
    String? vatNumber,
    String? address,
    String? country,
    String? nomenclatureCode,
    String? deliveryAddress,
    bool? isArchived,
    DateTime? archiveDate,
    String? fileHash,
    PdpStatus? pdpStatus,
    DateTime? pdpSentDate,
    String? rejectionReason,
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
      reminderDates: reminderDates ?? this.reminderDates,
      costCenterCode: costCenterCode ?? this.costCenterCode,
      items: items ?? this.items,
      siren: siren ?? this.siren,
      vatNumber: vatNumber ?? this.vatNumber,
      address: address ?? this.address,
      country: country ?? this.country,
      nomenclatureCode: nomenclatureCode ?? this.nomenclatureCode,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      isArchived: isArchived ?? this.isArchived,
      archiveDate: archiveDate ?? this.archiveDate,
      fileHash: fileHash ?? this.fileHash,
      pdpStatus: pdpStatus ?? this.pdpStatus,
      pdpSentDate: pdpSentDate ?? this.pdpSentDate,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id']?.toString() ?? '',
      number: json['number'] ?? '',
      quoteNumber: json['quoteNumber'],
      supplierOrClientName: json['supplierName'] ?? json['supplierOrClientName'] ?? 'Inconnu',
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
      reminderDates: (json['reminderDates'] as List?)
          ?.map((d) => DateTime.parse(d))
          .toList() ?? [],
      costCenterCode: json['costCenterCode'],
      items: (json['items'] as List?)?.map((i) => InvoiceItem.fromJson(i)).toList() ?? [],
      siren: json['siren'],
      vatNumber: json['vatNumber'],
      address: json['address'],
      country: json['country'],
      nomenclatureCode: json['nomenclatureCode'],
      deliveryAddress: json['deliveryAddress'],
      isArchived: json['isArchived'] ?? false,
      archiveDate: json['archiveDate'] != null ? DateTime.parse(json['archiveDate']) : null,
      fileHash: json['fileHash'],
      pdpStatus: PdpStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['pdpStatus'],
        orElse: () => PdpStatus.none,
      ),
      pdpSentDate: json['pdpSentDate'] != null ? DateTime.parse(json['pdpSentDate']) : null,
      rejectionReason: json['rejectionReason'],
    );
  }

  String? get supplier => null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'quoteNumber': quoteNumber,
    'supplierOrClientName': supplierOrClientName,
    'designation': designation,
    'amountHT': amountHT,
    'tva': tva,
    'amountTTC': amountTTC,
    'amountPaid': totalPaid,
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
    'reminderDates': reminderDates.map((d) => d.toIso8601String()).toList(),
    'costCenterCode': costCenterCode,
    'items': items.map((i) => i.toJson()).toList(),
    'siren': siren,
    'vatNumber': vatNumber,
    'address': address,
    'country': country,
    'nomenclatureCode': nomenclatureCode,
    'deliveryAddress': deliveryAddress,
    'isArchived': isArchived,
    'archiveDate': archiveDate?.toIso8601String(),
    'fileHash': fileHash,
    'pdpStatus': pdpStatus.toString().split('.').last,
    'pdpSentDate': pdpSentDate?.toIso8601String(),
    'rejectionReason': rejectionReason,
  };
}
