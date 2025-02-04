import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/models/user.dart';
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
      final Map<String, dynamic> user = responseData['user'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setInt('user_id', user['id']);
      await prefs.setString('username', user['username']);
      await prefs.setString('email', user['email']);
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
      final Map<String, dynamic> user = responseData['user'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setInt('user_id', user['id']);
      await prefs.setString('username', user['username']);
      await prefs.setString('email', user['email']);
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    int? id = prefs.getInt('user_id');
    String? username = prefs.getString('username');
    String? email = prefs.getString('email');
    String? token = prefs.getString('auth_token');

    if (id != null && username != null && email != null) {
      return User(id: id, username: username, email: email, token: token);
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('email');
  }

  static Future<Map<String, String>> getAuthHeader() async {
    final user = await getUser();
    return {
      'Authorization': 'Token ${user?.token}',
      'Content-Type': 'application/json',
    };
  }
}
