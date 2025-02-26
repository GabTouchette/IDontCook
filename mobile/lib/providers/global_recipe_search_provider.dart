import 'dart:async';

import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/recipe_api.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';

class RecipeSearchProvider with ChangeNotifier {
  List<RecipePreview> _filteredRecipes = [];
  Timer? _debounceTimer;

  String _searchQuery = '';
  Map<String, dynamic> _filters = {
    'prepTime': 0.0,
    'cookTime': 0.0,
    'cuisine': 'Any',
    'calories': RangeValues(0, 1000),
    'excludeAIGenerated': false,
    'excludeOwnRecipes': true,
    'selectedTags': [],
    'currentlyExpandedCategory': '',
  };

  List<RecipePreview> get filteredRecipes => _filteredRecipes;
  String get searchQuery => _searchQuery;
  Map<String, dynamic> get filters => _filters;

  Future<void> applyFilters() async {
    final Map<String, String> queryParams = {};

    if (_searchQuery.isNotEmpty) {
      queryParams['search'] = _searchQuery;
    }

    if (_filters['selectedTags'].isNotEmpty) {
      queryParams['tags'] =
          (_filters['selectedTags'] as List<String>).join(',');
    }

    if (_filters['prepTime'] > 0) {
      queryParams['prep_time'] = _filters['prepTime'].toString();
    }

    if (_filters['cookTime'] > 0) {
      queryParams['cook_time'] = _filters['cookTime'].toString();
    }

    queryParams['calories_min'] = _filters['calories'].start.toString();
    queryParams['calories_max'] = _filters['calories'].end.toString();

    queryParams['exclude_ai_generated'] =
        _filters['excludeAIGenerated'].toString();

    queryParams['exclude_own_recipes'] =
        _filters['excludeOwnRecipes'].toString();

    _filteredRecipes = await RecipeApi().getGlobalFilteredRecipes(queryParams);
    notifyListeners();
  }

  void onSearchChanged(String query) {
    _searchQuery = query;

    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      applyFilters();
    });
  }

  void updateFilter(String key, dynamic value) {
    _filters[key] = value;
    notifyListeners();
  }

  void addTag(String tag) {
    if (!_filters["selectedTags"].contains(tag)) {
      _filters["selectedTags"].add(tag);
    }
    notifyListeners();
  }

  void removeTag(String tag) {
    _filters["selectedTags"].remove(tag);
    notifyListeners();
  }

  void clearFilters() {
    _filters = {
      'prepTime': 60,
      'cookTime': 120,
      'cuisine': 'Any',
      'calories': RangeValues(0, 1000),
      'excludeAIGenerated': false,
      'excludeOwnRecipes': true,
      'selectedTags': [],
      'currentlyExpandedCategory': '',
    };
    notifyListeners();
  }
}
