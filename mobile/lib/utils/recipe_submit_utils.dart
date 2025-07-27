import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/recipe_api.dart';
import 'package:i_cant_cook/enums/toast_type.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/pages/recipe_detail_page.dart';
import 'package:i_cant_cook/theme/theme.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';

Map<String, dynamic> buildRecipeDataFromRecipe(Recipe recipe) {
  return {
    "title": recipe.title,
    "ingredients": recipe.ingredients
        .map((i) => {
              "quantity": i.quantity ?? "1",
              "name": i.name ?? "",
            })
        .toList(),
    "instructions": recipe.instructions,
    "preparation_time": recipe.preparation_time ?? 0,
    "cooking_time": recipe.cooking_time ?? 0,
    "description": recipe.description ?? "",
    "notes": recipe.notes ?? "",
    "tags": recipe.tags ?? [],
  };
}

Map<String, dynamic> buildRecipeDataFromForm({
  required TextEditingController titleController,
  required List<TextEditingController> instructionControllers,
  required List<dynamic> ingredientFields, // Each with `controller`
  required TextEditingController prepTimeController,
  required TextEditingController cookTimeController,
  required TextEditingController descriptionController,
  required TextEditingController notesController,
  required List<String> selectedTags,
}) {
  List<Map> ingredients = ingredientFields
      .map((field) {
        String text = field.controller.text.trim();
        if (text.isEmpty) return {};

        List<String> parts = text.split(" ");
        if (parts.isEmpty) return {};

        if (!_isNumber(parts[0])) {
          return {
            "quantity": "1",
            "name": parts.join(" "),
          };
        }
        if (parts.length == 2) {
          return {
            "quantity": parts[0],
            "name": parts[1],
          };
        }
        return {
          "quantity": parts[0],
          "name": parts.sublist(1).join(" "),
        };
      })
      .where((ingredient) => ingredient.isNotEmpty)
      .toList();

  List<String> instructions = instructionControllers
      .map((c) => c.text.trim())
      .where((t) => t.isNotEmpty)
      .toList();

  return {
    "title": titleController.text.trim(),
    "ingredients": ingredients,
    "instructions": instructions,
    "preparation_time": int.tryParse(prepTimeController.text) ?? 0,
    "cooking_time": int.tryParse(cookTimeController.text) ?? 0,
    "description": descriptionController.text.trim(),
    "notes": notesController.text.trim(),
    "tags": selectedTags,
  };
}

Future<void> submitRecipe({
  required BuildContext context,
  required Map<String, dynamic> recipeData,
  required bool isUpdate,
  int? recipeId,
  bool shouldNavigate = true,
}) async {
  try {
    bool success = false;
    int? newRecipeId;

    if (isUpdate) {
      if (recipeId == null) throw Exception("Missing recipe ID for update");
      success = await RecipeApi().updateRecipe(recipeId, recipeData);
    } else {
      newRecipeId = await RecipeApi().createRecipe(recipeData);
      success = newRecipeId != null;
    }

    InformationToast.show(
      context: context,
      message: success
          ? (isUpdate ? 'Recipe updated!' : 'Recipe created!')
          : 'An error occurred.',
      type: success ? ToastType.success : ToastType.error,
    );

    if (success && shouldNavigate) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailPage(recipeId: newRecipeId ?? recipeId!),
        ),
      );
    }
  } catch (e) {
    InformationToast.show(
      context: context,
      message: 'Error: $e',
      backgroundColor: Theme.of(context).colorScheme.error,
    );
  }
}

bool _isNumber(String s) => double.tryParse(s) != null;
