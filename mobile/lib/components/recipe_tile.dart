import 'package:flutter/material.dart';
import 'package:mobile/models/ingredient.dart';
import 'package:mobile/pages/recipe_detail_page.dart';
import 'package:mobile/theme/colors.dart';

class RecipeTile extends StatelessWidget {
  final int id;
  final String imageUrl;
  final String title;
  final int? preparationTime;
  final int? cookingTime;
  final List<Ingredient>? ingredients;
  final List<String>? instructions;
  final List<String>? tags;

  const RecipeTile({
    Key? key,
    required this.id,
    required this.imageUrl,
    required this.title,
    this.preparationTime,
    this.cookingTime,
    required this.ingredients,
    required this.instructions,
    this.tags,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipePage(
              id: id,
              imageUrl: imageUrl,
              title: title,
              preparationTime: preparationTime,
              cookingTime: cookingTime,
              ingredients: ingredients,
              instructions: instructions,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: ColorPalette.lightgray,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            height: 80,
                            width: 80,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: ColorPalette.offWhite,
                            height: 80,
                            width: 80,
                            child: const Icon(
                              Icons.image,
                              color: ColorPalette.offBlack,
                              size: 40,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: ColorPalette.offBlack,
                            fontSize: 20,
                            fontWeight: FontWeight.w300,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4.0),
                        Row(
                          children: [
                            if (preparationTime != null) ...[
                              const Icon(Icons.timer,
                                  size: 16, color: ColorPalette.offBlack),
                              const SizedBox(width: 4),
                              Text(
                                '$preparationTime min',
                                style: TextStyle(color: ColorPalette.offBlack),
                              ),
                            ],
                            if (preparationTime != null && cookingTime != null)
                              const SizedBox(width: 12),
                            if (cookingTime != null) ...[
                              const Icon(Icons.local_fire_department,
                                  size: 16, color: ColorPalette.offBlack),
                              const SizedBox(width: 4),
                              Text(
                                '$cookingTime min',
                                style: TextStyle(color: ColorPalette.offBlack),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              if (tags != null && tags!.isNotEmpty) ...[
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: tags!.map((tag) {
                    return Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: ColorPalette.darkgray,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tag,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 6.0),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
