import 'package:flutter/material.dart';
import '../core/constants/default_ingredients.dart';
import '../models/ingredient.dart';
import '../services/food_validation_service.dart';

class IngredientProvider with ChangeNotifier {
  final FoodValidationService _validationService = FoodValidationService();

  final List<Ingredient> _ingredients = List.from(kInitialIngredients);
  String _searchQuery = '';
  bool _isValidating = false;
  String? _validationError;
  List<String> _suggestions = [];
  bool _isLoadingSuggestions = false;

  List<Ingredient> get ingredients => _ingredients;
  String get searchQuery => _searchQuery;
  bool get isValidating => _isValidating;
  String? get validationError => _validationError;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleIngredient(String id) {
    final index = _ingredients.indexWhere((item) => item.id == id);
    if (index != -1) {
      _ingredients[index].isSelected = !_ingredients[index].isSelected;
      notifyListeners();
    }
  }

  List<String> get selectedIngredientNames {
    return _ingredients
        .where((item) => item.isSelected)
        .map((item) => item.name)
        .toList();
  }

  /// Returns sorted list of unique categories present in the filtered ingredients list.
  List<String> get categories {
    final Set<String> cats = {};
    for (var ing in filteredIngredients) {
      cats.add(ing.category);
    }
    return cats.toList()..sort();
  }

  /// Returns ingredients filtered by search query.
  List<Ingredient> get filteredIngredients {
    if (_searchQuery.trim().isEmpty) {
      return _ingredients;
    }
    return _ingredients
        .where((item) =>
            item.name.toLowerCase().contains(_searchQuery.toLowerCase().trim()))
        .toList();
  }

  /// Returns filtered ingredients belonging to a specific category.
  List<Ingredient> getIngredientsByCategory(String category) {
    return filteredIngredients.where((item) => item.category == category).toList();
  }

  /// Validates a custom ingredient name via Open Food Facts API and adds it.
  Future<bool> addCustomIngredient(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return false;

    // Check if ingredient already exists in list (case-insensitive)
    final exists = _ingredients.any(
      (item) => item.name.toLowerCase() == trimmedName.toLowerCase(),
    );
    if (exists) {
      _validationError = 'Bu malzeme zaten listede mevcut.';
      notifyListeners();
      return false;
    }

    _isValidating = true;
    _validationError = null;
    notifyListeners();

    try {
      final isValid = await _validationService.validateIngredient(trimmedName);
      if (isValid) {
        // Capitalize first letter of the name
        final capitalizedName = trimmedName[0].toUpperCase() + trimmedName.substring(1);
        final newIng = Ingredient(
          id: trimmedName.toLowerCase().replaceAll(RegExp(r'\s+'), '_'),
          name: capitalizedName,
          category: _determineCategory(capitalizedName),
          isSelected: true,
          isCustom: true,
        );
        _ingredients.add(newIng);
        _isValidating = false;
        notifyListeners();
        return true;
      } else {
        _validationError = '"$trimmedName" geçerli bir gıda maddesi olarak doğrulanamadı.';
        _isValidating = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _validationError = 'Doğrulama servisinde hata oluştu. Lütfen bağlantınızı kontrol edin.';
      _isValidating = false;
      notifyListeners();
      return false;
    }
  }

  void clearValidationError() {
    _validationError = null;
    notifyListeners();
  }

  /// Bulk adds and selects ingredients, used by the missing ingredients modal.
  void addAndSelectIngredients(List<String> names) {
    for (var name in names) {
      final trimmedName = name.trim();
      if (trimmedName.isEmpty) continue;

      final index = _ingredients.indexWhere(
        (item) => item.name.toLowerCase() == trimmedName.toLowerCase(),
      );

      if (index != -1) {
        _ingredients[index].isSelected = true;
      } else {
        final capitalizedName = trimmedName[0].toUpperCase() + trimmedName.substring(1);
        _ingredients.add(
          Ingredient(
            id: trimmedName.toLowerCase().replaceAll(RegExp(r'\s+'), '_'),
            name: capitalizedName,
            category: _determineCategory(capitalizedName),
            isSelected: true,
            isCustom: true,
          ),
        );
      }
    }
    notifyListeners();
  }

  List<String> get suggestions => _suggestions;
  bool get isLoadingSuggestions => _isLoadingSuggestions;

  /// Fetches suggestions as the user types.
  Future<void> fetchSuggestions(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 3) {
      _suggestions = [];
      notifyListeners();
      return;
    }

    _isLoadingSuggestions = true;
    notifyListeners();

    try {
      final results = await _validationService.getSuggestions(trimmedQuery);
      _suggestions = results;
    } catch (e) {
      debugPrint('Error fetching suggestions in provider: $e');
      _suggestions = [];
    } finally {
      _isLoadingSuggestions = false;
      notifyListeners();
    }
  }

