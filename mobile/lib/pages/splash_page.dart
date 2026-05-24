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
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    final User? user = await AuthApi.getUser();

    if (mounted) {
      if (user != null) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/recipes', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(
            context, '/landing', (route) => false);
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFF0A0A0A);
    const Color lime = Color(0xFFCAFF00);
    const Color offWhite = Color(0xFFF5F4EF);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: bg,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Center content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo
                    Image.asset(
                      'assets/images/icon.png',
                      width: 140,
                      height: 140,
                    ),

                    const SizedBox(height: 28),

                    // App name
                    Text(
                      'IDONTCOOK',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: offWhite,
                        letterSpacing: 4,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Subtitle
                    Text(
                      'your culinary companion',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: offWhite.withValues(alpha: 0.45),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom loading bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  backgroundColor: offWhite.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation<Color>(lime),
                  minHeight: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

