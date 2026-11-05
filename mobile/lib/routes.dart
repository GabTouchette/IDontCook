import 'package:flutter/material.dart';
import 'package:i_cant_cook/pages/dashboard_page.dart';
import 'package:i_cant_cook/pages/onboarding/onboarding_page.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  Widget page;
  switch (settings.name) {
    case '/':
    case '/onboarding':
      page = const OnboardingPage();
      break;
    case '/recipes':
      page = const DashboardPage();
      break;
    default:
      page = const OnboardingPage();
  }
  return PageRouteBuilder<dynamic>(
    settings: settings,
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 280),
  );
}
