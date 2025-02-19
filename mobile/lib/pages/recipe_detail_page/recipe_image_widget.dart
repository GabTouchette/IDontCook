import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mobile/theme/colors.dart';

class RecipeImage extends StatelessWidget {
  final String imageUrl;
  final Function onImagePick;

  const RecipeImage(
      {Key? key, required this.imageUrl, required this.onImagePick})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    int imageNumber = (imageUrl.hashCode % 11) + 1;

    return GestureDetector(
      onTap: () => onImagePick(),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            : Container(
                height: 250,
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/images/stock_food_$imageNumber.jpg',
                      fit: BoxFit.cover,
                      height: 250,
                      width: double.infinity,
                    ),
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                        child: Container(),
                      ),
                    ),
                    Center(
                      child: Icon(
                        Icons.image,
                        color: ColorPalette.lightgray,
                        size: 80,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