  void clearSuggestions() {
    _suggestions = [];
    notifyListeners();
  }

  /// Classifies custom ingredients into the closest category based on key phrases.
  String _determineCategory(String name) {
    final lowerName = name.toLowerCase();

    // 1. Sebzeler (Vegetables & Fruits)
    final vegKeywords = [
      'domates', 'patates', 'biber', 'havuç', 'ispanak', 'patlıcan', 'kabak', 
      'sarımsak', 'soğan', 'marul', 'salatalık', 'maydanoz', 'lahana', 'pırasa',
      'kereviz', 'karnabahar', 'brokoli', 'enginar', 'bezelye', 'taze fasulye',
      'sebze', 'meyve', 'elma', 'armut', 'muz', 'çilek', 'portakal', 'limon',
      'tomato', 'potato', 'pepper', 'carrot', 'spinach', 'eggplant', 'zucchini',
      'garlic', 'onion', 'lettuce', 'cucumber', 'parsley', 'cabbage', 'leek',
      'celery', 'cauliflower', 'broccoli', 'artichoke', 'peas', 'vegetable', 'fruit'
    ];

    // 2. Bakliyatlar (Legumes, grains)
    final legumeKeywords = [
      'mercimek', 'nohut', 'fasulye', 'pirinç', 'bulgur', 'maş', 'kuru fasulye',
      'bezelye', 'barbunya', 'bakla', 'yulaf', 'arpa', 'buğday', 'karabuğday',
      'kinoa', 'mısır', 'bakliyat', 'tahıl',
      'lentil', 'chickpea', 'bean', 'rice', 'bulgur', 'oat', 'barley', 'wheat',
      'buckwheat', 'quinoa', 'corn', 'legume', 'grain'
    ];

    // 3. Et & Balık Ürünleri (Meat & Fish & Poultry)
    final meatKeywords = [
      'tavuk', 'kıyma', 'et', 'kuşbaşı', 'balık', 'ton', 'jambon', 'sosis', 
      'salam', 'hindi', 'kuzu', 'dana', 'ördek', 'somon', 'karides', 'midye',
      'sucuk', 'kavurma', 'meat', 'chicken', 'beef', 'fish', 'tuna', 'ham', 
      'sausage', 'salami', 'turkey', 'lamb', 'salmon', 'shrimp', 'mussel'
    ];

    // 4. Süt Ürünleri (Dairy)
    final dairyKeywords = [
      'süt', 'yoğurt', 'peynir', 'tereyağı', 'krema', 'kaymak', 'kaşar', 'lor',
      'süzme', 'kefir', 'dairy', 'milk', 'cheese', 'yogurt', 'butter', 'cream'
    ];

    // Check matches
    for (var kw in vegKeywords) {
      if (lowerName.contains(kw)) return 'Sebzeler';
    }
    for (var kw in legumeKeywords) {
      if (lowerName.contains(kw)) return 'Bakliyatlar';
    }
    for (var kw in meatKeywords) {
      if (lowerName.contains(kw)) return 'Et & Balık Ürünleri';
    }
    for (var kw in dairyKeywords) {
      if (lowerName.contains(kw)) return 'Süt Ürünleri';
    }

    // Default fallback category
    return 'Diğer';
  }
}
