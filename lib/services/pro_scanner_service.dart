import 'dart:io';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class ProScannerService {
  Future<List<File>?> scanDocument() async {
    try {
      // 1. Vérification et demande des permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
      ].request();

      if (statuses[Permission.camera] != PermissionStatus.granted) {
        throw Exception("Permission not granted");
      }

      // 2. Lancement du scanner
      List<String>? pictures = await CunningDocumentScanner.getPictures();
      
      if (pictures != null && pictures.isNotEmpty) {
        return pictures.map((path) => File(path)).toList();
      }
      return null;
    } catch (e) {
      print("Error scanning document: $e");
      rethrow; // On renvoie l'erreur pour qu'elle soit gérée par l'UI
    }
  }
}
