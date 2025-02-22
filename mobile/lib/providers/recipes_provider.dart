import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/api/recipe_api.dart';
import 'package:mobile/models/recipe_preview/recipe_preview.dart';

class RecipesProvider with ChangeNotifier {
  List<RecipePreview> _allRecipes = [];
  List<RecipePreview> _filteredRecipes = [];
  int _tabIndex = 0;
  Timer? _debounceTimer;
  DateTime? _lastRequestTime;

  List<RecipePreview> get allRecipes => _allRecipes;
  List<RecipePreview> get filteredRecipes => _filteredRecipes;
  int get tabIndex => _tabIndex;

  Future<void> fetchRecipes() async {
    final now = DateTime.now();

    if (_lastRequestTime != null &&
        now.difference(_lastRequestTime!).inSeconds < 2) {
      return; // Exit if the cooldown period hasn't passed
    }

    _lastRequestTime = now;

    final recipes = await RecipeApi().fetchRecipes();
    recipes.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    _allRecipes = recipes;
    _filteredRecipes = recipes;
    notifyListeners();
  }

  void setTabIndex(int index) {
    _tabIndex = index;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    switch (_tabIndex) {
      case 0: // All Recipes
        _filteredRecipes = _allRecipes;
        break;
      case 1: // Recent Recipes
        _filteredRecipes = _allRecipes
            .where((recipe) => recipe.last_visited_at != null)
            .toList()
          ..sort((a, b) => b.last_visited_at!.compareTo(a.last_visited_at!));
        break;
      case 2: // Favorites
        _filteredRecipes =
            _allRecipes.where((recipe) => recipe.is_favorite == true).toList();
        break;
    }
    notifyListeners();
  }

  void onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.isEmpty) {
        _filteredRecipes = _allRecipes;
      } else {
        _filteredRecipes = _allRecipes
            .where((recipe) =>
                recipe.title.toLowerCase().contains(query.toLowerCase()) ||
                (recipe.tags ?? []).any(
                    (tag) => tag.toLowerCase().contains(query.toLowerCase())))
            .toList();
      }
      notifyListeners();
    });
  }
}
