import 'package:flutter/material.dart';
import 'package:i_cant_cook/pages/splash_page.dart';
import 'package:i_cant_cook/pages/login_page.dart';
import 'package:i_cant_cook/pages/dashboard_page.dart';
import 'package:i_cant_cook/pages/onboarding/onboarding_page.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  Widget page;
  switch (settings.name) {
    case '/':
      page = const SplashPage();
      break;
    case '/onboarding':
      page = const OnboardingPage();
      break;
    case '/landing':
      page = const LoginPage();
      break;
    case '/recipes':
    case '/chat':
    case '/recommendations':
    case '/explore':
    case '/meal-plans':
      page = const DashboardPage();
      break;
    default:
      page = const LoginPage();
  }
  return PageRouteBuilder<dynamic>(
    settings: settings,
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 280),
  );
}
