import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/enums/toast_type.dart';
import 'package:i_cant_cook/providers/auth_provider.dart';
import 'package:i_cant_cook/services/haptic_service.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  final void Function({required bool isNewUser})? onAuthSuccess;
  final bool initialSignInMode;

  const LoginPage({
    super.key,
    this.onAuthSuccess,
    this.initialSignInMode = true,
  });

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();

  late AnimationController _shakeController;

  late bool _isLoggingIn;
  bool _googleLoading = false;

  static const _lime = Color(0xFFCAFF00);
  static const _btnFg = Color(0xFF0A0A0A); // always black on lime button

  @override
  void initState() {
    super.initState();
    _isLoggingIn = widget.initialSignInMode;
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _usernameController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  bool get _hasRequiredInput {
    if (_isLoggingIn) {
      return _usernameController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
    }
    return _emailController.text.isNotEmpty &&
        _usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty;
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _usernameController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _emailController.removeListener(_onFieldChanged);
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleGoogleSignIn(BuildContext context) async {
    setState(() => _googleLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.signInWithGoogle();
      if (context.mounted) {
        widget.onAuthSuccess != null
            ? widget.onAuthSuccess!(isNewUser: true)
            : Navigator.pushNamed(context, '/recipes');
      }
    } catch (e) {
      if (context.mounted) {
        HapticService.notificationError();
        _shakeController.forward(from: 0);
        InformationToast.show(
          context: context,
          message: 'Google sign-in failed. Please try again.',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  void _handleLogin(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.login(
          _usernameController.text, _passwordController.text);
      if (context.mounted) {
        widget.onAuthSuccess != null
            ? widget.onAuthSuccess!(isNewUser: false)
            : Navigator.pushNamed(context, '/recipes');
      }
    } catch (e) {
      if (context.mounted) {
        HapticService.notificationError();
        _shakeController.forward(from: 0);
        InformationToast.show(
          context: context,
          message: 'Invalid username or password.',
          type: ToastType.error,
        );
      }
    }
  }

  void _handleRegister(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.register(_usernameController.text,
          _emailController.text, _passwordController.text);
      if (context.mounted) {
        widget.onAuthSuccess != null
            ? widget.onAuthSuccess!(isNewUser: true)
            : Navigator.pushNamed(context, '/recipes');
      }
    } catch (e) {
      if (context.mounted) {
        HapticService.notificationError();
        _shakeController.forward(from: 0);
        InformationToast.show(
          context: context,
          message: 'Failed to register. Please try again.',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(sin(_shakeController.value * 3 * pi) * 6, 0),
                child: child,
              );
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Logo ──
                  Row(
                    children: [
                      Image.asset('assets/images/icon.png',
                          width: 48, height: 48),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'I DON\'T COOK',
                            style: GoogleFonts.spaceGrotesk(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            'YOUR CULINARY COMPANION',
                            style: GoogleFonts.spaceGrotesk(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.4),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms).slideY(
                      begin: -0.07, duration: 400.ms, curve: Curves.easeOut),
                  const SizedBox(height: 36),
                  // ── Google button (primary) ──
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return GestureDetector(
                        onTap: (auth.isLoading || _googleLoading)
                            ? null
                            : () => _handleGoogleSignIn(context),
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          color: _lime,
                          child: _googleLoading
                              ? const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: _btnFg,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FaIcon(
                                      FontAwesomeIcons.google,
                                      size: 16,
                                      color: _btnFg,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'CONTINUE WITH GOOGLE',
                                      style: GoogleFonts.spaceGrotesk(
                                        color: _btnFg,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ).animate(delay: 90.ms).fadeIn(duration: 350.ms),
                  const SizedBox(height: 28),
                  // ── OR divider ──
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.3),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: GoogleFonts.spaceGrotesk(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.35),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.3),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ).animate(delay: 120.ms).fadeIn(duration: 350.ms),
                  const SizedBox(height: 28),
                  // ── Mode toggle ──
                  Row(
                    children: [
                      _buildModeTab('LOGIN', _isLoggingIn),
                      const SizedBox(width: 1),
                      _buildModeTab('REGISTER', !_isLoggingIn),
                    ],
                  ).animate(delay: 150.ms).fadeIn(duration: 350.ms),
                  const SizedBox(height: 32),
                  // ── Fields ──
                  if (!_isLoggingIn) ...[
                    _buildFieldLabel('EMAIL'),
                    _buildTextField(
                      _emailController,
                      hint: 'your@email.com',
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 20),
                  ],
                  _buildFieldLabel('USERNAME'),
                  _buildTextField(
                    _usernameController,
                    hint: _isLoggingIn ? 'Username or email' : 'Username',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 20),
                  _buildFieldLabel('PASSWORD'),
                  _buildTextField(
                    _passwordController,
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    obscure: true,
                  ),
                  // ── Primary button — slides in when fields are filled ──
                  AnimatedSize(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOut,
                    child: _hasRequiredInput
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 32),
                              Consumer<AuthProvider>(
                                builder: (context, auth, _) {
                                  final busy = auth.isLoading && !_googleLoading;
                                  return GestureDetector(
                                    onTap: (auth.isLoading || _googleLoading)
                                        ? null
                                        : () {
                                            HapticService.mediumImpact();
                                            _isLoggingIn
                                                ? _handleLogin(context)
                                                : _handleRegister(context);
                                          },
                                    child: Container(
                                      width: double.infinity,
                                      height: 52,
                                      color: _lime,
                                      child: busy
                                          ? const Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  color: _btnFg,
                                                  strokeWidth: 2.5,
                                                ),
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.check,
                                                    color: _btnFg, size: 18),
                                                const SizedBox(width: 10),
                                                Text(
                                                  _isLoggingIn
                                                      ? 'LOGIN'
                                                      : 'CREATE ACCOUNT',
                                                  style: GoogleFonts.spaceGrotesk(
                                                    color: _btnFg,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 1.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeTab(String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticService.selectionClick();
          setState(() => _isLoggingIn = (label == 'LOGIN'));
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 40,
          color: active
              ? _lime
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: active
                    ? _btnFg
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.55),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(width: 16, height: 1.5, color: _lime),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.spaceGrotesk(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: _lime,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.spaceGrotesk(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          icon,
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
          size: 20,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
              width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _lime, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}
