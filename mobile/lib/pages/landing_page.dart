import 'package:flutter/material.dart';
import 'package:mobile/api/auth_api.dart';
import '../theme/colors.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final AuthApi _authApi = AuthApi();

  bool _isLoggingIn = true;

  void _handleLogin() async {
    try {
      final username = _usernameController.text;
      final password = _passwordController.text;

      await _authApi.login(username, password);

      Navigator.pushNamed(context, '/recipes');
    } catch (e) {
      print(e);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Login Failed"),
          content: Text("Invalid username or password."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  void _handleRegister() async {
    try {
      final username = _usernameController.text;
      final password = _passwordController.text;
      final email = _emailController.text;

      await _authApi.register(username, email, password);

      Navigator.pushNamed(context, '/recipes');
    } catch (e) {
      print(e);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Registration Failed"),
          content: Text("Failed to register, please try again."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/landing_page_background.png',
            fit: BoxFit.cover,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'ICantCook',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: ColorPalette.offWhite,
                      fontSize: 72,
                      fontWeight: FontWeight.w300,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your culinary companion for effortless meals.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColorPalette.offWhite,
                      fontWeight: FontWeight.w200,
                    ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    if (!_isLoggingIn)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 4),
                        decoration: BoxDecoration(
                          color: ColorPalette.darkergray,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          controller: _emailController,
                          style: TextStyle(
                            color: ColorPalette.offWhite,
                          ),
                          decoration: InputDecoration(
                            icon: const Icon(
                              Icons.email,
                              color: ColorPalette.offWhite,
                            ),
                            hintText: 'Email',
                            hintStyle: TextStyle(
                              color: ColorPalette.placeholdergray,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    if (!_isLoggingIn) const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 4),
                      decoration: BoxDecoration(
                        color: ColorPalette.darkergray,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: _usernameController,
                        style: TextStyle(
                          color: ColorPalette.offWhite,
                        ),
                        decoration: InputDecoration(
                          icon: const Icon(
                            Icons.person,
                            color: ColorPalette.offWhite,
                          ),
                          hintText: _isLoggingIn ? 'Username or email' : 'Username',
                          hintStyle: TextStyle(
                            color: ColorPalette.placeholdergray,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 4),
                      decoration: BoxDecoration(
                        color: ColorPalette.darkergray,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: TextStyle(
                          color: ColorPalette.offWhite,
                        ),
                        decoration: InputDecoration(
                          icon: const Icon(
                            Icons.lock,
                            color: ColorPalette.offWhite,
                          ),
                          hintText: '••••••••••',
                          hintStyle: TextStyle(
                            color: ColorPalette.placeholdergray,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: ElevatedButton(
                  onPressed: _isLoggingIn ? _handleLogin : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.yellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _isLoggingIn ? 'Login' : 'Register',
                    style: TextStyle(
                      fontSize: 18,
                      color: ColorPalette.offBlack,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLoggingIn = !_isLoggingIn;
                  });
                },
                child: Text(
                  _isLoggingIn
                      ? 'Don\'t have an account? Register'
                      : 'Already have an account? Login',
                  style: TextStyle(
                    color: ColorPalette.offWhite,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
