import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:i_cant_cook/providers/auth_provider.dart';
import 'package:i_cant_cook/services/haptic_service.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';
import 'welcome_page.dart';
import 'login_drawer.dart';
import 'profile_setup_page.dart';

// TEMP: surface the raw Google auth error in the toast regardless of build
// mode (Xcode Release runs have kDebugMode == false). Set back to false — or
// revert to the kDebugMode gate — once the google-auth issue is diagnosed.
const bool _debugGoogleAuth = true;

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _pageIndex = 0;
  bool _googleLoading = false;

  /// Returning user (existing account) → straight into the app.
  void _routeToApp() {
    Navigator.pushReplacementNamed(context, '/recipes');
  }

  /// Brand-new account → run the one-time profile-setup step.
  void _goToProfileSetup() {
    setState(() => _pageIndex = 1);
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/recipes');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _googleLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.signInWithGoogle();
      if (mounted) _routeToApp();
    } catch (e) {
      if (mounted) {
        HapticService.notificationError();
        InformationToast.error(
          context,
          (kDebugMode || _debugGoogleAuth)
              ? 'Google sign-in failed: $e'
              : 'Google sign-in failed. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  void _showEmailSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LoginDrawer(
        // The drawer closes itself, then we route by what happened:
        // an existing sign-in goes to the app; a fresh account gets setup.
        onAuthSuccess: ({required bool isNewAccount}) {
          if (isNewAccount) {
            _goToProfileSetup();
          } else {
            _routeToApp();
          }
        },
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_pageIndex) {
      case 1:
        return OnboardingProfileSetupPage(
          key: const ValueKey(1),
          onComplete: _completeOnboarding,
        );
      default:
        return OnboardingWelcomePage(
          key: const ValueKey(0),
          googleLoading: _googleLoading,
          onContinueWithGoogle: _handleGoogleSignIn,
          onContinueWithEmail: _showEmailSheet,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, animation) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeOut);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.03, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
        child: _buildCurrentPage(),
      ),
    );
  }
}
