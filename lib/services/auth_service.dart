import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mathsolver/globals.dart';

class AuthService {
  static String baseUrl = '${Globals.httpURI}/user';

  static Future<Map<String, dynamic>> signUp(
    String username,
    String email,
    String password,
    String confirmPassword,
  ) async {
    try {
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
    } catch (e) {
      print('SignUp error: $e');
      return {'success': false, 'message': 'Signup failed. Please try again.'};
    }
  }

  static Future<Map<String, dynamic>> signIn(
    String email,
    String password,
  ) async {
    try {
      Globals.email = email;

      final response = await http.post(
        Uri.parse('$baseUrl/signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final result = jsonDecode(response.body);

      // Safely update global values
      Globals.userId = result['userId'] ?? "0";
      Globals.username = result['username'] ?? "User";
      Globals.profileImg = result['profileImg'];

      return result;
    } catch (e) {
      print('SignIn error: $e');
      return {
        'success': false,
        'message': 'Signin failed. Please check your credentials.',
      };
    }
  }

  static void signout() {
    Globals.username = null;
    Globals.token = null;
    Globals.userId = "0";
    Globals.email = null;
    Globals.profileImg = null;
  }
}
