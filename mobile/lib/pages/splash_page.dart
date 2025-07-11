import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/auth_api.dart';
import 'package:i_cant_cook/models/user/user.dart';
import 'package:i_cant_cook/theme/colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1800)); // Wait for fade
    final User? user = await AuthApi.getUser();

    if (mounted) {
      if (user != null) {
        Navigator.pushReplacementNamed(context, '/recipes');
      } else {
        Navigator.pushReplacementNamed(context, '/landing');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.offBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/landing_page_background.png',
            fit: BoxFit.cover,
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ICantCook',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: ColorPalette.offWhite,
                          fontSize: 64,
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
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
