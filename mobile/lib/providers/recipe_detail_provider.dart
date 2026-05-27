import 'dart:async';
import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/recipe_api.dart';
import 'package:i_cant_cook/enums/toast_type.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';

class RecipeDetailProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isNutritionCalculating = false;
  Recipe? _recipe;
  double _servings = 1.0;
  List<bool> _completedInstructions = [];
  List<bool> _completedIngredients = [];
  // ingredientId → scaled calories for that ingredient (based on recipe servings)
  Map<int, double> _ingredientCalories = {};

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isNutritionCalculating => _isNutritionCalculating;
  Recipe? get recipe => _recipe;
  double get servings => _servings;
  List<bool> get completedInstructions => _completedInstructions;
  List<bool> get completedIngredients => _completedIngredients;
  Map<int, double> get ingredientCalories => _ingredientCalories;

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
        "servings": _recipe!.servings,
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

      // Start background polling for nutrition (non-blocking)
      pollNutritionUntilReady(newId);

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
        "servings": _recipe!.servings,
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

        // Start background polling for nutrition (non-blocking)
        pollNutritionUntilReady(newId);
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

  /// Poll `/api/recipes/<id>/nutrition/` until `is_calculated: true` or max attempts
  /// reached.  Updates [_ingredientCalories] and recipe macros on success.
  Future<void> pollNutritionUntilReady(int recipeId) async {
    if (_isNutritionCalculating) return;
    _isNutritionCalculating = true;
    notifyListeners();

    const maxAttempts = 8;
    const pollInterval = Duration(seconds: 4);

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      await Future.delayed(pollInterval);
      try {
        final data = await RecipeApi().fetchNutrition(recipeId);
        if (data == null) continue;

        if (data['is_calculated'] == true) {
          // Update recipe macros
          if (_recipe != null) {
            _recipe = _recipe!.copyWith(
              calories: (data['calories'] as num?)?.toDouble(),
              protein: (data['protein'] as num?)?.toDouble(),
              fat: (data['fat'] as num?)?.toDouble(),
              carbs: (data['carbs'] as num?)?.toDouble(),
            );
          }

          // Store per-ingredient calorie map
          final perIngredient = data['per_ingredient'] as List<dynamic>?;
          if (perIngredient != null) {
            final map = <int, double>{};
            for (final entry in perIngredient) {
              final id = entry['ingredient_id'] as int?;
              final cal = (entry['calories'] as num?)?.toDouble();
              if (id != null && cal != null) map[id] = cal;
            }
            _ingredientCalories = map;
          }

          _isNutritionCalculating = false;
          notifyListeners();
          return;
        }
        // is_calculated == false: keep polling
      } catch (e) {
        print('Nutrition poll error (attempt ${attempt + 1}): $e');
      }
    }

    // Timed out — stop spinner but don't show an error (nutrition is optional)
    _isNutritionCalculating = false;
    notifyListeners();
  }

  void toggleFavorite(BuildContext context) async {

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
