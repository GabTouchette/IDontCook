import 'dart:async';
import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/recipe_api.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';

class UserRecipesProvider with ChangeNotifier {
  List<RecipePreview> _allRecipes = [];
  List<RecipePreview> _filteredRecipes = [];
  int _tabIndex = 0;
  String? _selectedTag;
  Timer? _debounceTimer;
  DateTime? _lastRequestTime;

  int tileMode = 1; // 0 = small, 1 = medium, 2 = large

  // Getters
  List<RecipePreview> get allRecipes => _allRecipes;
  List<RecipePreview> get filteredRecipes => _filteredRecipes;
  int get tabIndex => _tabIndex;
  String? get selectedTag => _selectedTag;

  List<String> get userTags {
    // Count occurrences of each tag
    final Map<String, int> tagCounts = {};

    for (var recipe in _allRecipes) {
      final tags = recipe.tags ?? [];
      for (var tag in tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    // Get all unique tags and sort by their count (descending)
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTags.map((entry) => entry.key).toList();
  }

  void setTileMode(int mode) {
    tileMode = mode;
    notifyListeners();
  }

  Future<void> fetchRecipes() async {
    final now = DateTime.now();

    if (_lastRequestTime != null &&
        now.difference(_lastRequestTime!).inSeconds < 2) {
      return; // Exit if the cooldown period hasn't passed
    }

    _lastRequestTime = now;

    final recipes = await RecipeApi().fetchRecipes();
    recipes
        .sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    _allRecipes = recipes;
    _applyFilters();
    notifyListeners();
  }

  void setTabIndex(int index) {
    _tabIndex = index;

    // Reset selected tag when leaving Tags tab
    if (index != 3) {
      _selectedTag = null;
    }

    _applyFilters();
    notifyListeners();
  }

  void setSelectedTag(String? tag) {
    _selectedTag = tag;
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
      case 3: // Tags tab
        if (_selectedTag != null) {
          _filteredRecipes = _allRecipes
              .where((recipe) => (recipe.tags ?? []).contains(_selectedTag))
              .toList();
        } else {
          _filteredRecipes = [];
        }
        break;
      default:
        _filteredRecipes = _allRecipes;
    }
  }

  void onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      List<RecipePreview> baseList;

      // Search should apply to whatever the current base list is
      switch (_tabIndex) {
        case 1:
          baseList = _allRecipes
              .where((recipe) => recipe.last_visited_at != null)
              .toList();
          break;
        case 2:
          baseList = _allRecipes
              .where((recipe) => recipe.is_favorite == true)
              .toList();
          break;
        case 3:
          if (_selectedTag != null) {
            baseList = _allRecipes
                .where((recipe) => (recipe.tags ?? []).contains(_selectedTag))
                .toList();
          } else {
            baseList = [];
          }
          break;
        default:
          baseList = _allRecipes;
      }

      if (query.isEmpty) {
        _filteredRecipes = baseList;
      } else {
        _filteredRecipes = baseList
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
