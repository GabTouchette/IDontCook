import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:i_cant_cook/api/auth_api.dart';
import 'package:i_cant_cook/models/user/user.dart';

class AuthProvider with ChangeNotifier {
  final AuthApi _authApi = AuthApi();
  bool _isLoading = false;
  User? _currentUser;

  bool get isLoading => _isLoading;
  User? get currentUser => _currentUser;

  AuthProvider() {
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    final user = await AuthApi.getUser();
    if (user != null) {
      _currentUser = user;
      notifyListeners();
    }
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authApi.login(username, password);
      _currentUser = user;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authApi.register(username, email, password);
      _currentUser = user;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authApi.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final googleSignIn = GoogleSignIn(
        clientId: '42379090918-2sskh09gan77b97k71668vqpc9nk0dh7.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );
      final account = await googleSignIn.signIn();
      if (account == null) throw Exception('Google sign-in cancelled');

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) throw Exception('Failed to obtain Google ID token');

      final user = await _authApi.googleAuthWithIdToken(idToken);
      _currentUser = user;
    } catch (e, st) {
      debugPrint('signInWithGoogle failed: $e');
      debugPrint('$st');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
