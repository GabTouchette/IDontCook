import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile/theme/colors.dart';

class Navbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChanged;

  const Navbar({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onTabChanged,
      backgroundColor: ColorPalette.lightgray,
      selectedItemColor: Colors.black,
      unselectedItemColor: ColorPalette.gray,
      type: BottomNavigationBarType.fixed,
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: FaIcon(FontAwesomeIcons.book),
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: FaIcon(FontAwesomeIcons.solidMessage),
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: FaIcon(FontAwesomeIcons.utensils),
          ),
          label: '',
        ),
      ],
    );
  }
}
