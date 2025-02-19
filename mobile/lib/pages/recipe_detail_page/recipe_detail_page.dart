import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/api/auth_api.dart';
import 'package:mobile/api/recipe_api.dart';
import 'package:mobile/models/recipe/recipe.dart';
import 'package:mobile/models/user/user.dart';
import 'package:mobile/pages/recipe_detail_page/additional_section_widget.dart';
import 'package:mobile/pages/recipe_detail_page/recipe_detail_skeleton.dart';
import 'package:mobile/pages/recipe_detail_page/recipe_image_widget.dart';
import 'package:mobile/pages/recipe_detail_page/recipe_info_widget.dart';
import 'package:mobile/providers/recipe_detail_provider.dart';
import 'package:mobile/widgets/dialogs/confirmation_dialog.dart';
import 'package:mobile/pages/update_recipe_page.dart';
import 'package:mobile/theme/colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile/widgets/toasts/information_toast.dart';
import 'package:mobile/widgets/dialogs/user_post_dialog.dart';
import 'package:provider/provider.dart';

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
  late Recipe _currentRecipe;
  late int _servings;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final recipeDetailProvider =
        Provider.of<RecipeDetailProvider>(context, listen: false);
    recipeDetailProvider.fetchRecipe().then((_) {
      _initializePage();
    });
  }

  void _initializePage() async {
    if (widget.recipe != null) {
      _currentRecipe = widget.recipe!;
      _servings = _currentRecipe.servings ?? 1;
      await _checkIfSaved();
      completedInstructions =
          List<bool>.filled(_currentRecipe.instructions.length, false);
    } else if (widget.recipeId != null && widget.recipeId! > 0) {
      await _initializeRecipe(widget.recipeId!);
    }
  }

  Future<void> _initializeRecipe(int recipeId) async {
    var response = await RecipeApi().getRecipeById(recipeId);
    setState(() {
      _currentRecipe = Recipe.fromJson(response);
      _servings = _currentRecipe.servings ?? 1;
      completedInstructions =
          List<bool>.filled(_currentRecipe.instructions.length, false);
    });
    await _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    User? user = await AuthApi.getUser();

    if (user != null && _currentRecipe.created_by?.id == user.id) {
      setState(() {
        isSaved = true;
      });
    }
  }

  void _saveRecipe() async {
    String capitalize(String? text) {
      if (text == null) return "";
      return text[0].toUpperCase() + text.substring(1).toLowerCase();
    }

    if (isSaved) return;

    Map<String, dynamic> recipeData = {
      "title": capitalize(_currentRecipe.title),
      "ingredients": _currentRecipe.ingredients
          .map((ingredient) => {
                "name": capitalize(ingredient.name),
                "quantity": ingredient.quantity,
                "unit_of_measure": ingredient.unit_of_measure,
              })
          .toList(),
      "instructions": _currentRecipe.instructions,
      "preparation_time": _currentRecipe.preparation_time,
      "cooking_time": _currentRecipe.cooking_time,
      "description": capitalize(_currentRecipe.description),
      "notes": capitalize(_currentRecipe.notes),
      "tags": _currentRecipe.tags,
      "parent": _currentRecipe.id,
    };

    bool success = await RecipeApi().createRecipe(recipeData);

    InformationToast.show(
      context: context,
      message:
          success ? "Recipe saved successfully!" : "Failed to save recipe.",
      textColor: success ? ColorPalette.green : ColorPalette.red,
    );
  }

  void _toggleFavorite() async {
    final updatedFavoriteStatus = !(_currentRecipe.is_favorite ?? true);

    final result = await RecipeApi().patchRecipe(
      _currentRecipe.id,
      {
        'is_favorite': updatedFavoriteStatus,
      },
    );

    if (result) {
      setState(() {
        _currentRecipe =
            _currentRecipe.copyWith(is_favorite: updatedFavoriteStatus);
      });
    } else {
      InformationToast.show(
        context: context,
        message: 'There was an error updating the favorite status.',
        textColor: ColorPalette.red,
      );
    }
  }

  void _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });

      bool success = await _uploadImageToServer(_imageFile!, _currentRecipe.id);
      if (success) {
        InformationToast.show(
            context: context,
            message: success
                ? "Image uploaded successfully!"
                : "Failed to upload image.",
            textColor: success ? ColorPalette.green : ColorPalette.red);
      }
    }
  }

  Future<bool> _uploadImageToServer(File imageFile, int recipeId) async {
    try {
      return await RecipeApi().uploadRecipeImage(recipeId, imageFile);
    } catch (e) {
      InformationToast.show(
        context: context,
        message: "An error occurred while uploading the image.",
        textColor: ColorPalette.red,
      );
      return false;
    }
  }

  Widget getRecipeImage(String? imageUrl) {
    int imageNumber = (_currentRecipe.id % 11) + 1;

    return GestureDetector(
      onTap: () {
        _pickImage();
      },
      child: ClipRRect(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipeDetailProvider = Provider.of<RecipeDetailProvider>(context);

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
                      recipe: _currentRecipe,
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
                (_currentRecipe.is_favorite ?? false)
                    ? FontAwesomeIcons.solidHeart
                    : FontAwesomeIcons.heart,
                color: (_currentRecipe.is_favorite ?? false)
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
                        UpdateRecipePage(recipeId: _currentRecipe.id),
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
                          await RecipeApi().deleteRecipe(_currentRecipe.id);
                      if (success) Navigator.pop(context);
                      InformationToast.show(
                        context: context,
                        message: success
                            ? "Recipe deleted successfully!"
                            : "There was an error deleting the recipe.",
                        textColor:
                            success ? ColorPalette.green : ColorPalette.red,
                      );
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
      body: recipeDetailProvider.isLoading
          ? RecipeDetailSkeleton()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RecipeImage(
                    imageUrl: _currentRecipe.image_url ?? "",
                    onImagePick: _pickImage,
                  ),
                  const SizedBox(height: 16),
                  RecipeInfo(
                    recipe: _currentRecipe,
                    servings: _servings,
                    incrementServings: () => setState(() => _servings++),
                    decrementServings: () =>
                        setState(() => _servings > 1 ? _servings-- : _servings),
                    completedInstructions: completedInstructions,
                    onCompletedInstructions: (index) => {
                      setState(
                        () {
                          completedInstructions[index] =
                              !completedInstructions[index];
                        },
                      ),
                    },
                  ),
                  const SizedBox(height: 16),
                  AdditionalSections(
                    tags: _currentRecipe.tags,
                    description: _currentRecipe.description,
                    notes: _currentRecipe.notes,
                  ),
                ],
              ),
            ),
    );
  }
}
