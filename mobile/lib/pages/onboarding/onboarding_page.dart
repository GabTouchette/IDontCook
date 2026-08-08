import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_page.dart';
import 'login_drawer.dart';
import 'profile_setup_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _pageIndex = 0;

  void _onAuthSuccess() {
    setState(() => _pageIndex = 1);
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/recipes');
    }
  }

  void _showLoginDrawer({required bool isSignIn}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LoginDrawer(
        initialSignInMode: isSignIn,
        onSignUpSuccess: _onAuthSuccess,
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
          onGetStarted: () => _showLoginDrawer(isSignIn: false),
          onSignIn: () => _showLoginDrawer(isSignIn: true),
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
