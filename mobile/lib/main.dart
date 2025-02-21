import 'package:flutter/material.dart';
import 'package:mobile/providers/explore_provider.dart';
import 'package:mobile/providers/recipe_detail_provider.dart';
import 'package:mobile/providers/recipes_provider.dart';
import 'package:provider/provider.dart';
import 'package:mobile/routes.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => RecipeDetailProvider()),
        ChangeNotifierProvider(create: (context) => RecipesProvider()),
        ChangeNotifierProvider(create: (context) => ExploreProvider()),
      ],
      child: ICantCook(),
    ),
  );
}

class ICantCook extends StatelessWidget {
  const ICantCook({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ICantCook',
      theme: ThemeData.light(),
      initialRoute: '/',
      onGenerateRoute: generateRoute,
    );
  }
}
