import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendService {
  static const String baseUrl = 'http://10.0.2.2:3000';

  static Future<void> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Backend OK: $data');
      } else {
        print('❌ Backend error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Impossible de joindre le backend: $e');
    }
  }
}

