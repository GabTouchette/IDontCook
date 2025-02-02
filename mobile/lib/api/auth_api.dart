import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/api/api_helper.dart';
import 'package:mobile/models/user.dart';

class AuthApi {
  final ApiHelper _apiHelper = ApiHelper();

  Future<User?> login(String username, String password) async {
    final response = await _apiHelper.postRequest(
      'auth/login/',
      {'username': username, 'password': password},
    );

    if (response != null && response['key'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', response['key']);

      return User.fromJsonWithUsername(response, username);
    } else {
      throw Exception('Failed to login');
    }
  }

  Future<void> register(String username, String email, String password) async {
    final response = await _apiHelper.postRequest(
      'auth/registration/',
      {
        'username': username,
        'email': email,
        'password1': password,
        'password2': password
      },
    );

    if (response == null) {
      throw Exception('Failed to register');
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}
