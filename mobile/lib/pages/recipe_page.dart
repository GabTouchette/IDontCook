import 'package:flutter/material.dart';
import 'package:mobile/models/ingredient.dart';
import 'package:mobile/theme/colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RecipePage extends StatefulWidget {
  final String imageUrl;
  final String title;
  final int? preparationTime;
  final int? cookingTime;
  final List<Ingredient>? ingredients;
  final List<String>? instructions;

  const RecipePage({
    Key? key,
    required this.imageUrl,
    required this.title,
    this.preparationTime,
    this.cookingTime,
    required this.ingredients,
    required this.instructions,
  }) : super(key: key);

  @override
  _RecipePageState createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  List<bool> completedInstructions = [];

  @override
  void initState() {
    super.initState();
    completedInstructions =
        List<bool>.filled(widget.instructions?.length ?? 0, false);
  }

  @override
  Widget build(BuildContext context) {
    print(widget.instructions);
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: ColorPalette.offWhite,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.chevron_left,
            size: 32,
            color: ColorPalette.offWhite,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const FaIcon(
              FontAwesomeIcons.heart,
              color: ColorPalette.offWhite,
            ),
          ),
          const Padding(padding: EdgeInsets.only(right: 8.0)),
          IconButton(
            onPressed: () {},
            icon: const FaIcon(
              FontAwesomeIcons.share,
              color: ColorPalette.offWhite,
            ),
          ),
          const Padding(padding: EdgeInsets.only(right: 16.0)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: widget.imageUrl.isNotEmpty
                  ? Image.network(
                      widget.imageUrl,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey[700],
                      height: 250,
                      width: double.infinity,
                      child: const Icon(
                        Icons.image,
                        color: Colors.white,
                        size: 80,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  if (widget.preparationTime != null) ...[
                    const Icon(Icons.timer, size: 20, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Prep: ${widget.preparationTime} min',
                      style:
                          TextStyle(color: ColorPalette.offWhite, fontSize: 16),
                    ),
                  ],
                  if (widget.preparationTime != null &&
                      widget.cookingTime != null)
                    const SizedBox(width: 16),
                  if (widget.cookingTime != null) ...[
                    const Icon(Icons.local_fire_department,
                        size: 20, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Cook: ${widget.cookingTime} min',
                      style:
                          TextStyle(color: ColorPalette.offWhite, fontSize: 16),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Ingredients",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (widget.ingredients ?? []).map((ingredient) {
                  String formattedIngredient =
                      "${ingredient.quantity ?? ''} ${ingredient.unit_of_measure ?? ''} ${ingredient.name ?? ''}"
                          .trim();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      "- $formattedIngredient",
                      style:
                          TextStyle(color: ColorPalette.offWhite, fontSize: 16),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Instructions",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    List.generate(widget.instructions?.length ?? 0, (index) {
                  final isCompleted = completedInstructions[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        completedInstructions[index] = !isCompleted;
                      });
                    },
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              completedInstructions[index] = !isCompleted;
                            });
                          },
                          child: const SizedBox(height: 12),
                        ),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor:
                                  isCompleted ? Colors.green : Colors.grey,
                              child: isCompleted
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 16)
                                  : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.instructions![index],
                                style: TextStyle(
                                  color: isCompleted
                                      ? Colors.green
                                      : ColorPalette.offWhite,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.grey),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
