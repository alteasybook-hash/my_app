import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthService {
  // Adresse IP de votre Mac pour l'émulateur Android
  static const String baseUrl = 'http://10.0.2.2:3000';

  // Fonction pour se connecter
  Future<User?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Succès : NestJS renvoie les données de l'utilisateur et le token
        final Map<String, dynamic> data = jsonDecode(response.body);
        return User.fromJson(data);
      } else {
        print('❌ Échec de connexion : ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Erreur réseau lors de la connexion : $e');
      return null;
    }
  }

  // Fonction pour s'inscrire (Optionnel pour le MVP)
  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
