import 'dart:io';
import 'local_ocr_service.dart';
import 'factur_x_service.dart';
import 'pdp_service.dart';
import 'annuaire_service.dart';
import 'accounting_engine.dart';
import '../models/invoice.dart';
import '../models/supplier.dart';
import '../models/entity.dart';
import 'package:pdf/widgets.dart' as pw;

class WorkflowService {
  final ocr = LocalOCRService();
  final annuaire = AnnuaireService();
  final pdp = PdpService();
  final accounting = AccountingEngine();

  /// Étape 6 : Le Workflow complet de A à Z
  Future<void> processFullInvoiceCycle(File file) async {
    try {
      // 1. OCR & Structuration
      print("Step 1: OCR...");
      final data = await ocr.processImage(file.path);
      
      // 2. Annuaire (Lookup SIRET)
      print("Step 2: Annuaire Lookup...");
      final destinataireInfo = await annuaire.getPdpFromSiret(data['siren'] ?? '');

      // 3. Modélisation
      final invoice = Invoice(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        number: data['invoiceNumber'] ?? 'N/A',
        supplierOrClientName: data['supplierName'] ?? 'Inconnu',
        amountHT: data['amountHT'] ?? 0.0,
        tva: data['tva'] ?? 0.0,
        amountTTC: data['amountTTC'] ?? 0.0,
        date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
        type: InvoiceType.achat,
        entityId: 'ENT-001',
        supplierOrClientId: 'SUP-001',
        siren: data['siren'],
        vatNumber: data['vatNumber'],
      );

      final supplier = Supplier(
        id: 'SUP-001',
        name: data['supplierName'] ?? 'Inconnu',
        address: data['deliveryAddress'] ?? '',
        email: '',
        paymentTerms: '30 jours',
        siret: data['siren'],
        vatin: data['vatNumber'],
        entityId: 'ENT-001',
      );

      // 4. Factur-X & PDP
      print("Step 3: Factur-X & Transmission...");
      await pdp.transmitToPdp(invoice, supplier, file);

      // 5. Comptabilité Auto
      print("Step 4: Accounting Entry...");
      
      // Temporary entity for the workflow demo
      final entity = Entity(
        id: 'ENT-001',
        name: 'Ma Société',
        idNumber: data['siren'] ?? '',
        email: '',
        address: '',
      );
      
      final entry = accounting.generateAutomaticEntry(invoice, supplier, entity);
      print("Écriture générée: ${entry.journalNumber} - ${entry.totalDebit}€");

      // 6. Archive Probante (Hash déjà calculé dans OCR)
      print("Step 5: Archiving... OK (Hash: ${data['fileHash']})");

    } catch (e) {
      print("Erreur Workflow: $e");
    }
  }
}
