import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_page.dart';
import '../login_page.dart';
import 'profile_setup_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _pageIndex = 0;
  bool _signInMode = false;

  void _advanceToAuth({required bool signInMode}) {
    setState(() {
      _signInMode = signInMode;
      _pageIndex = 1;
    });
  }

  void _onAuthSuccess({required bool isNewUser}) {
    if (isNewUser) {
      setState(() => _pageIndex = 2);
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/recipes');
    }
  }

  Widget _buildCurrentPage() {
    switch (_pageIndex) {
      case 1:
        return LoginPage(
          key: const ValueKey(1),
          initialSignInMode: _signInMode,
          onAuthSuccess: _onAuthSuccess,
        );
      case 2:
        return OnboardingProfileSetupPage(
          key: const ValueKey(2),
          onComplete: _completeOnboarding,
        );
      default:
        return OnboardingWelcomePage(
          key: const ValueKey(0),
          onGetStarted: () => _advanceToAuth(signInMode: false),
          onSignIn: () => _advanceToAuth(signInMode: true),
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
