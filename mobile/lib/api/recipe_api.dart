import 'dart:io';

import 'package:i_cant_cook/api/api_helper.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';

class RecipeApi {
  final ApiHelper _apiHelper = ApiHelper();

  Future<List<RecipePreview>> fetchRecipes() async {
    var data = await _apiHelper.getRequest('recipes/');
    if (data != null) {
      print(data);
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
}
