import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Avatars {
  // Define constants for icon colors
  static const Color burgerColor = Color(0xFFFFA500);
  static const Color pizzaColor = Color(0xFFFF0000);
  static const Color appleColor = Color(0xFF32CD32);
  static const Color iceCreamColor = Color(0xFFFFC0CB);
  static const Color carrotColor = Color(0xFFFF8C00);
  static const Color fishColor = Color(0xFF4682B4);
  static const Color lemonColor = Color(0xFFFFD700);
  static const Color coffeeColor = Color(0xFF6F4F37);
  static const Color cakeColor = Color(0xFFFFC0CB);
  static const Color hotdogColor = Color(0xFFFFD700);

  static Widget getAvatarIcon(String iconName, {double? size = 24}) {
    switch (iconName) {
      case 'burger':
        return FaIcon(
          FontAwesomeIcons.burger,
          size: size,
          color: burgerColor,
        );
      case 'pizza':
        return FaIcon(
          FontAwesomeIcons.pizzaSlice,
          size: size,
          color: pizzaColor,
        );
      case 'apple':
        return FaIcon(
          FontAwesomeIcons.appleWhole,
          size: size,
          color: appleColor,
        );
      case 'iceCream':
        return FaIcon(
          FontAwesomeIcons.iceCream,
          size: size,
          color: iceCreamColor,
        );
      case 'carrot':
        return FaIcon(
          FontAwesomeIcons.carrot,
          size: size,
          color: carrotColor,
        );
      case 'fish':
        return FaIcon(
          FontAwesomeIcons.fish,
          size: size,
          color: fishColor,
        );
      case 'lemon':
        return FaIcon(
          FontAwesomeIcons.solidLemon,
          size: size,
          color: lemonColor,
        );
      case 'coffee':
        return FaIcon(
          FontAwesomeIcons.mugSaucer,
          size: size,
          color: coffeeColor,
        );
      case 'cake':
        return FaIcon(
          FontAwesomeIcons.cakeCandles,
          size: size,
          color: cakeColor,
        );
      case 'hotdog':
        return FaIcon(
          FontAwesomeIcons.hotdog,
          size: size,
          color: hotdogColor,
        );
      default:
        return Builder(
          builder: (context) => FaIcon(
            FontAwesomeIcons.utensils,
            size: size,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
    }
  }
}
