import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingWelcomePage extends StatefulWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  const OnboardingWelcomePage({
    super.key,
    required this.onGetStarted,
    required this.onSignIn,
  });

  @override
  State<OnboardingWelcomePage> createState() => _OnboardingWelcomePageState();
}

class _OnboardingWelcomePageState extends State<OnboardingWelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFade;
  late Animation<double> _subtitleFade;
  late Animation<double> _btnFade;

  int _typeChars = 0;
  static const _headline1 = "I CAN'T";
  static const _headline2 = 'COOK.';

  String get _line1Text =>
      _headline1.substring(0, _typeChars.clamp(0, _headline1.length));
  String get _line2Text => _headline2.substring(
      0, (_typeChars - _headline1.length).clamp(0, _headline2.length));

  static const _lime = Color(0xFFCAFF00);
  static const _black = Color(0xFF0A0A0A);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.30, curve: Curves.easeOut),
    );
    _subtitleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.74, 0.88, curve: Curves.easeOut),
    );
    _btnFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.88, 1.0, curve: Curves.easeOut),
    );
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 300), _startTyping);
  }

  Future<void> _startTyping() async {
    // Fast-type line 1 "I CAN'T"
    for (int i = 0; i < _headline1.length; i++) {
      await Future.delayed(const Duration(milliseconds: 35));
      if (!mounted) return;
      setState(() => _typeChars++);
    }
    // Dramatic pause before COOK.
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    // Slower type for dramatic effect on COOK.
    for (int i = 0; i < _headline2.length; i++) {
      await Future.delayed(const Duration(milliseconds: 65));
      if (!mounted) return;
      setState(() => _typeChars++);
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              // ── Logo mark ──
              FadeTransition(
                opacity: _logoFade,
                child: Image.asset(
                  'assets/images/icon.png',
                  width: 64,
                  height: 64,
                ),
              ),
              const SizedBox(height: 20),
              // ── Lime rule ──
              FadeTransition(
                opacity: _logoFade,
                child: Container(
                  height: 1,
                  color: _lime.withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(height: 20),
              // ── Headline (typewriter) ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _line1Text,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.5,
                      height: 1.0,
                    ),
                  ),
                  Container(
                    color: _typeChars >= _headline1.length
                        ? const Color(0xFF0A0A0A)
                        : Colors.transparent,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text(
                      _line2Text.isEmpty ? '\u00A0' : _line2Text,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 76,
                        fontWeight: FontWeight.w700,
                        color: _lime,
                        letterSpacing: -2.5,
                        height: 0.92,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _subtitleFade,
                    child: Text(
                      'YOUR CULINARY COMPANION',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.28),
                        letterSpacing: 2.5,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 3),
              // ── Buttons ──
              FadeTransition(
                opacity: _btnFade,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // GET STARTED
                    GestureDetector(
                      onTap: widget.onGetStarted,
                      child: Container(
                        height: 52,
                        color: _lime,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.arrow_forward,
                                color: _black, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              'GET STARTED',
                              style: GoogleFonts.spaceGrotesk(
                                color: _black,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
