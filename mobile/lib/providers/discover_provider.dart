import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/recommendation_api.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';

class DiscoverProvider with ChangeNotifier {
  List<RecipePreview> _recommendedRecipes = [];
  bool _isLoading = false;
  DateTime? _lastFetchTime;

  List<RecipePreview> get recommendedRecipes => _recommendedRecipes;
  bool get isLoading => _isLoading;

  Future<void> fetchRecommendedRecipes() async {
    final now = DateTime.now();

    if (_lastFetchTime != null &&
        now.difference(_lastFetchTime!).inMinutes < 1) {
      return; // Exit if less than 1 minute has passed since the last fetch
    }

    _isLoading = true;
    notifyListeners();

    try {
      final recipes = await RecommendationsApi().fetchRecommendedRecipes();
      _recommendedRecipes = recipes;
      _lastFetchTime = now;
      print(_lastFetchTime);
    } catch (e) {
      print('Error fetching recommended recipes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
