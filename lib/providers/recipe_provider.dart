import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';
import '../services/recipe_generator_service.dart';

enum RecipeStatus { idle, loading, success, error }

class RecipeProvider with ChangeNotifier {
  final RecipeGeneratorService _generatorService = RecipeGeneratorService();

  RecipeStatus _status = RecipeStatus.idle;
  Recipe? _recipe;
  String? _error;
  
  String _apiKey = '';
  String _userName = '';
  List<Recipe> _history = [];
  String _dietProfile = '';
  List<String> _allergens = [];
  List<String> _shoppingList = [];

  RecipeProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiKey = prefs.getString('gemini_api_key') ?? const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
      _userName = prefs.getString('user_name') ?? '';
      _dietProfile = prefs.getString('diet_profile') ?? '';
      _allergens = prefs.getStringList('allergens') ?? [];
      _shoppingList = prefs.getStringList('shopping_list') ?? [];
      
      final String? historyJson = prefs.getString('recipe_history');
      if (historyJson != null) {
        final List decoded = json.decode(historyJson);
        _history = decoded.map((item) => Recipe.fromJson(item)).toList();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  RecipeStatus get status => _status;
  Recipe? get recipe => _recipe;
  String? get error => _error;
  String get apiKey => _apiKey;
  bool get hasApiKey => _apiKey.isNotEmpty;
  String get userName => _userName;
  bool get hasUserName => _userName.isNotEmpty;
  List<Recipe> get history => _history;
  String get dietProfile => _dietProfile;
  List<String> get allergens => _allergens;
  List<String> get shoppingList => _shoppingList;

  Future<void> setApiKey(String key) async {
    _apiKey = key.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gemini_api_key', _apiKey);
    } catch (e) {
      debugPrint('Error saving API Key: $e');
    }
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    _userName = name.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _userName);
    } catch (e) {
      debugPrint('Error saving Username: $e');
    }
    notifyListeners();
  }

  Future<void> setDietProfile(String profile) async {
    _dietProfile = profile;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('diet_profile', _dietProfile);
    } catch (e) {
      debugPrint('Error saving diet profile: $e');
    }
    notifyListeners();
  }

  Future<void> toggleAllergen(String allergen) async {
    if (_allergens.contains(allergen)) {
      _allergens.remove(allergen);
    } else {
      _allergens.add(allergen);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('allergens', _allergens);
    } catch (e) {
      debugPrint('Error saving allergens: $e');
    }
    notifyListeners();
  }

  Future<void> setAllergens(List<String> list) async {
    _allergens = List.from(list);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('allergens', _allergens);
    } catch (e) {
      debugPrint('Error saving allergens: $e');
    }
    notifyListeners();
  }

  /// Triggers the recipe generation from Gemini using the [selectedIngredients].
  Future<void> generateRecipe(List<String> selectedIngredients) async {
    if (selectedIngredients.isEmpty) {
      _error = 'Lütfen tarif üretmek için en az bir malzeme seçin.';
      _status = RecipeStatus.error;
      notifyListeners();
      return;
    }

    _status = RecipeStatus.loading;
    _error = null;
    _recipe = null;
    notifyListeners();

    try {
      final generatedRecipe = await _generatorService.generateRecipe(
        selectedIngredients: selectedIngredients,
        apiKey: _apiKey,
        dietProfile: _dietProfile,
        allergens: _allergens,
      );
      _recipe = generatedRecipe;
      _status = RecipeStatus.success;
      
      // Add successfully generated recipe to history (insert at start)
      _history.insert(0, generatedRecipe);
      _saveHistoryToPrefs();
      
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _status = RecipeStatus.error;
      notifyListeners();
    }
  }

  /// Deletes a recipe from the history at [index].
  Future<void> deleteRecipe(int index) async {
    if (index >= 0 && index < _history.length) {
      _history.removeAt(index);
      await _saveHistoryToPrefs();
      notifyListeners();
    }
  }

  Future<void> _saveHistoryToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = json.encode(_history.map((r) => r.toJson()).toList());
      await prefs.setString('recipe_history', encoded);
    } catch (e) {
      debugPrint('Error saving history to preferences: $e');
    }
  }

  void setRecipe(Recipe selectedRecipe) {
    _recipe = selectedRecipe;
    _status = RecipeStatus.success;
    _error = null;
    notifyListeners();
  }

  void reset() {
    _recipe = null;
    _status = RecipeStatus.idle;
    _error = null;
    notifyListeners();
  }

  Future<void> addIngredientsToShoppingList(List<String> ingredients) async {
    for (var ing in ingredients) {
      final trimmed = ing.trim();
      if (trimmed.isNotEmpty && !_shoppingList.any((item) => item.toLowerCase() == trimmed.toLowerCase())) {
        _shoppingList.add(trimmed);
      }
    }
    await _saveShoppingListToPrefs();
  }

  Future<void> removeIngredientFromShoppingList(String ingredient) async {
    _shoppingList.removeWhere((item) => item.toLowerCase() == ingredient.toLowerCase());
    await _saveShoppingListToPrefs();
  }

  Future<void> clearShoppingList() async {
    _shoppingList.clear();
    await _saveShoppingListToPrefs();
  }

  Future<void> _saveShoppingListToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('shopping_list', _shoppingList);
    } catch (e) {
      debugPrint('Error saving shopping list: $e');
    }
    notifyListeners();
  }

  Future<void> importRecipeFromUrl(String url) async {
    _status = RecipeStatus.loading;
    _error = null;
    _recipe = null;
    notifyListeners();

    try {
      final importedRecipe = await _generatorService.importRecipeFromUrl(
        url: url,
        apiKey: _apiKey,
      );
      _recipe = importedRecipe;
      _status = RecipeStatus.success;

      // Add to history
      _history.insert(0, importedRecipe);
      await _saveHistoryToPrefs();
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _status = RecipeStatus.error;
      notifyListeners();
      rethrow;
    }
  }
}
