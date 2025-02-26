import 'package:flutter/material.dart';
import 'package:i_cant_cook/providers/auth_provider.dart';
import 'package:i_cant_cook/providers/discover_provider.dart';
import 'package:i_cant_cook/providers/explore_provider.dart';
import 'package:i_cant_cook/providers/global_recipe_search_provider.dart';
import 'package:i_cant_cook/providers/recipe_detail_provider.dart';
import 'package:i_cant_cook/providers/recipes_provider.dart';
import 'package:i_cant_cook/providers/user_profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:i_cant_cook/routes.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => RecipeDetailProvider()),
        ChangeNotifierProvider(create: (context) => RecipesProvider()),
        ChangeNotifierProvider(create: (context) => ExploreProvider()),
        ChangeNotifierProvider(create: (context) => UserProfileProvider()),
        ChangeNotifierProvider(create: (context) => DiscoverProvider()),
        ChangeNotifierProvider(create: (_) => RecipeSearchProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
