import 'package:flutter/material.dart';
import 'package:i_cant_cook/pages/social_page.dart';
import 'package:i_cant_cook/pages/explore_page.dart';
import 'package:i_cant_cook/widgets/navbar.dart';
import 'package:i_cant_cook/pages/ai_chatbot_page.dart';
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
      body: _getBody(),
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
        return const RecipesPage();
      case 1:
        return const AiChatBotPage();
      case 2:
        return ExplorePage();
      case 3:
        return const MealPlanPage();
      case 4:
        return const SocialPage();
      default:
        return const Center(child: Text('Page Not Found'));
    }
  }
}
