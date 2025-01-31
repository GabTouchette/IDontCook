import 'package:flutter/material.dart';
import 'package:mobile/pages/landing_page.dart';
import 'package:mobile/pages/recipes_page.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (_) => const LandingPage());
    case '/recipes':
      return MaterialPageRoute(builder: (_) => const RecipesPage());
    default:
      return MaterialPageRoute(builder: (_) => const LandingPage());
  }
}
