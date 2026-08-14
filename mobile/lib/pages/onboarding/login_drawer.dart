import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/enums/toast_type.dart';
import 'package:i_cant_cook/providers/auth_provider.dart';
import 'package:i_cant_cook/services/haptic_service.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';
import 'package:provider/provider.dart';

class LoginDrawer extends StatefulWidget {
  final VoidCallback onSignUpSuccess;
  final bool initialSignInMode;

  const LoginDrawer({
    super.key,
    required this.onSignUpSuccess,
    this.initialSignInMode = true,
  });

  @override
  State<LoginDrawer> createState() => _LoginDrawerState();
}

class _LoginDrawerState extends State<LoginDrawer>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();

  late AnimationController _shakeController;
  late bool _isSigningIn;
  bool _googleLoading = false;

  static const _lime = Color(0xFFCAFF00);
  static const _btnFg = Color(0xFF0A0A0A);

  @override
  void initState() {
    super.initState();
    _isSigningIn = widget.initialSignInMode;
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
    if (_isSigningIn) {
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
        Navigator.pop(context);
        widget.onSignUpSuccess();
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
        Navigator.pop(context);
        widget.onSignUpSuccess();
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
        Navigator.pop(context);
        widget.onSignUpSuccess();
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
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(sin(_shakeController.value * 3 * pi) * 6, 0),
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(
          // Cap at 95% of the screen; content shorter than this sizes the
          // sheet to fit, so sign-in and sign-up each take only the room
          // their fields need. Scrolling kicks in only past this cap.
          maxHeight: MediaQuery.of(context).size.height * 0.95,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  // ── Handle bar ──
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ── Title ──
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                    child: Text(
                      _isSigningIn ? 'SIGN IN' : 'SIGN UP',
                      key: ValueKey(_isSigningIn),
                      style: GoogleFonts.spaceGrotesk(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Google button ──
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
                  ),
                  const SizedBox(height: 28),

                  // ── Divider ──
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
                  ),
                  const SizedBox(height: 28),

                  // ── Fields Section ──
                  // Email field fades + slides in/out; the surrounding
                  // AnimatedSize smoothly grows/shrinks the sheet to match.
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        alignment: Alignment.topCenter,
                        child: child,
                      ),
                    ),
                    child: _isSigningIn
                        ? const SizedBox(
                            width: double.infinity,
                            key: ValueKey('no-email'),
                          )
                        : Column(
                            key: const ValueKey('email-field'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('EMAIL'),
                              _buildTextField(
                                _emailController,
                                hint: 'your@email.com',
                                icon: Icons.email_outlined,
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                  ),
                  _buildFieldLabel('USERNAME'),
                  _buildTextField(
                    _usernameController,
                    hint: _isSigningIn ? 'Username or email' : 'Username',
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
                  const SizedBox(height: 32),

                  // ── Primary button ──
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      final busy = auth.isLoading && !_googleLoading;
                      return GestureDetector(
                        onTap: (_hasRequiredInput && !(auth.isLoading || _googleLoading))
                            ? () {
                                HapticService.mediumImpact();
                                _isSigningIn
                                    ? _handleLogin(context)
                                    : _handleRegister(context);
                              }
                            : null,
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          color: (_hasRequiredInput && !busy) ? _lime : Colors.grey.shade300,
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
                              : AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                  child: Row(
                                    key: ValueKey(_isSigningIn),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _isSigningIn
                                            ? Icons.login
                                            : Icons.check,
                                        color: _btnFg,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        _isSigningIn
                                            ? 'SIGN IN'
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
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // ── Toggle + New here text (centered) ──
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        Text(
                          _isSigningIn ? 'New here? ' : 'Already have an account? ',
                          style: GoogleFonts.spaceGrotesk(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.55),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticService.selectionClick();
                            setState(() => _isSigningIn = !_isSigningIn);
                          },
                          child: Text(
                            _isSigningIn ? 'Sign up' : 'Sign in',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
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
