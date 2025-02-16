import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mobile/theme/colors.dart';

class PlaceholderImageWidget extends StatelessWidget {
  final int recipeId;
  final int height;

  const PlaceholderImageWidget({required this.recipeId, this.height = 120});

  @override
  Widget build(BuildContext context) {
    int imageNumber = (recipeId % 11) + 1;

    return Container(
      color: ColorPalette.offWhite,
      height: height.toDouble(),
      width: height.toDouble(),
      child: Stack(
        children: [
          Image.asset(
            'assets/images/stock_food_$imageNumber.jpg',
            fit: BoxFit.cover,
            height: height.toDouble(),
            width: height.toDouble(),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(),
            ),
          ),
          const Center(
            child: Icon(
              Icons.image,
              color: ColorPalette.lightgray,
              size: 50,
            ),
          ),
        ],
      ),
    );
  }
}
