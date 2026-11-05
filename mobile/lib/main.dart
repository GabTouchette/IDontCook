import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/auth_api.dart';
import 'package:i_cant_cook/models/user/user.dart';
import 'package:i_cant_cook/providers/auth_provider.dart';
import 'package:i_cant_cook/providers/settings_provider.dart';
import 'package:i_cant_cook/providers/social_provider.dart';
import 'package:i_cant_cook/providers/explore_provider.dart';
import 'package:i_cant_cook/providers/recipe_detail_provider.dart';
import 'package:i_cant_cook/providers/user_recipes_provider.dart';
import 'package:i_cant_cook/providers/user_profile_provider.dart';
import 'package:i_cant_cook/providers/chat_provider.dart';
import 'package:i_cant_cook/providers/theme_provider.dart';
import 'package:i_cant_cook/providers/meal_plan_provider.dart';
import 'package:i_cant_cook/providers/home_feed_provider.dart';
import 'package:i_cant_cook/providers/grocery_bag_provider.dart';

import 'package:i_cant_cook/routes.dart';
import 'package:i_cant_cook/theme/theme.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final User? user = await AuthApi.getUser();

  // Already authenticated → go straight to the app.
  // Not authenticated → start at onboarding (welcome + auth).
  final String initialRoute = user != null ? '/recipes' : '/onboarding';

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
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
        ChangeNotifierProvider(create: (_) => MealPlanProvider()),
        ChangeNotifierProvider(create: (_) => HomeFeedProvider()),
        ChangeNotifierProvider(create: (_) => GroceryBagProvider()),
      ],
      child: ICantCook(initialRoute: initialRoute),
    ),
  );
}

class ICantCook extends StatelessWidget {
  final String initialRoute;
  const ICantCook({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'ICantCook',
          theme: lightTheme(),
          darkTheme: darkTheme(),
          themeMode: themeProvider.themeMode,
          initialRoute: initialRoute,
          onGenerateRoute: generateRoute,
          builder: (context, child) => GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: child!,
          ),
        );
      },
    );
  }
}
