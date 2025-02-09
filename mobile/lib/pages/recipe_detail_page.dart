import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mobile/api/auth_api.dart';
import 'package:mobile/api/recipe_api.dart';
import 'package:mobile/models/recipe/recipe.dart';
import 'package:mobile/models/user/user.dart';
import 'package:mobile/widgets/dialogs/confirmation_dialog.dart';
import 'package:mobile/pages/update_recipe_page.dart';
import 'package:mobile/theme/colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile/widgets/toasts/information_toast.dart';
import 'package:mobile/widgets/dialogs/user_post_dialog.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe? recipe;
  final int? recipeId;

  const RecipeDetailPage({
    Key? key,
    this.recipe,
    this.recipeId,
  }) : super(key: key);

  @override
  _RecipeDetailPageState createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  List<bool> completedInstructions = [];
  bool isSaved = false;
  late Recipe currentRecipe;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  void _initializePage() async {
    if (widget.recipe != null) {
      currentRecipe = widget.recipe!;
      await _checkIfSaved();
      completedInstructions =
          List<bool>.filled(currentRecipe.instructions.length, false);
    } else if (widget.recipeId != null && widget.recipeId! > 0) {
      await _initializeRecipe(widget.recipeId!);
    }
  }

  Future<void> _initializeRecipe(int recipeId) async {
    var response = await RecipeApi().getRecipeById(recipeId);
    setState(() {
      currentRecipe = Recipe.fromJson(response);
      completedInstructions =
          List<bool>.filled(currentRecipe.instructions.length, false);
    });
    await _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    User? user = await AuthApi.getUser();

    if (user != null && currentRecipe.created_by?.id == user.id) {
      setState(() {
        isSaved = true;
      });
    }
  }

  void _saveRecipe() async {
    if (isSaved) return;

    Map<String, dynamic> recipeData = {
      "title": currentRecipe.title,
      "ingredients": currentRecipe.ingredients
          .map((ingredient) => {
                "name": ingredient.name,
                "quantity": ingredient.quantity,
                "unit_of_measure": ingredient.unit_of_measure,
              })
          .toList(),
      "instructions": currentRecipe.instructions,
      "preparation_time": currentRecipe.preparation_time,
      "cooking_time": currentRecipe.cooking_time,
      "description": currentRecipe.description,
      "notes": currentRecipe.notes,
      "tags": currentRecipe.tags,
      "parent": currentRecipe.id,
    };

    bool success = await RecipeApi().createRecipe(recipeData);

    if (success) {
      InformationToast.show(
        context: context,
        message: "Recipe saved successfully!",
        textColor: ColorPalette.green,
      );
    }
  }

  void _toggleFavorite() async {
    final updatedFavoriteStatus = !(currentRecipe.is_favorite ?? true);

    final result = await RecipeApi().patchRecipe(
      currentRecipe.id,
      {
        'is_favorite': updatedFavoriteStatus,
      },
    );

    if (result) {
      setState(() {
        currentRecipe =
            currentRecipe.copyWith(is_favorite: updatedFavoriteStatus);
      });
    } else {
      InformationToast.show(
        context: context,
        message: 'There was an error updating the favorite status.',
        textColor: ColorPalette.red,
      );
    }
  }

  Widget getRecipeImage(String? imageUrl) {
    final random = Random();
    int imageNumber = random.nextInt(11) + 1;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: imageUrl != null && imageUrl.isNotEmpty
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.darkergray,
      appBar: AppBar(
        backgroundColor: ColorPalette.darkergray,
        title: Text(
          "Details",
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 32,
            color: ColorPalette.offWhite,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 0,
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
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return PostDialog(
                      recipe: currentRecipe,
                    );
                  },
                );
              },
              icon: const FaIcon(
                FontAwesomeIcons.share,
                color: ColorPalette.offWhite,
              ),
            ),
            IconButton(
              onPressed: _toggleFavorite,
              icon: FaIcon(
                (currentRecipe.is_favorite ?? false)
                    ? FontAwesomeIcons.solidHeart
                    : FontAwesomeIcons.heart,
                color: (currentRecipe.is_favorite ?? false)
                    ? Colors.red
                    : ColorPalette.offWhite,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        UpdateRecipePage(recipeId: currentRecipe.id),
                  ),
                ).then(
                  (_) {
                    _initializePage();
                  },
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
                          await RecipeApi().deleteRecipe(currentRecipe.id);
                      if (success) Navigator.pop(context);
                      InformationToast.show(
                          context: context,
                          message: success
                              ? "Recipe deleted successfully!"
                              : "There was an error deleting the recipe.",
                          textColor:
                              success ? ColorPalette.green : ColorPalette.red);
                    },
                    onCancel: () {
                      Navigator.pop(context);
                    },
                  ),
                );
              },
              icon: const FaIcon(
                FontAwesomeIcons.trash,
                color: ColorPalette.red,
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
            getRecipeImage(currentRecipe.image_url),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16),
              child: Text(
                currentRecipe.title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 36,
                  color: ColorPalette.offWhite,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  if (currentRecipe.preparation_time != null) ...[
                    const Icon(Icons.timer,
                        size: 20, color: ColorPalette.yellow),
                    const SizedBox(width: 6),
                    Text(
                      'Prep: ${currentRecipe.preparation_time} min',
                      style:
                          TextStyle(color: ColorPalette.offWhite, fontSize: 16),
                    ),
                  ],
                  if (currentRecipe.preparation_time != null &&
                      currentRecipe.cooking_time != null)
                    const SizedBox(width: 16),
                  if (currentRecipe.cooking_time != null) ...[
                    const Icon(Icons.local_fire_department,
                        size: 20, color: ColorPalette.orange),
                    const SizedBox(width: 6),
                    Text(
                      'Cook: ${currentRecipe.cooking_time} min',
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
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (currentRecipe.ingredients).map((ingredient) {
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
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
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
                    List.generate(currentRecipe.instructions.length, (index) {
                  final isCompleted = (index < completedInstructions.length)
                      ? completedInstructions[index]
                      : false;
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
                                currentRecipe.instructions[index],
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
            if (currentRecipe.tags != null && currentRecipe.tags!.isNotEmpty)
              _buildTagSection(currentRecipe.tags!),
            if (currentRecipe.description != null &&
                currentRecipe.description!.isNotEmpty)
              _buildSection("Description", currentRecipe.description!),
            if (currentRecipe.notes != null && currentRecipe.notes!.isNotEmpty)
              _buildSection("Notes", currentRecipe.notes!),
            const SizedBox(height: 64),
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
              fontSize: 28,
              fontWeight: FontWeight.w300,
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
              fontSize: 28,
              fontWeight: FontWeight.w300,
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
