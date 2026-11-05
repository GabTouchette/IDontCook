import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/grocery_api.dart';
import 'package:i_cant_cook/models/grocery/grocery_models.dart';

/// State for the Grocery Bag: queued recipes + the derived shoppable list.
///
/// The list itself is computed server-side (grocery.aggregator) and returned by
/// every call, so the provider just mirrors the latest payload. Staple sorting
/// (backend Part C1) and the confirm step (Part D2) layer on later.
class GroceryBagProvider with ChangeNotifier {
  final GroceryApi _api = GroceryApi();

  GroceryBag _bag = GroceryBag();
  bool _hasLoaded = false;
  bool _isLoading = false;
  bool _isMutating = false;
  String? _error;

  GroceryBag get bag => _bag;
  List<ShoppableLine> get items => _bag.items;
  List<ShoppableLine> get hiddenItems => _bag.hiddenItems;
  List<BagRecipe> get recipes => _bag.recipes;
  bool get hasLoaded => _hasLoaded;
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  bool get isEmpty => _bag.isEmpty;
  int get itemCount => _bag.itemCount;
  int get removedCount => _bag.removedCount;
  int get hiddenCount => _bag.hiddenCount;
  String? get error => _error;

  void _apply(Map<String, dynamic>? json) {
    if (json != null) {
      _bag = GroceryBag.fromJson(json);
      _error = null;
    }
  }

  Future<void> fetchBag() async {
    _isLoading = true;
    notifyListeners();
    final json = await _api.getBag();
    if (json != null) {
      _apply(json);
    } else {
      _error = 'Could not load your grocery bag.';
    }
    _isLoading = false;
    _hasLoaded = true;
    notifyListeners();
  }

  /// Adds a recipe to the bag. Returns true on success. Refetches the full bag
  /// (the add endpoint returns only the bag-recipe, not the recomputed list).
  Future<bool> addRecipe(int recipeId, {int? servings}) async {
    _isMutating = true;
    notifyListeners();
    final res = await _api.addRecipe(recipeId, servings: servings);
    bool ok = res != null;
    if (ok) {
      final json = await _api.getBag();
      _apply(json);
    } else {
      _error = 'Could not add to your grocery bag.';
    }
    _isMutating = false;
    notifyListeners();
    return ok;
  }

  Future<void> setServings(int bagRecipeId, int servings) async {
    final res = await _api.updateServings(bagRecipeId, servings);
    if (res != null) {
      final json = await _api.getBag();
      _apply(json);
      notifyListeners();
    }
  }

  Future<void> removeRecipe(int bagRecipeId) async {
    final ok = await _api.removeRecipe(bagRecipeId);
    if (ok) {
      final json = await _api.getBag();
      _apply(json);
      notifyListeners();
    }
  }

  Future<void> removeItem(String key) async {
    _apply(await _api.setItem(key, state: 'removed'));
    notifyListeners();
  }

  Future<void> toggleChecked(String key, bool checked) async {
    _apply(await _api.setItem(key, state: checked ? 'checked' : null));
    notifyListeners();
  }

  Future<void> emptyBag() async {
    final ok = await _api.emptyBag();
    if (ok) {
      _bag = GroceryBag();
      notifyListeners();
    }
  }

  /// Toggle "I always have this" (pantry). Sinks the item to the bottom.
  Future<void> setPantry(String key, bool inPantry) async {
    _apply(await _api.setPantry(key, inPantry));
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> searchCanonical(String q) {
    return _api.searchCanonical(q);
  }

  /// Confirm step: link an unresolved/low-confidence line to a canonical concept.
  Future<void> resolveItem(String key, int conceptId) async {
    _apply(await _api.resolveItem(key, conceptId));
    notifyListeners();
  }
}
