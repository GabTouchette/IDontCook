import 'package:flutter/material.dart';
import 'package:mobile/api/recipe_api.dart';
import 'package:mobile/widgets/dialogs/confirmation_dialog.dart';
import 'package:mobile/models/ingredient.dart';
import 'package:mobile/pages/update_recipe_page.dart';
import 'package:mobile/theme/colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RecipePage extends StatefulWidget {
  final int id;
  final String imageUrl;
  final String title;
  final int? preparationTime;
  final int? cookingTime;
  final List<Ingredient>? ingredients;
  final List<String>? instructions;
  final String? description;
  final String? notes;
  final List<String>? tags;

  const RecipePage({
    Key? key,
    required this.id,
    required this.imageUrl,
    required this.title,
    this.preparationTime,
    this.cookingTime,
    required this.ingredients,
    required this.instructions,
    this.description,
    this.notes,
    this.tags,
  }) : super(key: key);

  @override
  _RecipePageState createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  List<bool> completedInstructions = [];
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    completedInstructions =
        List<bool>.filled(widget.instructions?.length ?? 0, false);
    isSaved = widget.id != -1;
  }

  void _saveRecipe() async {
    if (widget.id == -1) {
      Map<String, dynamic> recipeData = {
        "title": widget.title,
        "ingredients": widget.ingredients
            ?.map((ingredient) => {
                  "name": ingredient.name,
                  "quantity": ingredient.quantity,
                  "unit_of_measure": ingredient.unit_of_measure,
                })
            .toList(),
        "instructions": widget.instructions,
        "preparation_time": widget.preparationTime,
        "cooking_time": widget.cookingTime,
        "description": widget.description,
        "notes": widget.notes,
        "tags": widget.tags,
      };

      bool success = await RecipeApi().createRecipe(recipeData);

      if (success) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(success ? 'Recipe Submitted' : 'Submission Failed'),
            content: Text(success
                ? 'Your recipe has been successfully submitted!'
                : 'There was an error submitting your recipe.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (success) Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          if (isSaved) ...[
            IconButton(
              onPressed: () {},
              icon: const FaIcon(
                FontAwesomeIcons.heart,
                color: ColorPalette.offWhite,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdateRecipePage(recipeId: widget.id),
                  ),
                );
              },
              icon: const FaIcon(
                FontAwesomeIcons.pen,
                color: ColorPalette.offWhite,
              ),
            ),
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => ConfirmationDialog(
                    message: "Are you sure you want to delete this recipe?",
                    onConfirm: () async {
                      Navigator.pop(context);
                      bool success = await RecipeApi().deleteRecipe(widget.id);
                      if (success) {
                        Navigator.pop(context);
                      }
                    },
                    onCancel: () {
                      Navigator.pop(context);
                    },
                  ),
                );
              },
              icon: const FaIcon(
                FontAwesomeIcons.trash,
                color: ColorPalette.offWhite,
              ),
            ),
          ] else ...[
            IconButton(
              onPressed: _saveRecipe,
              icon: FaIcon(
                isSaved
                    ? FontAwesomeIcons.solidBookmark
                    : FontAwesomeIcons.bookmark,
                color: ColorPalette.offWhite,
              ),
            ),
          ],
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
