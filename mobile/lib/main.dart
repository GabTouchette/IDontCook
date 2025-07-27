import 'package:flutter/material.dart';
import 'package:i_cant_cook/providers/auth_provider.dart';
import 'package:i_cant_cook/providers/settings_provider.dart';
import 'package:i_cant_cook/providers/social_provider.dart';
import 'package:i_cant_cook/providers/explore_provider.dart';
import 'package:i_cant_cook/providers/recipe_detail_provider.dart';
import 'package:i_cant_cook/providers/user_recipes_provider.dart';
import 'package:i_cant_cook/providers/user_profile_provider.dart';
import 'package:i_cant_cook/providers/chat_provider.dart';

import 'package:i_cant_cook/routes.dart';
import 'package:i_cant_cook/theme/theme.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => RecipeDetailProvider()),
        ChangeNotifierProvider(create: (context) => UserRecipesProvider()),
        ChangeNotifierProvider(create: (context) => SocialProvider()),
        ChangeNotifierProvider(create: (context) => UserProfileProvider()),
        ChangeNotifierProvider(create: (context) => ExploreProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
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
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      onGenerateRoute: generateRoute,
    );
  }
}
