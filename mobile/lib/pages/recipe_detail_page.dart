import 'package:flutter/material.dart';
import 'package:mobile/api/recipe_api.dart';
import 'package:mobile/models/recipe.dart';
import 'package:mobile/widgets/dialogs/confirmation_dialog.dart';
import 'package:mobile/pages/update_recipe_page.dart';
import 'package:mobile/theme/colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailPage({Key? key, required this.recipe}) : super(key: key);

  @override
  _RecipeDetailPageState createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  List<bool> completedInstructions = [];
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    completedInstructions =
        List<bool>.filled(widget.recipe.instructions.length, false);
    isSaved = widget.recipe.id != -1;
  }

  void _saveRecipe() async {
    if (widget.recipe.id == -1) {
      Map<String, dynamic> recipeData = {
        "title": widget.recipe.title,
        "ingredients": widget.recipe.ingredients
            .map((ingredient) => {
                  "name": ingredient.name,
                  "quantity": ingredient.quantity,
                  "unit_of_measure": ingredient.unit_of_measure,
                })
            .toList(),
        "instructions": widget.recipe.instructions,
        "preparation_time": widget.recipe.preparation_time,
        "cooking_time": widget.recipe.cooking_time,
        "description": widget.recipe.description,
        "notes": widget.recipe.notes,
        "tags": widget.recipe.tags,
      };

      bool success = await RecipeApi().createRecipe(recipeData);

      if (success) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(success ? 'Recipe Saved' : 'Submission Failed'),
            content: Text(success
                ? 'Your recipe has been successfully saved!'
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
          widget.recipe.title,
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
                    builder: (context) =>
                        UpdateRecipePage(recipeId: widget.recipe.id),
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
                      bool success =
                          await RecipeApi().deleteRecipe(widget.recipe.id);
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
              child: widget.recipe.image_url != null && widget.recipe.image_url != ""
                  ? Image.network(
                      widget.recipe.image_url!,
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
                  if (widget.recipe.preparation_time != null) ...[
                    const Icon(Icons.timer, size: 20, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Prep: ${widget.recipe.preparation_time} min',
                      style:
                          TextStyle(color: ColorPalette.offWhite, fontSize: 16),
                    ),
                  ],
                  if (widget.recipe.preparation_time != null &&
                      widget.recipe.cooking_time != null)
                    const SizedBox(width: 16),
                  if (widget.recipe.cooking_time != null) ...[
                    const Icon(Icons.local_fire_department,
                        size: 20, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Cook: ${widget.recipe.cooking_time} min',
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
                children: (widget.recipe.ingredients).map((ingredient) {
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
                    List.generate(widget.recipe.instructions.length, (index) {
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
                                widget.recipe.instructions[index],
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
            const SizedBox(height: 16),

            if (widget.recipe.tags != null && widget.recipe.tags!.isNotEmpty)
              _buildTagSection(widget.recipe.tags!),
            // Description Section

            if (widget.recipe.description != null &&
                widget.recipe.description!.isNotEmpty)
              _buildSection("Description", widget.recipe.description!),

            // Notes Section
            if (widget.recipe.notes != null && widget.recipe.notes!.isNotEmpty)
              _buildSection("Notes", widget.recipe.notes!),
            const SizedBox(height: 64),

            // Tags Section
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(color: ColorPalette.offWhite, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTagSection(List<String> tags) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tags",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: tags.map((tag) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: ColorPalette.darkgray,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
