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
}
