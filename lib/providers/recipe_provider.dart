import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_generator_service.dart';

enum RecipeStatus { idle, loading, success, error }

class RecipeProvider with ChangeNotifier {
  final RecipeGeneratorService _generatorService = RecipeGeneratorService();

  RecipeStatus _status = RecipeStatus.idle;
  Recipe? _recipe;
  String? _error;
  
  // Set default api key from environment if defined
  String _apiKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  RecipeStatus get status => _status;
  Recipe? get recipe => _recipe;
  String? get error => _error;
  String get apiKey => _apiKey;
  bool get hasApiKey => _apiKey.isNotEmpty;

  void setApiKey(String key) {
    _apiKey = key.trim();
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
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _status = RecipeStatus.error;
      notifyListeners();
    }
  }

  void reset() {
    _recipe = null;
    _status = RecipeStatus.idle;
    _error = null;
    notifyListeners();
  }
}
