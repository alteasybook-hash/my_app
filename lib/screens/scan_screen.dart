import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/pro_scanner_service.dart';
import '../services/pdp_service.dart';
import '../services/api_service.dart';
import '../models/invoice.dart';
import '../models/supplier.dart';
import '../models/entity.dart';

class ScanScreen extends StatefulWidget {
  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool isLoading = false;
  Map<String, dynamic>? result;
  String? error;
  File? lastScannedFile;
  
  List<Entity> _entities = [];
  String? _selectedEntityId;

  final scanner = ProScannerService();
  final pdp = PdpService();
  final apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadEntities();
  }

  Future<void> _loadEntities() async {
    try {
      final entities = await apiService.fetchEntities();
      setState(() {
        _entities = entities;
        if (_entities.isNotEmpty) _selectedEntityId = _entities.first.id;
      });
    } catch (e) {
      debugPrint("Erreur entités: $e");
    }
  }

  /// Scan via Caméra
  Future<void> startScan() async {
    setState(() {
      isLoading = true;
      error = null;
      result = null;
    });

    try {
      final files = await scanner.scanDocument();
      if (files == null || files.isEmpty) {
        setState(() => isLoading = false);
        return;
      }
      lastScannedFile = files.first;
      await _processWithGemini(lastScannedFile!.path);
    } catch (e) {
      setState(() {
        isLoading = false;
        error = "Erreur Caméra: $e";
      });
    }
  }

  /// Import de fichier (PDF ou Image)
  Future<void> pickFile() async {
    setState(() {
      isLoading = true;
      error = null;
      result = null;
    });

    try {
      FilePickerResult? pickResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (pickResult == null || pickResult.files.single.path == null) {
        setState(() => isLoading = false);
        return;
      }

      lastScannedFile = File(pickResult.files.single.path!);
      await _processWithGemini(lastScannedFile!.path);
    } catch (e) {
      setState(() {
        isLoading = false;
        error = "Erreur Import: $e";
      });
    }
  }

  /// Appel direct à Gemini AI
  Future<void> _processWithGemini(String path) async {
    try {
      final extractedData = await apiService.aiProvider.extractInvoiceDataFromPath(path);
      setState(() {
        if (extractedData.containsKey('error')) {
          error = extractedData['error'];
        } else {
          result = extractedData;
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        error = "Erreur IA Gemini: $e";
      });
    }
  }

  Future<void> sendToPdp() async {
    if (result == null || lastScannedFile == null || _selectedEntityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner une entité avant l'envoi")),
      );
      return;
    }

    setState(() => isLoading = true);

    final invoice = Invoice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      number: result!['invoiceNumber'] ?? 'SANS_NUMERO',
      supplierOrClientName: result!['supplierName'] ?? 'INCONNU',
      amountHT: (result!['amountHT'] as num?)?.toDouble() ?? 0.0,
      tva: (result!['tva'] as num?)?.toDouble() ?? 0.0,
      amountTTC: (result!['amountTTC'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(result!['date'] ?? '') ?? DateTime.now(),
      type: InvoiceType.achat,
      entityId: _selectedEntityId!,
      supplierOrClientId: 'temp',
      currency: result!['currency'] ?? 'EUR',
      siren: result!['siren'],
      vatNumber: result!['vatNumber'],
    );

    final supplier = Supplier(
      id: 'temp',
      name: result!['supplierName'] ?? 'Inconnu',
      address: result!['deliveryAddress'] ?? 'Non spécifiée',
      email: '',
      paymentTerms: '30 jours',
      siret: result!['siren'],
      vatin: result!['vatNumber'],
      entityId: _selectedEntityId!,
    );

    final success = await pdp.transmitToPdp(invoice, supplier, lastScannedFile!);
    setState(() => isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Transmis au PPF via Gemini"), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Intelligent Gemini")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeaderCard(),
            if (isLoading) _buildLoading(),
            if (error != null) _buildError(),
            if (result != null && !isLoading) _buildEntitySelector(),
            if (result != null && !isLoading) _buildResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.blue, size: 40),
            const SizedBox(height: 10),
            const Text("Extraction IA Gemini (PDF & Images)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isLoading ? null : startScan,
              icon: const Icon(Icons.camera_alt),
              label: const Text("SCANNER AVEC CAMÉRA"),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: isLoading ? null : pickFile,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("IMPORTER PDF / IMAGE"),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.all(30.0),
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 15),
          Text("L'IA Gemini analyse votre document...", style: TextStyle(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildEntitySelector() {
    return Card(
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("ENTITÉ RÉCEPTRICE (Obligatoire)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedEntityId,
              isExpanded: true,
              items: _entities.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
              onChanged: (v) => setState(() => _selectedEntityId = v),
              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    return Column(
      children: [
        const SizedBox(height: 20),
        _buildDataSection("Données extraites", [
          _row("Fournisseur", result!['supplierName'], Icons.business),
          _row("N° Facture", result!['invoiceNumber'], Icons.numbers),
          _row("Date", result!['date'], Icons.calendar_today),
          _row("Total TTC", "${result!['amountTTC']} ${result!['currency']}", Icons.payments, bold: true),
        ]),
        const SizedBox(height: 25),
        ElevatedButton.icon(
          onPressed: sendToPdp,
          icon: const Icon(Icons.cloud_upload),
          label: const Text("ENVOYER AU PORTAIL PUBLIC (PPF)"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55)),
        ),
      ],
    );
  }

  Widget _buildDataSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }

  Widget _row(String label, dynamic value, IconData icon, {bool bold = false, Color? color}) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 18),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value?.toString() ?? "Non détecté",
        style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color ?? Colors.black87, fontSize: 14)),
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(child: Text(error!, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
