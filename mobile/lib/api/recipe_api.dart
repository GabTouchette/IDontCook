import 'dart:io';

import 'package:mobile/api/api_helper.dart';
import 'package:mobile/models/recipe_preview.dart';

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

  Future<bool> createRecipe(Map<String, dynamic> recipeData) async {
    var response = await _apiHelper.postRequest('recipes/', recipeData);
    return response != null;
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

  Future<bool> deleteRecipe(int recipeId) async {
    return await _apiHelper.deleteRequest('recipes/$recipeId/');
  }

  Future<bool> isRecipeSaved(int recipeId) async {
    var response = await _apiHelper.getRequest('recipes/$recipeId/is_saved/');

    if (response != null && response.containsKey('is_saved')) {
      return response['is_saved'];
    }
    return false;
  }

  Future<Map<String, dynamic>?> uploadRecipeImage(File image) async {
    var response = await _apiHelper.uploadFile(
      'recipes/ocr/',
      image,
    );

    return response;
  }
}
