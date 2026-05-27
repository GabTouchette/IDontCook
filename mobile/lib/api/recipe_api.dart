import 'dart:convert';
import 'dart:io';

import 'package:i_cant_cook/api/api_helper.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';

class RecipeApi {
  final ApiHelper _apiHelper = ApiHelper();

  Future<List<RecipePreview>> fetchRecipes() async {
    var data = await _apiHelper.getRequest('recipes/');
    if (data != null) {
      return (data as List)
          .map((recipe) => RecipePreview.fromJson(recipe))
          .toList();
    }
    return [];
  }

  Future<int?> createRecipe(Map<String, dynamic> recipeData) async {
    var response = await _apiHelper.postRequest('recipes/', recipeData);
    return response["id"];
  }

  Future<Map<String, dynamic>> getRecipeById(int recipeId) async {
    return await _apiHelper.getRequest('recipes/$recipeId/');
  }

  Future<bool> updateRecipe(
      int recipeId, Map<String, dynamic> recipeData) async {
    var response =
        await _apiHelper.putRequest('recipes/$recipeId/', recipeData);
    return response != null;
  }

  Future<bool> patchRecipe(
      int recipeId, Map<String, dynamic> recipeData) async {
    var response =
        await _apiHelper.patchRequest('recipes/$recipeId/', recipeData);
    return response != null;
  }

  Future<String> uploadRecipeImage(int recipeId, File imageFile) async {
    return await _apiHelper.imageRequest('recipes/$recipeId/image', imageFile);
  }

  /// Sends an image to the OCR endpoint and returns the extracted recipe fields,
  /// or null if the request fails.
  Future<Map<String, dynamic>?> digitalizeFromImage(File imageFile) async {
    try {
      final result = await _apiHelper.uploadFile('ai/ocr/', imageFile);
      if (result == null) return null;
      final responseStr = result['response'] as String?;
      if (responseStr == null) return null;
      return jsonDecode(responseStr) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteRecipe(int recipeId) async {
    return await _apiHelper.deleteRequest('recipes/$recipeId/');
  }

  Future<List<String>> fetchRecipeTags() async {
    var data = await _apiHelper.getRequest('recipes/tags/');
    if (data != null) {
      return List<String>.from(data);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> autocompleteCanonicalIngredients(
      String query,
      {int limit = 5}) async {
    final params = {'q': query, 'limit': '$limit'};
    final data = await _apiHelper
        .getRequest('recipes/ingredients/autocomplete/', queryParams: params);
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>?> calculateRecipeNutrition(int recipeId) async {
    return await _apiHelper.postRequest('recipes/$recipeId/nutrition/', {});
  }

  /// GET /api/recipes/<id>/nutrition/ — returns cached per-serving macros +
  /// per-ingredient breakdown.  Returns null on network error.
  Future<Map<String, dynamic>?> fetchNutrition(int recipeId) async {
    try {
      final data = await _apiHelper.getRequest('recipes/$recipeId/nutrition/');
      if (data is Map<String, dynamic>) return data;
      return null;
    } catch (_) {
      return null;
    }
  }
}
