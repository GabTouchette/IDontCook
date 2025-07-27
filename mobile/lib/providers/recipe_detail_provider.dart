import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/recipe_api.dart';
import 'package:i_cant_cook/enums/toast_type.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/theme/theme.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';

class RecipeDetailProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isSaving = false;
  Recipe? _recipe;
  int _servings = 1;
  List<bool> _completedInstructions = [];

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  Recipe? get recipe => _recipe;
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
    if (_recipe == null || _isSaving) return;

    _isSaving = true;
    notifyListeners();

    try {
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
        "web_image_url": _recipe!.image_url,
      };

      int? newId = await RecipeApi().createRecipe(recipeData);
      bool success = newId != null;

      if (success) {
        // Fetch the full recipe data including nutrition to refresh the UI
        var fullRecipeData = await RecipeApi().getRecipeById(newId);
        _recipe = Recipe.fromJson(fullRecipeData);
        notifyListeners();
      }

      InformationToast.show(
        context: context,
        message:
            success ? "Recipe saved successfully!" : "Failed to save recipe.",
        type: success ? ToastType.success : ToastType.error,
      );
    } catch (e) {
      InformationToast.show(
        context: context,
        message: "Error saving recipe: $e",
        type: ToastType.error,
      );
    } finally {
      _isSaving = false;
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
        type: ToastType.error,
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
