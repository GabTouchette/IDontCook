import 'package:flutter/material.dart';

class RecipeDetailProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _recipe;

  bool get isLoading => _isLoading;
  String? get recipe => _recipe;

  Future<void> fetchRecipe() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(Duration(seconds: 2));

    _recipe = "Delicious Recipe";

    _isLoading = false;
    notifyListeners();
  }
}
