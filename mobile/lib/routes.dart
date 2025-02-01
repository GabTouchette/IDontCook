import 'package:flutter/material.dart';
import 'package:mobile/pages/dashboard_page.dart';
import 'package:mobile/pages/landing_page.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (_) => const LandingPage());
    case '/recipes' || '/chat':
      return MaterialPageRoute(builder: (_) => const DashboardPage());
    default:
      return MaterialPageRoute(builder: (_) => const LandingPage());
  }
}
