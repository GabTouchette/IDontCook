import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/auth_api.dart';
import 'package:i_cant_cook/api/recipe_api.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/theme/colors.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';

class RecipeDetailProvider with ChangeNotifier {
  bool _isLoading = false;
  Recipe? _recipe;
  bool _isSaved = false;
  int _servings = 1;
  List<bool> _completedInstructions = [];

  bool get isLoading => _isLoading;
  Recipe? get recipe => _recipe;
  bool get isSaved => _isSaved;
  int get servings => _servings;
  List<bool> get completedInstructions => _completedInstructions;

  set image_url(String? newImageUrl) {
    if (_recipe != null) {
      _recipe = _recipe!.copyWith(image_url: newImageUrl);
      notifyListeners();
    }
  }

  Future<void> initializeRecipe({Recipe? recipe, int? recipeId}) async {
    if (recipe != null) {
      _recipe = recipe;
      _servings = recipe.servings ?? 1;
      _completedInstructions =
          List<bool>.filled(recipe.instructions.length, false);
      await _checkIfSaved();
      notifyListeners();
      return;
    }

    if (recipeId != null && recipeId > 0) {
      await _fetchRecipe(recipeId);
    }
  }

  Future<void> _fetchRecipe(int recipeId) async {
    _isLoading = true;
    notifyListeners();

    try {
      var response = await RecipeApi().getRecipeById(recipeId);
      _recipe = Recipe.fromJson(response);
      _servings = _recipe!.servings ?? 1;
      _completedInstructions =
          List<bool>.filled(_recipe!.instructions.length, false);
      await _checkIfSaved();
    } catch (error) {
      print("Error fetching recipe: $error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _capitalize(String? text) {
    if (text == null || text.isEmpty) return "";
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Future<void> saveRecipe(BuildContext context) async {
    if (_isSaved || _recipe == null) return;

    Map<String, dynamic> recipeData = {
      "title": _capitalize(_recipe!.title),
      "ingredients": _recipe!.ingredients
          .map((ingredient) => {
                "name": _capitalize(ingredient.name),
                "quantity": ingredient.quantity,
              })
          .toList(),
      "instructions": _recipe!.instructions,
      "preparation_time": _recipe!.preparation_time,
      "cooking_time": _recipe!.cooking_time,
      "description": _capitalize(_recipe!.description),
      "notes": _capitalize(_recipe!.notes),
      "tags": _recipe!.tags,
      "parent_id": _recipe!.id,
    };

    int? newId = await RecipeApi().createRecipe(recipeData);
    bool success = newId != null;

    if (success) {
      _isSaved = true;
      _recipe = recipe?.copyWith(id: newId);
      notifyListeners();
    }

    InformationToast.show(
      context: context,
      message:
          success ? "Recipe saved successfully!" : "Failed to save recipe.",
      textColor: success ? ColorPalette.green : ColorPalette.red,
    );
  }

  Future<void> _checkIfSaved() async {
    var user = await AuthApi.getUser();
    _isSaved = false;
    if (user != null && _recipe?.created_by?.id == user.id) {
      _isSaved = true;
      notifyListeners();
    }
  }

  void toggleFavorite(BuildContext context) async {
    if (_recipe == null) return;

    final updatedFavoriteStatus = !(_recipe!.is_favorite ?? true);

    final result = await RecipeApi().patchRecipe(
      _recipe!.id,
      {'is_favorite': updatedFavoriteStatus},
    );

    if (result) {
      _recipe = _recipe!.copyWith(is_favorite: updatedFavoriteStatus);
      notifyListeners();
    } else {
      InformationToast.show(
        context: context,
        message: 'There was an error updating the favorite status.',
        textColor: ColorPalette.red,
      );
    }
  }

  void incrementServings() {
    _servings++;
    notifyListeners();
  }

  void decrementServings() {
    if (_servings > 1) {
      _servings--;
      notifyListeners();
    }
  }

  void toggleInstructionCompletion(int index) {
    if (index >= 0 && index < _completedInstructions.length) {
      _completedInstructions[index] = !_completedInstructions[index];
      notifyListeners();
    }
  }
}
