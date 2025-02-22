import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/recommendation_api.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';

class RecommendationsProvider with ChangeNotifier {
  List<RecipePreview> _recommendedRecipes = [];
  bool _isLoading = false;

  List<RecipePreview> get recommendedRecipes => _recommendedRecipes;
  bool get isLoading => _isLoading;

  Future<void> fetchRecommendedRecipes() async {
    _isLoading = true;
    notifyListeners();

    try {
      if(_recommendedRecipes.isNotEmpty) return;

      final recipes = await RecommendationsApi().fetchRecommendedRecipes();
      _recommendedRecipes = recipes;
    } catch (e) {
      print('Error fetching recommended recipes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}