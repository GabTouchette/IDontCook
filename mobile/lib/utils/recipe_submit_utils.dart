import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/recipe_api.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/pages/recipe_detail_page.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';

Map<String, dynamic> buildRecipeDataFromRecipe(Recipe recipe) {
  return {
    "title": recipe.title,
    "ingredients": recipe.ingredients.map((i) {
      final item = <String, dynamic>{
        if (i.quantity != null) "quantity": i.quantity,
        "unit": i.unit ?? "",
        "name": i.name ?? "",
        if (i.preparation != null && i.preparation!.isNotEmpty)
          "preparation": i.preparation,
        if (i.substitutes != null && i.substitutes!.isNotEmpty)
          "substitutes": i.substitutes,
      };
      if (i.canonical != null) item["canonical_id"] = i.canonical;
      return item;
    }).toList(),
    "instructions": recipe.instructions,
    "preparation_time": recipe.preparation_time ?? 0,
    "cooking_time": recipe.cooking_time ?? 0,
    "description": recipe.description ?? "",
    "notes": recipe.notes ?? "",
    "tags": recipe.tags ?? [],
    "servings": recipe.servings,
    "image_url": recipe.image_url ?? "",
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
  List<Map<String, dynamic>> ingredients = [];
  for (final field in ingredientFields) {
    // Prefer structured entry if any structured control is populated
    final qty = field.qtyController.text.trim();
    final unit = field.unit;
    final name = field.nameController.text.trim().isNotEmpty
        ? field.nameController.text.trim()
        : field.controller.text.trim(); // fallback to legacy text field
    final desc = field.descController.text.trim();

    if (name.isNotEmpty || qty.isNotEmpty || desc.isNotEmpty) {
      Map<String, dynamic> item = {
        if (qty.isNotEmpty) 'quantity': qty,
        'unit': unit,
        'name': name,
        if (desc.isNotEmpty) 'preparation': desc,
      };
      final canonicalId = (field.canonicalId is int) ? field.canonicalId : null;
      if (canonicalId != null) item['canonical_id'] = canonicalId;
      ingredients.add(item);
      continue;
    }

    // Legacy free-text fallback
    final text = field.controller.text.trim();
    if (text.isNotEmpty) {
      final parsed = _parseIngredientText(text);
      if (parsed.isNotEmpty) {
        final canonicalId =
            (field.canonicalId is int) ? field.canonicalId : null;
        if (canonicalId != null) parsed['canonical_id'] = canonicalId;
        ingredients.add(parsed);
      }
    }
  }

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
    int? resultRecipeId;
    bool success = false;

    if (isUpdate) {
      if (recipeId == null) throw Exception("Missing recipe ID for update");
      success = await RecipeApi().updateRecipe(recipeId, recipeData);
      resultRecipeId = recipeId;
    } else {
      resultRecipeId = await RecipeApi().createRecipe(recipeData);
      success = resultRecipeId != null;
    }

    if (success && resultRecipeId != null) {
      // Show success toast
      InformationToast.success(
        context,
        isUpdate ? 'Recipe updated successfully!' : 'Recipe saved successfully!',
      );

      // Navigate if requested
      if (shouldNavigate) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailPage(recipeId: resultRecipeId),
          ),
        );
      }
    } else {
      throw Exception(
          isUpdate ? 'Failed to update recipe' : 'Failed to create recipe');
    }
  } catch (e) {
    // Show error toast
    InformationToast.error(
      context,
      isUpdate ? 'Failed to update recipe.' : 'Failed to save recipe.',
    );
  }
}

bool _isNumber(String s) => double.tryParse(s) != null;

