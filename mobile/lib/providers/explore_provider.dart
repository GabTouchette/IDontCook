import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/explore_api.dart';
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
    'prepTime': 60.0,
    'cookTime': 60.0,
    'cuisine': 'Any',
    'calories': RangeValues(0, 1000),
    'excludeAIGenerated': false,
    'excludeOwnRecipes': true,
    'selectedTags': [],
    'currentlyExpandedCategory': '',
  };

  bool get isLoading => _isLoading;
  Map<String, dynamic> get filters => _filters;

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

    params['prep_time'] = _filters['prepTime'].toString();
    params['cook_time'] = _filters['cookTime'].toString();
    params['calories_min'] = _filters['calories'].start.toString();
    params['calories_max'] = _filters['calories'].end.toString();
    params['exclude_ai_generated'] = _filters['excludeAIGenerated'].toString();
    params['exclude_own_recipes'] = _filters['excludeOwnRecipes'].toString();

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

  /// Refresh resets pagination and reloads data
  Future<void> refresh() async {
    await fetchInitialItems();
  }

  void clearFilters() {
    _filters = {
      'prepTime': 60.0,
      'cookTime': 60.0,
      'cuisine': 'Any',
      'calories': RangeValues(0, 1000),
      'excludeAIGenerated': false,
      'excludeOwnRecipes': true,
      'selectedTags': [],
      'currentlyExpandedCategory': '',
    };
    notifyListeners();
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
    // Default values that indicate no filtering
    final defaultFilters = {
      'prepTime': 60.0,
      'cookTime': 60.0,
      'cuisine': 'Any',
      'calories': RangeValues(0, 1000),
      'excludeAIGenerated': false,
      'excludeOwnRecipes': true,
      'selectedTags': [],
    };
    
    // Check if any filter differs from default
    return _filters['prepTime'] != defaultFilters['prepTime'] ||
           _filters['cookTime'] != defaultFilters['cookTime'] ||
           _filters['cuisine'] != defaultFilters['cuisine'] ||
           _filters['calories'].start != (defaultFilters['calories'] as RangeValues).start ||
           _filters['calories'].end != (defaultFilters['calories'] as RangeValues).end ||
           _filters['excludeAIGenerated'] != defaultFilters['excludeAIGenerated'] ||
           _filters['excludeOwnRecipes'] != defaultFilters['excludeOwnRecipes'] ||
           (_filters['selectedTags'] as List).isNotEmpty;
  }

  void disposeProvider() {
    disposeScroll();
    disposeSearch();
  }
}
