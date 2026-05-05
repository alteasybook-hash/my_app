import '../models/invoice.dart';
import '../models/journal_entry.dart';
import '../models/supplier.dart';
import '../models/entity.dart';

class AccountingEngine {
  /// Génère l'écriture comptable automatique basée sur la configuration de l'entité
  JournalEntry generateAutomaticEntry(Invoice invoice, Supplier partner, Entity entity) {
    List<JournalLine> lines = [];
    bool isPurchase = invoice.type == InvoiceType.achat;

    // 1. Ligne de charge ou produit (6xx ou 7xx)
    String mainAccount = isPurchase 
        ? (invoice.expenseAccount ?? entity.defaultPurchaseAccount ?? '601')
        : (invoice.expenseAccount ?? entity.defaultSaleAccount ?? '707');

    lines.add(JournalLine(
      accountCode: mainAccount,
      description: "${isPurchase ? 'Achat' : 'Vente'} ${partner.name} - Facture ${invoice.number}",
      debit: isPurchase ? invoice.amountHT : 0.0,
      credit: isPurchase ? 0.0 : invoice.amountHT,
    ));

    // 2. Ligne de TVA (44566 ou 44571)
    if (invoice.tva > 0) {
      String vatAccount = isPurchase 
          ? (entity.defaultVatReceivableAccount ?? '44566')
          : (entity.defaultVatPayableAccount ?? '44571');
          
      lines.add(JournalLine(
        accountCode: vatAccount,
        description: "TVA sur facture ${invoice.number}",
        debit: isPurchase ? invoice.tva : 0.0,
        credit: isPurchase ? 0.0 : invoice.tva,
      ));
    }

    // 3. Ligne de Tiers (401 ou 411)
    String tierPrefix = isPurchase 
        ? (entity.defaultSupplierAccountPrefix ?? '401')
        : (entity.defaultCustomerAccountPrefix ?? '411');
    
    // On utilise souvent les 3 premières lettres du nom pour le compte auxiliaire si non défini
    String auxAccount = partner.expenseAccount.length > 3 
        ? partner.expenseAccount 
        : "$tierPrefix${partner.name.replaceAll(' ', '').substring(0, 3).toUpperCase()}";

    lines.add(JournalLine(
      accountCode: auxAccount,
      description: "Facture ${invoice.number} - ${partner.name}",
      debit: isPurchase ? 0.0 : invoice.amountTTC,
      credit: isPurchase ? invoice.amountTTC : 0.0,
    ));

    return JournalEntry(
      id: "JE-${DateTime.now().millisecondsSinceEpoch}",
      entityId: invoice.entityId,
      journalNumber: isPurchase ? "AC" : "VE",
      date: invoice.date,
      reference: invoice.number,
      lines: lines,
      currency: invoice.currency,
    );
  }
  
  /// Exporte en format FEC (Fichier des Écritures Comptables) - Standard DGFIP
  String exportToFec(List<JournalEntry> entries) {
    StringBuffer fec = StringBuffer();
    fec.writeln("JournalCode\tJournalLib\tEcritureNum\tEcritureDate\tCompteNum\tCompteLib\tCompAuxNum\tCompAuxLib\tPieceRef\tPieceDate\tEcritureLib\tDebit\tCredit\tEcritureLet\tDateLet\tValidDate\tMontantdevise\tIdevise");
    
    for (var entry in entries) {
      for (var line in entry.lines) {
        String journalLib = entry.journalNumber == "AC" ? "ACHATS" : (entry.journalNumber == "VE" ? "VENTES" : "OD");
        fec.writeln("${entry.journalNumber}\t$journalLib\t${entry.id}\t${entry.date.toIso8601String().split('T')[0]}\t${line.accountCode}\t${line.description}\t\t\t${entry.reference}\t${entry.date.toIso8601String().split('T')[0]}\t${line.description}\t${line.debit.toStringAsFixed(2).replaceAll('.', ',')}\t${line.credit.toStringAsFixed(2).replaceAll('.', ',')}\t\t\t\t\t");
      }
    }
    return fec.toString();
  }
}
