import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/recipe_api.dart';
import 'package:i_cant_cook/enums/toast_type.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';

class RecipeDetailProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isSaving = false;
  Recipe? _recipe;
  double _servings = 1.0;
  List<bool> _completedInstructions = [];
  List<bool> _completedIngredients = [];

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  Recipe? get recipe => _recipe;
  double get servings => _servings;
  List<bool> get completedInstructions => _completedInstructions;
  List<bool> get completedIngredients => _completedIngredients;

  set image_url(String? newImageUrl) {
    if (_recipe != null) {
      _recipe = _recipe!.copyWith(image_url: newImageUrl);
      notifyListeners();
    }
  }

  Future<void> initializeRecipe({Recipe? recipe, int? recipeId}) async {
    if (recipe != null) {
      _recipe = recipe;
      _servings = (recipe.servings ?? 1).toDouble();
      _completedInstructions =
          List<bool>.filled(recipe.instructions.length, false);
      _completedIngredients =
          List<bool>.filled(recipe.ingredients.length, false);
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
      _servings = (_recipe!.servings ?? 1).toDouble();
      _completedInstructions =
          List<bool>.filled(_recipe!.instructions.length, false);
      _completedIngredients =
          List<bool>.filled(_recipe!.ingredients.length, false);

      print(
          'DEBUG RecipeDetailProvider: Fetched recipe ${_recipe!.id}, is_saved: ${_recipe!.is_saved}');
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

  Future<void> saveRecipeOnly(BuildContext context) async {
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
        // AI-generated recipes (id == -1) already have structured ingredients — skip LLM reformatting
        "is_formatted": _recipe!.id == -1,
        // Preserve existing nutrition on clone so UI doesn't "lose" it before recalculation
        "calories": _recipe!.calories,
        "protein": _recipe!.protein,
        "fat": _recipe!.fat,
        "carbs": _recipe!.carbs,
      };

      int? newId = await RecipeApi().createRecipe(recipeData);
      bool success = newId != null;

      if (!success) {
        throw Exception("Failed to save recipe");
      }

      // Fetch the newly created recipe (will not yet have nutrition data)
      var fullRecipeData = await RecipeApi().getRecipeById(newId);
      _recipe = Recipe.fromJson(fullRecipeData);
      notifyListeners();

      // If the original recipe had nutrition OR we want to ensure nutrition, attempt calculation
      try {
        var nutritionResult = await RecipeApi().calculateRecipeNutrition(newId);
        if (nutritionResult != null && nutritionResult['success'] == true) {
          // Re-fetch to get updated nutrition fields
          var updatedRecipeData = await RecipeApi().getRecipeById(newId);
          _recipe = Recipe.fromJson(updatedRecipeData);
          notifyListeners();
          // ignore: avoid_print
          print('✅ Nutrition recalculated for saved recipe (saveRecipeOnly)');
        } else {
          // ignore: avoid_print
          print(
              '⚠️ Nutrition calculation skipped or failed for saveRecipeOnly');
        }
      } catch (e) {
        // ignore: avoid_print
        print('❌ Error calculating nutrition in saveRecipeOnly: $e');
      }

      InformationToast.show(
        context: context,
        message: "Recipe saved successfully!",
        type: ToastType.success,
      );
    } catch (e) {
      InformationToast.show(
        context: context,
        message: "Error saving recipe: $e",
        type: ToastType.error,
      );
      rethrow; // Let dialog handle the error
    } finally {
      _isSaving = false;
      notifyListeners();
    }
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
        // AI-generated recipes (id == -1) already have structured ingredients — skip LLM reformatting
        "is_formatted": _recipe!.id == -1,
        // Preserve existing nutrition so new saved recipe immediately shows values
        "calories": _recipe!.calories,
        "protein": _recipe!.protein,
        "fat": _recipe!.fat,
        "carbs": _recipe!.carbs,
      };

      int? newId = await RecipeApi().createRecipe(recipeData);
      bool success = newId != null;

      if (success) {
        // Fetch the full recipe data to refresh the UI
        var fullRecipeData = await RecipeApi().getRecipeById(newId);
        _recipe = Recipe.fromJson(fullRecipeData);
        notifyListeners();

        // Calculate nutrition after recipe is saved and formatted
        try {
          var nutritionResult =
              await RecipeApi().calculateRecipeNutrition(newId);
          if (nutritionResult != null && nutritionResult['success'] == true) {
            print(
                "✅ Nutrition calculated successfully: ${nutritionResult['nutrition']}");
            // Refresh recipe data again to get the updated nutrition
            var updatedRecipeData = await RecipeApi().getRecipeById(newId);
            _recipe = Recipe.fromJson(updatedRecipeData);
            notifyListeners();
          } else {
            print("⚠️ Nutrition calculation failed or returned no data");
          }
        } catch (e) {
          print("❌ Error calculating nutrition: $e");
          // Don't show error to user - nutrition calculation is optional
        }
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
    // Step up through 0.25 -> 0.5 -> 1.0 -> +1 increments
    if (_servings < 0.5) {
      _servings = 0.5;
    } else if (_servings < 1.0) {
      _servings = 1.0;
    } else {
      _servings = _servings + 1.0;
    }
    notifyListeners();
  }

  void decrementServings() {
    // Allow dropping to 0.5 and 0.25, minimum 0.25
    if (_servings > 1.0) {
      _servings = _servings - 1.0;
    } else if (_servings > 0.5) {
      _servings = 0.5;
    } else if (_servings > 0.25) {
      _servings = 0.25;
    }
    notifyListeners();
  }

  void toggleInstructionCompletion(int index) {
    if (index >= 0 && index < _completedInstructions.length) {
      _completedInstructions[index] = !_completedInstructions[index];
      notifyListeners();
    }
  }

  void toggleIngredientCompletion(int index) {
    if (index >= 0 && index < _completedIngredients.length) {
      _completedIngredients[index] = !_completedIngredients[index];
      notifyListeners();
    }
  }
}
