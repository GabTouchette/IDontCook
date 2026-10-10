import 'package:i_cant_cook/api/api_helper.dart';
import 'package:i_cant_cook/models/paginated_recipes/paginated_recipes.dart';

class ExploreApi {
  final ApiHelper _apiHelper = ApiHelper();

  /// Fetch paginated filtered & recommended recipes from the unified endpoint.
  Future<PaginatedRecipes> fetchFilteredRecommendations({
    int page = 1,
    Map<String, String>? filters,
  }) async {
    // Build query params including page + filters
    final queryParams = <String, String>{'page': page.toString()};
    if (filters != null && filters.isNotEmpty) {
      queryParams.addAll(filters);
    }

    final data = await _apiHelper.getRequest(
      'recipes/global/filter/',
      queryParams: queryParams,
    );

    if (data != null) {
      return PaginatedRecipes.fromJson(data);
    }

    return PaginatedRecipes(results: [], next: null, count: 0);
  }

  /// Record a thumbs-up (upvote) or thumbs-down (downvote) on a recipe.
  /// Returns true if the interaction is now active, false if it was toggled off.
  Future<bool> recordInteraction(int recipeId, String interactionType) async {
    final data = await _apiHelper.postRequest(
      'recipes/$recipeId/interact/',
      {'interaction_type': interactionType},
    );
    return data?['active'] == true;
  }

  /// Record a "click" — the user opened this recipe's detail. Weak,
  /// recency-weighted ranking signal; append-only and fire-and-forget.
  Future<void> recordClick(int recipeId) async {
    await _apiHelper.postRequest('recipes/$recipeId/click/', {});
  }
}
