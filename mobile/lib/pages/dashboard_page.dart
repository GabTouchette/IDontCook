import 'package:flutter/material.dart';
import 'package:mobile/components/navbar.dart';
import 'package:mobile/pages/ai_chatbot_page.dart';
import 'package:mobile/pages/recipes_page.dart';

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
      default:
        return const Center(child: Text('Page Not Found'));
    }
  }
}
