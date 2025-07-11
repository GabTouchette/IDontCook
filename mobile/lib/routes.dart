import 'package:flutter/material.dart';
import 'package:i_cant_cook/pages/splash_page.dart';
import 'package:i_cant_cook/pages/landing_page.dart';
import 'package:i_cant_cook/pages/dashboard_page.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (_) => const SplashPage());

    case '/landing':
      return MaterialPageRoute(builder: (_) => const LandingPage());

    case '/recipes':
    case '/chat':
    case '/recommendations':
    case '/explore':
      return MaterialPageRoute(builder: (_) => const DashboardPage());

    default:
      return MaterialPageRoute(builder: (_) => const LandingPage());
  }
}
