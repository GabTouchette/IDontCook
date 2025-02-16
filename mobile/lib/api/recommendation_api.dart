import 'package:mobile/api/api_helper.dart';
import 'package:mobile/models/recipe_preview/recipe_preview.dart';

class RecommendationsApi {
  final ApiHelper _apiHelper = ApiHelper();

  Future<List<RecipePreview>> fetchRecommendedRecipes() async {
    var data = await _apiHelper.getRequest('recommendations');
    if (data != null) {
      print(data);
      return (data["recommendations"] as List)
          .map((recipe) => RecipePreview.fromJson(recipe))
          .toList();
    }
    return [];
  }
}
