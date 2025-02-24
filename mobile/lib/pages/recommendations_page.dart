import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:i_cant_cook/providers/recommendations_provider.dart';
import 'package:i_cant_cook/widgets/recommendations/big_recipe_tile.dart';
import 'package:i_cant_cook/theme/colors.dart';
import 'package:i_cant_cook/widgets/appbar/appbar_user_menu.dart';

class RecommendationsPage extends StatelessWidget {
  const RecommendationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RecommendationsProvider()..fetchRecommendedRecipes(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          centerTitle: true,
          elevation: 0,
          title: Text(
            'Discover',
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
        body: Consumer<RecommendationsProvider>(
          builder: (context, provider, child) {
            return Stack(
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
                      const SizedBox(height: 16.0),
                      Expanded(
                        child: provider.isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: ColorPalette.offWhite,
                                ),
                              )
                            : provider.recommendedRecipes.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No recommendations available.',
                                      style: TextStyle(
                                          color: ColorPalette.offWhite),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: provider.recommendedRecipes.length,
                                    itemBuilder: (context, index) {
                                      final recipe =
                                          provider.recommendedRecipes[index];
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
            );
          },
        ),
      ),
    );
  }
}