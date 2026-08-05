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

  RecipeProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiKey = prefs.getString('gemini_api_key') ?? const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
      _userName = prefs.getString('user_name') ?? '';
      
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
}