Map<String, dynamic> _parseIngredientText(String text) {
  // Comprehensive unit database
  final units = [
    // Volume
    'cup', 'cups', 'c',
    'tablespoon', 'tablespoons', 'tbsp', 'tbs',
    'teaspoon', 'teaspoons', 'tsp', 'ts',
    'liter', 'liters', 'l',
    'milliliter', 'milliliters', 'ml',
    'quart', 'quarts', 'qt',
    'pint', 'pints', 'pt',
    'gallon', 'gallons', 'gal',
    'fluid ounce', 'fluid ounces', 'fl oz',

    // Weight
    'pound', 'pounds', 'lb', 'lbs',
    'ounce', 'ounces', 'oz',
    'gram', 'grams', 'g',
    'kilogram', 'kilograms', 'kg',

    // Count/Size
    'piece', 'pieces', 'pcs',
    'slice', 'slices',
    'clove', 'cloves',
    'can', 'cans',
    'bottle', 'bottles',
    'package', 'packages', 'pkg',
    'bag', 'bags',
    'bunch', 'bunches',
    'head', 'heads',
    'stalk', 'stalks',
    'sprig', 'sprigs',
    'leaf', 'leaves',
    'strip', 'strips',
    'fillet', 'fillets',
    'breast', 'breasts',
  ];

  // Smart ingredient defaults based on ingredient type
  final ingredientDefaults = {
    // Fruits & Vegetables (pieces)
    'avocado': 'piece', 'avocados': 'piece', 'ripe avocado': 'piece',
    'ripe avocados': 'piece',
    'onion': 'piece', 'onions': 'piece', 'large onion': 'piece',
    'medium onion': 'piece', 'small onion': 'piece',
    'tomato': 'piece', 'tomatoes': 'piece', 'large tomato': 'piece',
    'cherry tomatoes': 'cup',
    'apple': 'piece', 'apples': 'piece', 'green apple': 'piece',
    'red apple': 'piece',
    'banana': 'piece', 'bananas': 'piece', 'ripe banana': 'piece',
    'ripe bananas': 'piece',
    'lemon': 'piece', 'lemons': 'piece', 'large lemon': 'piece',
    'lime': 'piece', 'limes': 'piece', 'fresh lime': 'piece',
    'potato': 'piece', 'potatoes': 'piece', 'large potato': 'piece',
    'medium potato': 'piece',
    'carrot': 'piece', 'carrots': 'piece', 'large carrot': 'piece',
    'baby carrots': 'cup',
    'bell pepper': 'piece', 'peppers': 'piece', 'red bell pepper': 'piece',
    'green pepper': 'piece',
    'cucumber': 'piece', 'cucumbers': 'piece', 'large cucumber': 'piece',
    'garlic': 'clove', 'garlic clove': 'clove', 'garlic cloves': 'clove',
    'fresh garlic': 'clove',

    // Proteins (pieces/lbs for larger cuts, pieces for individual items)
    'chicken breast': 'piece', 'chicken breasts': 'piece',
    'boneless chicken breast': 'piece',
    'boneless chicken breasts': 'piece', 'skinless chicken breast': 'piece',
    'skinless chicken breasts': 'piece',
    'boneless skinless chicken breast': 'piece',
    'boneless skinless chicken breasts': 'piece',
    'chicken thigh': 'piece', 'chicken thighs': 'piece',
    'boneless chicken thigh': 'piece', 'boneless chicken thighs': 'piece',
    'chicken wing': 'piece', 'chicken wings': 'piece',
    'ground chicken': 'lb', 'ground beef': 'lb', 'ground turkey': 'lb',
    'ground pork': 'lb',
    'beef': 'lb', 'pork': 'lb', 'lamb': 'lb',
    'steak': 'piece', 'steaks': 'piece', 'ribeye': 'piece', 'sirloin': 'piece',
    'egg': 'piece', 'eggs': 'piece', 'large egg': 'piece',
    'large eggs': 'piece',
    'salmon fillet': 'piece', 'salmon fillets': 'piece', 'cod fillet': 'piece',
    'tilapia fillet': 'piece',
    'pork chop': 'piece', 'pork chops': 'piece', 'lamb chop': 'piece',
    'lamb chops': 'piece',
    'bacon': 'slice', 'bacon strips': 'slice', 'ham': 'slice',
    'shrimp': 'lb', 'prawns': 'lb', 'scallops': 'piece',

    // Dairy & Cheese
    'cheese': 'cup', 'cheddar cheese': 'cup', 'mozzarella cheese': 'cup',
    'parmesan cheese': 'cup',
    'cream cheese': 'oz', 'butter': 'tbsp', 'unsalted butter': 'tbsp',
    'salted butter': 'tbsp',
    'heavy cream': 'cup', 'sour cream': 'cup', 'greek yogurt': 'cup',
    'yogurt': 'cup',

    // Liquids (cups/tbsp)
    'olive oil': 'tbsp', 'extra virgin olive oil': 'tbsp',
    'vegetable oil': 'tbsp', 'canola oil': 'tbsp', 'coconut oil': 'tbsp',
    'water': 'cup', 'warm water': 'cup', 'cold water': 'cup',
    'milk': 'cup', 'whole milk': 'cup', 'skim milk': 'cup',
    'almond milk': 'cup',
    'broth': 'cup', 'chicken broth': 'cup', 'beef broth': 'cup',
    'vegetable broth': 'cup',
    'stock': 'cup', 'chicken stock': 'cup', 'beef stock': 'cup',
    'vegetable stock': 'cup',
    'juice': 'cup', 'lemon juice': 'tbsp', 'lime juice': 'tbsp',
    'orange juice': 'cup',
    'vinegar': 'tbsp', 'apple cider vinegar': 'tbsp', 'white vinegar': 'tbsp',
    'balsamic vinegar': 'tbsp',
    'soy sauce': 'tbsp', 'worcestershire sauce': 'tbsp', 'hot sauce': 'tsp',
    'wine': 'cup', 'white wine': 'cup', 'red wine': 'cup',

    // Spices & Small Items (tsp)
    'salt': 'tsp', 'sea salt': 'tsp', 'kosher salt': 'tsp', 'table salt': 'tsp',
    'pepper': 'tsp', 'black pepper': 'tsp', 'white pepper': 'tsp',
    'ground black pepper': 'tsp',
    'garlic powder': 'tsp', 'onion powder': 'tsp', 'paprika': 'tsp',
    'smoked paprika': 'tsp',
    'cumin': 'tsp', 'ground cumin': 'tsp', 'oregano': 'tsp',
    'dried oregano': 'tsp',
    'thyme': 'tsp', 'dried thyme': 'tsp', 'fresh thyme': 'tbsp',
    'basil': 'tsp', 'dried basil': 'tsp', 'fresh basil': 'tbsp',
    'basil leaves': 'tbsp',
    'rosemary': 'tsp', 'dried rosemary': 'tsp', 'fresh rosemary': 'tbsp',
    'parsley': 'tbsp', 'fresh parsley': 'tbsp', 'dried parsley': 'tsp',
    'cilantro': 'tbsp', 'fresh cilantro': 'tbsp',
    'chili powder': 'tsp', 'cayenne pepper': 'tsp', 'red pepper flakes': 'tsp',
    'cinnamon': 'tsp', 'ground cinnamon': 'tsp', 'nutmeg': 'tsp',
    'vanilla extract': 'tsp',

    // Pantry Items (cups)
    'flour': 'cup', 'all-purpose flour': 'cup', 'bread flour': 'cup',
    'wheat flour': 'cup',
    'sugar': 'cup', 'white sugar': 'cup', 'brown sugar': 'cup',
    'granulated sugar': 'cup',
    'powdered sugar': 'cup', 'confectioners sugar': 'cup',
    'rice': 'cup', 'white rice': 'cup', 'brown rice': 'cup',
    'jasmine rice': 'cup',
    'pasta': 'cup', 'spaghetti': 'cup', 'penne': 'cup', 'fettuccine': 'cup',
    'breadcrumbs': 'cup', 'panko breadcrumbs': 'cup',
    'oats': 'cup', 'rolled oats': 'cup', 'quick oats': 'cup',
    'quinoa': 'cup', 'barley': 'cup', 'lentils': 'cup', 'black beans': 'cup',
    'chickpeas': 'cup', 'kidney beans': 'cup',
  };

  List<String> parts = text.split(RegExp(r'\s+'));
  if (parts.isEmpty) return {};

  // Handle fractions like "1/2", "1/4"
  String quantity = "1";
  int startIndex = 0;

  if (parts.isNotEmpty && (_isNumber(parts[0]) || _isFraction(parts[0]))) {
    quantity = parts[0];
    startIndex = 1;
  }

  // No quantity found, but we have text
  if (startIndex == 0) {
    // Try to extract quantity from patterns like "a few", "some", etc.
    String lowerText = text.toLowerCase();
    if (lowerText.startsWith('a ') || lowerText.startsWith('an ')) {
      quantity = "1";
      startIndex = 1;
    } else if (lowerText.startsWith('some ') || lowerText.startsWith('few ')) {
      quantity = "2";
      startIndex = 1;
    } else {
      quantity = "1";
      startIndex = 0;
    }
  }

  // Extract remaining parts
  List<String> remainingParts = parts.sublist(startIndex);
  String unit = "";
  String name = "";

  if (remainingParts.isEmpty) {
    name = text;
  } else if (remainingParts.length == 1) {
    name = remainingParts[0];
  } else {
    // Check if first remaining part is a unit
    String potentialUnit = remainingParts[0].toLowerCase();

    if (units.contains(potentialUnit)) {
      unit = remainingParts[0];
      name = remainingParts.sublist(1).join(" ");
    } else {
      // No unit found, combine all as name
      name = remainingParts.join(" ");
    }
  }

  // Apply smart defaults if no unit found
  if (unit.isEmpty) {
    String nameLower = name.toLowerCase();

    // Check for exact matches first
    if (ingredientDefaults.containsKey(nameLower)) {
      unit = ingredientDefaults[nameLower]!;
    } else {
      // Check for partial matches
      for (String key in ingredientDefaults.keys) {
        if (nameLower.contains(key)) {
          unit = ingredientDefaults[key]!;
          break;
        }
      }
    }

    // Final fallback based on common patterns
    if (unit.isEmpty) {
      if (nameLower.contains('oil') ||
          nameLower.contains('sauce') ||
          nameLower.contains('vinegar') ||
          nameLower.contains('syrup')) {
        unit = 'tbsp';
      } else if (nameLower.contains('powder') ||
          nameLower.contains('spice') ||
          nameLower.contains('herb') ||
          nameLower.contains('seasoning')) {
        unit = 'tsp';
      } else if (nameLower.contains('flour') ||
          nameLower.contains('sugar') ||
          nameLower.contains('rice') ||
          nameLower.contains('pasta')) {
        unit = 'cup';
      } else {
        unit = 'piece'; // Default fallback
      }
    }
  }

  return {
    "quantity": quantity,
    "unit": unit,
    "name": name,
  };
}

bool _isFraction(String s) {
  return RegExp(r'^\d+/\d+$').hasMatch(s) ||
      RegExp(r'^\d+\s+\d+/\d+$').hasMatch(s);
}
