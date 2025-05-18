//

// auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mathsolver/globals.dart'; // Import the globals.dart file to access the global variable

class AuthService {
  static const String baseUrl =
      'https://abfa-2401-4900-3316-384f-7c0a-b8cb-2ff4-d6c4.ngrok-free.app/auth';

  static Future<Map<String, dynamic>> signUp(
    String username,
    String email,
    String password,
    String confirmPassword,
  ) async {
    // Set the global username
    Globals.username = username;

    final response = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> signIn(
    String username,
    String password,
  ) async {
    // Set the global username
    Globals.username = username;

    final response = await http.post(
      Uri.parse('$baseUrl/signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> signout() async {
    final response = await http.post(
      Uri.parse('$baseUrl/signout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': Globals.username}),
    );
    // After signing out, you can clear the global username if needed
    Globals.username = null;
    Globals.token = null;
    return jsonDecode(response.body);
  }
}
