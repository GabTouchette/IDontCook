import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/models/recipe.dart';

class ApiService {
  final String baseUrl = 'http://192.168.0.110:8000/api';

  Future<List<Recipe>> fetchRecipes() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/recipes/'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((recipe) => Recipe.fromJson(recipe)).toList();
      } else {
        throw Exception('Failed to load recipes');
      }
    } catch (e) {
      print(e);
      throw Exception('Failed to load recipes: $e');
    }
  }
}
