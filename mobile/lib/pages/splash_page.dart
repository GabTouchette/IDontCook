import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/api/auth_api.dart';
import 'package:i_cant_cook/models/user/user.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;

  int _typeChars = 0;
  static const _splashText = "I CAN'T COOK";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 700), _startTyping);
    _checkAuth();
  }

  Future<void> _startTyping() async {
    for (int i = 0; i < _splashText.length; i++) {
      await Future.delayed(const Duration(milliseconds: 75));
      if (!mounted) return;
      setState(() => _typeChars = i + 1);
    }
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    final User? user = await AuthApi.getUser();
    if (mounted) {
      if (user != null) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/recipes', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(
            context, '/onboarding', (route) => false);
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
    const Color lime = Color(0xFFCAFF00);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: FadeTransition(
          opacity: _fade,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _scale,
                      child: Image.asset(
                        'assets/images/icon.png',
                        width: 96,
                        height: 96,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      _splashText.substring(0, _typeChars),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4.0,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom progress line
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      lime.withValues(alpha: 0.5)),
                  minHeight: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
