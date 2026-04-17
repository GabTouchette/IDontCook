import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:i_cant_cook/models/user/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

class AuthApi {
  static const _userKey = 'user_data';
  static const _tokenKey = 'auth_token';

  /// LOGIN
  Future<User> login(String username, String password) async {
    try {
      final url = ApiConfig.buildApiUri('accounts/login/');
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
        final Map<String, dynamic> userJson = responseData['user'];

        final user = User(
          id: userJson['id'],
          username: userJson['username'],
          email: userJson['email'],
          token: token,
          avatar_icon: userJson['avatar_icon'] ?? '',
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_userKey, json.encode(user.toJson()));

        return user;
      } else {
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  /// REGISTER
  Future<User> register(String username, String email, String password) async {
    try {
      final url = ApiConfig.buildApiUri('accounts/register/');
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
        final Map<String, dynamic> userJson = responseData['user'];

        final user = User(
          id: userJson['id'],
          username: userJson['username'],
          email: userJson['email'],
          token: token,
          avatar_icon: userJson['avatar_icon'] ?? '',
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_userKey, json.encode(user.toJson()));

        return user;
      } else {
        throw Exception('Failed to register: ${response.body}');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  /// GET CURRENT USER FROM LOCAL STORAGE
  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString(_userKey);
    final String? token = prefs.getString(_tokenKey);

    if (userJson != null && token != null) {
      final Map<String, dynamic> data = json.decode(userJson);
      return User(
        id: data['id'],
        username: data['username'],
        email: data['email'],
        token: token,
        avatar_icon: data['avatar_icon'] ?? '',
      );
    }
    return null;
  }

  /// LOGOUT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
  }

  /// GET AUTH HEADERS
  static Future<Map<String, String>> getAuthHeader() async {
    final user = await getUser();
    if (user != null && user.token != null) {
      return {
        'Authorization': 'Token ${user.token}',
        'Content-Type': 'application/json',
      };
    } else {
      return {'Content-Type': 'application/json'};
    }
  }
}
