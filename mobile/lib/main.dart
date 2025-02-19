import 'package:flutter/material.dart';
import 'package:mobile/providers/recipe_detail_provider.dart';
import 'package:provider/provider.dart';
import 'package:mobile/routes.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => RecipeDetailProvider(),
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
