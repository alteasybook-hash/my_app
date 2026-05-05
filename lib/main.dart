import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  // 1. Initialisation des bindings Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Chargement du fichier .env
  try {
    await dotenv.load(fileName: ".env");
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('⚠️ ATTENTION : GEMINI_API_KEY est vide dans le fichier .env');
    } else {
      debugPrint('✅ Clé API détectée (longueur: ${apiKey.length})');
    }
  } catch (e) {
    debugPrint('❌ Erreur lors du chargement du fichier .env : $e');
  }

  // 3. Initialisation de Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialisé avec succès');
  } catch (e) {
    debugPrint('⚠️ Erreur Firebase (Ignorable en local) : $e');
  }

  // 4. Lancement de l'application
  runApp(const MyApp());
}