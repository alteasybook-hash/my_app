import 'dart:io';
import 'package:http/http.dart' as http;
import 'factur_x_service.dart';
import '../models/invoice.dart';
import '../models/supplier.dart';

class PdpService {
  final String _pdpEndpoint = "https://api.pdp-expert.fr/v1"; // Exemple de middleware/PDP
  final String _apiKey = "VOTRE_CLE_API_PDP";

  /// Étape 3 : Transmission à une PDP (ou via middleware)
  Future<bool> transmitToPdp(Invoice invoice, Supplier supplier, File invoiceFile) async {
    try {
      // 1. Génération du XML Factur-X
      final facturX = FacturXService();
      final xmlContent = facturX.generateFacturXXml(invoice, supplier);

      // 2. Préparation de l'envoi (Multipart: PDF + XML)
      var request = http.MultipartRequest('POST', Uri.parse('$_pdpEndpoint/transmit'));
      request.headers.addAll({
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'multipart/form-data',
      });

      request.files.add(await http.MultipartFile.fromPath('file', invoiceFile.path));
      request.files.add(http.MultipartFile.fromString(
        'metadata', 
        xmlContent, 
        filename: 'factur-x.xml'
      ));

      // Simulation d'envoi
      print("Envoi vers PDP : ${invoice.number} pour ${supplier.name}");
      // var response = await request.send();
      // return response.statusCode == 200;
      
      await Future.delayed(Duration(seconds: 2)); // Simule latence réseau
      return true;
    } catch (e) {
      print("Erreur transmission PDP: $e");
      return false;
    }
  }
}
