import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // L'erreur partira après l'étape 1

Future<void> main() async {
  // 1. Initialisation des bindings Flutter (Indispensable)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Chargement du fichier .env (Pour cacher vos clés)
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('.env chargé avec succès');
  } catch (e) {
    debugPrint('Attention : Fichier .env introuvable : $e');
  }

  // 3. Initialisation de Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialisé avec succès');
  } catch (e) {
    debugPrint('Erreur Firebase : $e');
  }

  // 4. Lancement de l'application
  runApp(const MyApp());
}