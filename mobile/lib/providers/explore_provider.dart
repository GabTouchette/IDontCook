import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/explore_api.dart';
import 'package:i_cant_cook/api/recipe_api.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';
import 'package:i_cant_cook/mixins/pagination_mixin.dart';
import 'package:i_cant_cook/mixins/scroll_mixin.dart';
import 'package:i_cant_cook/mixins/search_mixin.dart';

class ExploreProvider
    with
        ChangeNotifier,
        PaginationMixin<RecipePreview>,
        ScrollMixin,
        SearchMixin {
  bool _isLoading = false;
  Map<String, dynamic> _filters = {
    'totalTime': 0,
    'cuisine': 'Any',
    'maxCalories': 0,
    'excludeAIGenerated': false,
    'excludeOwnRecipes': true,
    'selectedTags': [],
    'currentlyExpandedCategory': '',
  };

  bool get isLoading => _isLoading;
  Map<String, dynamic> get filters => _filters;

  // Per-session variety seed: stable across pages of one browse session (so
  // pagination stays consistent) and regenerated on pull-to-refresh so the feed
  // reshuffles. The backend uses it for the ranker's band-shuffle + exploration
  // slice (docs/plans/recommendation-algo-v2.md §3).
  int _seed = DateTime.now().millisecondsSinceEpoch % 1000000000;

  String _lastListenerText = '';

  ExploreProvider() {
    // Initialize scroll listener to load next page on scroll
    initScrollListener(() {
      fetchNextPage();
    });

    // Listen to search input changes with debounce.
    // Only react when text changes, not on cursor/selection changes.
    searchController.addListener(() {
      final currentText = searchController.text;
      if (currentText != _lastListenerText) {
        _lastListenerText = currentText;
        onSearchChanged(currentText, (_) => refresh());
      }
    });

    // Initial load
    fetchInitialItems();
  }

  /// Compose query params from filters + searchQuery + page
  Map<String, String> _composeQueryParams(int page) {
    final params = <String, String>{'page': page.toString()};

    if (searchQuery.isNotEmpty) {
      params['search'] = searchQuery;
    }

    if (_filters['selectedTags'].isNotEmpty) {
      params['tags'] = (_filters['selectedTags'] as List<String>).join(',');
    }

    params['total_time'] = _filters['totalTime'].toString();
    params['max_calories'] = _filters['maxCalories'].toString();
    params['exclude_ai_generated'] = _filters['excludeAIGenerated'].toString();
    params['exclude_own_recipes'] = _filters['excludeOwnRecipes'].toString();
    params['seed'] = _seed.toString();

    return params;
  }

  /// PaginationMixin requires this to fetch items by page
  @override
  Future<List<RecipePreview>> fetchItems(int page) async {
    _isLoading = true;
    notifyListeners();

    try {
      final queryParams = _composeQueryParams(page);
      final paginated = await ExploreApi().fetchFilteredRecommendations(
        page: page,
        filters: queryParams,
      );
      setNextPageUrl(paginated.next);
      return paginated.results;
    } catch (e) {
      print('Error fetching recipes: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh resets pagination and reloads data. A new variety seed is minted so
  /// the recommendation feed reshuffles (new order + fresh exploration picks)
  /// rather than returning the exact same ranking.
  Future<void> refresh() async {
    _seed = DateTime.now().millisecondsSinceEpoch % 1000000000;
    await fetchInitialItems();
  }

  void clearFilters() {
    _filters = {
      'totalTime': 0,
      'cuisine': 'Any',
      'maxCalories': 0,
      'excludeAIGenerated': false,
      'excludeOwnRecipes': true,
      'selectedTags': [],
      'currentlyExpandedCategory': '',
    };
    notifyListeners();
    refresh();
  }

  /// Clears the search text and reloads the unfiltered feed. Called when the
  /// page is left so a stale query doesn't persist to the next visit. (We refresh
  /// explicitly because clearSearch() resets the debounce baseline, which would
  /// otherwise suppress the controller-listener's own refresh.)
  void resetSearch() {
    if (searchController.text.isEmpty && searchQuery.isEmpty) return;
    clearSearch();
    refresh();
  }

  void updateFilter(String key, dynamic value) {
    _filters[key] = value;
    notifyListeners();
  }

  void addTag(String tag) {
    if (!_filters["selectedTags"].contains(tag)) {
      _filters["selectedTags"].add(tag);
      notifyListeners();
    }
  }

  void removeTag(String tag) {
    _filters["selectedTags"].remove(tag);
    notifyListeners();
  }

  bool get hasActiveFilters {
    return _filters['totalTime'] != 0 ||
           _filters['cuisine'] != 'Any' ||
           _filters['maxCalories'] != 0 ||
           _filters['excludeAIGenerated'] != false ||
           _filters['excludeOwnRecipes'] != true ||
           (_filters['selectedTags'] as List).isNotEmpty;
  }

  void disposeProvider() {
    disposeScroll();
    disposeSearch();
  }

  // ── Feedback ──────────────────────────────────────────────────────────────

  /// Remove a recipe from the current list immediately (optimistic UI).
  void removeItem(int recipeId) {
    items.removeWhere((r) => r.id == recipeId);
    notifyListeners();
  }

  /// Record a thumbs-up — does NOT remove the recipe from the list.
  Future<void> recordUpvote(int recipeId) async {
    await ExploreApi().recordInteraction(recipeId, 'upvote');
  }

  /// Record a thumbs-down and hide the recipe from the current list.
  Future<void> recordDownvote(int recipeId) async {
    removeItem(recipeId);
    await ExploreApi().recordInteraction(recipeId, 'downvote');
  }

  /// Record that the user opened a recipe (weak ranking signal).
  /// Fire-and-forget: never blocks navigation and swallows failures.
  Future<void> recordClick(int recipeId) async {
    try {
      await ExploreApi().recordClick(recipeId);
    } catch (_) {
      // Weak signal — a failed click log must never affect the UX.
    }
  }

  /// Delete the recipe from the database and remove it from the list.
  /// Returns true on success. On failure the item is re-inserted at its
  /// original position so the list stays consistent with the backend.
  Future<bool> adminDeleteRecipe(int recipeId) async {
    // Capture position for rollback
    int? originalIndex;
    RecipePreview? original;
    for (int i = 0; i < items.length; i++) {
      if (items[i].id == recipeId) {
        originalIndex = i;
        original = items[i];
        break;
      }
    }

    // Optimistic removal
    removeItem(recipeId);

    final success = await RecipeApi().deleteRecipe(recipeId);

    if (!success && original != null && originalIndex != null) {
      // Rollback: re-insert at original position
      items.insert(originalIndex, original);
      notifyListeners();
    }

    return success;
  }
}
