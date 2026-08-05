import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/ingredient_provider.dart';
import 'providers/recipe_provider.dart';
import 'views/main_navigation_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => IngredientProvider()),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
      ],
      child: const SmartFoodCalApp(),
    ),
  );
}

class SmartFoodCalApp extends StatelessWidget {
  const SmartFoodCalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Ingredients & Recipe Generator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigationScreen(),
    );
  }
}
