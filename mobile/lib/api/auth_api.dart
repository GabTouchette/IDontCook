import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthApi {
  final String _baseUrl = 'http://192.168.0.110:8000';

  Future<void> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/api/login/');
    final response = await http.post(
      url,
      body: {
        'username': username,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final String token = responseData['token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  Future<void> register(String username, String email, String password) async {
    final url = Uri.parse('$_baseUrl/api/register/');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final String token = responseData['token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<Map<String, String>> getAuthHeader() async {
    final token = await getToken();
    return {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
    };
  }
}
