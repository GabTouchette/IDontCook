import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/api/recommendation_api.dart';
import 'package:mobile/models/recipe_preview/recipe_preview.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/widgets/appbar/appbar_user_menu.dart';
import 'package:mobile/widgets/recommendations/big_recipe_tile.dart';

class RecommendationsPage extends StatefulWidget {
  const RecommendationsPage({super.key});

  @override
  _RecommendationsPageState createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  List<RecipePreview> _recommendedRecipes = [];

  @override
  void initState() {
    super.initState();
    _fetchRecommendedRecipes();
  }

  Future<void> _fetchRecommendedRecipes() async {
    final recipes = await RecommendationsApi().fetchRecommendedRecipes();

    setState(() {
      _recommendedRecipes = recipes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        title: Text(
          'Recommendations',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 32,
            color: ColorPalette.offWhite,
          ),
        ),
        actions: [
          UserMenuWidget(),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/recipes_page_background.png',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 100.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 32.0),
                  child: Text(
                    'Here are some recipes that we think you may like based on your preferences.',
                    style: TextStyle(
                      color: ColorPalette.offWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.w200,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 16.0),
                Expanded(
                  child: _recommendedRecipes.isEmpty
                      ? Center(
                          child: Text('No recommendations available.',
                              style: TextStyle(color: ColorPalette.offWhite)))
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: _recommendedRecipes.length,
                          itemBuilder: (context, index) {
                            final recipe = _recommendedRecipes[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                BigRecipeTile(
                                  recipe: recipe,
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
