import 'dart:async';
import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/recipe_api.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';
import 'package:i_cant_cook/mixins/search_mixin.dart';

class UserRecipesProvider with ChangeNotifier, SearchMixin {
  List<RecipePreview> _allRecipes = [];
  List<RecipePreview> _filteredRecipes = [];
  int _tabIndex = 0;
  String? _selectedTag;
  DateTime? _lastRequestTime;

  int tileMode = 1; // 0 = small, 1 = medium, 2 = large

  List<RecipePreview> get allRecipes => _allRecipes;
  List<RecipePreview> get filteredRecipes => _filteredRecipes;
  int get tabIndex => _tabIndex;
  String? get selectedTag => _selectedTag;

  List<String> get userTags {
    final Map<String, int> tagCounts = {};
    for (var recipe in _allRecipes) {
      final tags = recipe.tags ?? [];
      for (var tag in tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
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
      return;
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
    if (index != 3) _selectedTag = null;
    _applyFilters();
    notifyListeners();
  }

  void setSelectedTag(String? tag) {
    _selectedTag = tag;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    List<RecipePreview> baseList;

    switch (_tabIndex) {
      case 1:
        baseList = _allRecipes.where((r) => r.last_visited_at != null).toList()
          ..sort((a, b) => b.last_visited_at!.compareTo(a.last_visited_at!));
        break;
      case 2:
        baseList = _allRecipes.where((r) => r.is_favorite == true).toList();
        break;
      case 3:
        baseList = _selectedTag == null
            ? []
            : _allRecipes
                .where((r) => (r.tags ?? []).contains(_selectedTag))
                .toList();
        break;
      default:
        baseList = _allRecipes;
    }

    final query = searchQuery.toLowerCase();
    if (query.isEmpty) {
      _filteredRecipes = baseList;
    } else {
      _filteredRecipes = baseList
          .where((r) =>
              r.title.toLowerCase().contains(query) ||
              (r.tags ?? []).any((tag) => tag.toLowerCase().contains(query)))
          .toList();
    }
  }

  void onSearchTextChanged(String text) {
    onSearchChanged(text, (_) {
      _applyFilters();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    disposeSearch();
    super.dispose();
  }
}
