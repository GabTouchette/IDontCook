import 'package:flutter/material.dart';
import 'package:i_cant_cook/pages/social_page.dart';
import 'package:i_cant_cook/pages/explore_page.dart';
import 'package:i_cant_cook/widgets/navbar.dart';
import 'package:i_cant_cook/pages/home_page.dart';
import 'package:i_cant_cook/pages/recipes_page.dart';
import 'package:i_cant_cook/pages/meal_plan_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: _getBody(),
        ),
      ),
      bottomNavigationBar: Navbar(
        selectedIndex: _selectedIndex,
        onTabChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return const HomePage();
      case 1:
        return ExplorePage();
      case 2:
        return RecipesPage(
          onNavigateToTab: (index) => setState(() => _selectedIndex = index),
        );
      case 3:
        return const SocialPage();
      case 4:
        return const MealPlanPage();
      default:
        return const Center(child: Text('Page Not Found'));
    }
  }
}
