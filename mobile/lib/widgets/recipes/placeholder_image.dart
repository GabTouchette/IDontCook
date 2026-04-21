import 'dart:ui';

import 'package:flutter/material.dart';

class PlaceholderImageWidget extends StatelessWidget {
  final int recipeId;
  final int height;

  const PlaceholderImageWidget({required this.recipeId, this.height = 120});

  @override
  Widget build(BuildContext context) {
    int imageNumber = (recipeId % 11) + 1;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      height: height.toDouble(),
      width: height.toDouble(),
      child: Stack(children: [
        Image.asset(
          'assets/images/stock_food_$imageNumber.jpg',
          fit: BoxFit.cover,
          height: height.toDouble(),
          width: height.toDouble(),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
            ),
          ),
        ),
        Center(
          child: Icon(
            Icons.image,
            color:
                Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.9),
            size: 50,
          ),
        ),
      ]),
    );
  }
}
