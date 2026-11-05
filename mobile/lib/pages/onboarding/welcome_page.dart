import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingWelcomePage extends StatefulWidget {
  final VoidCallback onContinueWithGoogle;
  final VoidCallback onContinueWithEmail;
  final bool googleLoading;

  const OnboardingWelcomePage({
    super.key,
    required this.onContinueWithGoogle,
    required this.onContinueWithEmail,
    this.googleLoading = false,
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
    final lime = Theme.of(context).colorScheme.secondary;
    final black = Theme.of(context).colorScheme.onSecondary;
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
                  color: lime.withValues(alpha: 0.35),
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
                        color: lime,
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
                    // CONTINUE WITH GOOGLE (primary — works for new & returning)
                    GestureDetector(
                      onTap:
                          widget.googleLoading ? null : widget.onContinueWithGoogle,
                      child: Container(
                        height: 52,
                        color: lime,
                        child: widget.googleLoading
                            ? Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: black,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FaIcon(FontAwesomeIcons.google,
                                      color: black, size: 16),
                                  const SizedBox(width: 12),
                                  Text(
                                    'CONTINUE WITH GOOGLE',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: black,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // CONTINUE WITH EMAIL (secondary — opens the auth sheet)
                    Center(
                      child: GestureDetector(
                        onTap: widget.onContinueWithEmail,
                        child: Text(
                          'Continue with email',
                          style: GoogleFonts.spaceGrotesk(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            decoration: TextDecoration.underline,
                          ),
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
