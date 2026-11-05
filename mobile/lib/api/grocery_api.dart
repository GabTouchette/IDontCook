import 'dart:ui' as ui;

import 'package:i_cant_cook/api/api_helper.dart';

/// HTTP client for the Grocery Bag endpoints (/api/grocery/*).
class GroceryApi {
  final ApiHelper _api = ApiHelper();

  /// Device language code ('en', 'fr', …) — backend localizes display names.
  String get _lang => ui.PlatformDispatcher.instance.locale.languageCode;

  Future<Map<String, dynamic>?> getBag() async {
    final res =
        await _api.getRequest('grocery/bag/', queryParams: {'lang': _lang});
    return res == null ? null : (res as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>?> addRecipe(int recipeId, {int? servings}) async {
    final body = <String, dynamic>{'recipe_id': recipeId};
    if (servings != null) body['servings'] = servings;
    final res = await _api.postRequest('grocery/bag/recipes/', body);
    return res == null ? null : (res as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>?> updateServings(int bagRecipeId, int servings) async {
    final res = await _api.patchRequest(
      'grocery/bag/recipes/$bagRecipeId/',
      {'servings': servings},
    );
    return res == null ? null : (res as Map).cast<String, dynamic>();
  }

  Future<bool> removeRecipe(int bagRecipeId) async {
    return await _api.deleteRequest('grocery/bag/recipes/$bagRecipeId/');
  }

  /// Upsert an item override. A null [state] clears it. Returns the refreshed bag.
  Future<Map<String, dynamic>?> setItem(String key, {String? state}) async {
    final res = await _api.postRequest(
      'grocery/bag/items/',
      {'key': key, 'state': state, 'lang': _lang},
    );
    return res == null ? null : (res as Map).cast<String, dynamic>();
  }

  Future<bool> emptyBag() async {
    return await _api.deleteRequest('grocery/bag/');
  }

  /// Toggle a concept in the user's pantry ("I always have this"). Returns the bag.
  Future<Map<String, dynamic>?> setPantry(String key, bool inPantry) async {
    final res = await _api.postRequest(
      'grocery/pantry/',
      {'key': key, 'in_pantry': inPantry, 'lang': _lang},
    );
    return res == null ? null : (res as Map).cast<String, dynamic>();
  }

  /// Search canonical ingredients for the confirm picker.
  Future<List<Map<String, dynamic>>> searchCanonical(String q) async {
    final res = await _api.getRequest(
      'grocery/bag/resolve/search/',
      queryParams: {'q': q},
    );
    if (res == null) return [];
    final results = (res as Map)['results'] as List? ?? [];
    return results.map((r) => (r as Map).cast<String, dynamic>()).toList();
  }

  /// Previously-learned product matches for [keys] at [grocer] (the recall
  /// half — lets the Order flow skip search + scoring on repeat fills).
  /// Returns a map of line key → {code, title, uom} for hits only.
  Future<Map<String, Map<String, dynamic>>> cachedMatches(
      String grocer, List<String> keys) async {
    if (keys.isEmpty) return {};
    final res = await _api.postRequest(
      'grocery/match/cached/',
      {'grocer': grocer, 'keys': keys},
    );
    final matches = res == null ? null : (res as Map)['matches'] as Map?;
    if (matches == null) return {};
    return matches.map(
      (k, v) => MapEntry(k.toString(), (v as Map).cast<String, dynamic>()),
    );
  }

  /// Remember the products chosen during a fill so the next fill reads them
  /// from cache. [matches] is a list of {key, code, title, uom}. Fire-and-forget.
  Future<void> learnMatches(
      String grocer, List<Map<String, dynamic>> matches) async {
    if (matches.isEmpty) return;
    await _api.postRequest(
      'grocery/match/learn/',
      {'grocer': grocer, 'matches': matches},
    );
  }

  /// Link a needs-confirmation line to a canonical concept. Returns the bag.
  Future<Map<String, dynamic>?> resolveItem(String key, int conceptId) async {
    final res = await _api.postRequest(
      'grocery/bag/resolve/',
      {'key': key, 'concept_id': conceptId, 'lang': _lang},
    );
    return res == null ? null : (res as Map).cast<String, dynamic>();
  }
}
