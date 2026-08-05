import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/services/http_client.dart';

class FoodValidationService {
  // Open Food Facts API search url
  static const String _baseUrl = 'https://tr.openfoodfacts.org/cgi/search.pl';

  /// Validates if the given [ingredientName] is a valid food item.
  /// Returns `true` if Open Food Facts API returns matching food products.
  Future<bool> validateIngredient(String ingredientName) async {
    final query = ingredientName.trim();
    if (query.isEmpty) return false;

    try {
      final uri = Uri.parse('$_baseUrl?search_terms=${Uri.encodeComponent(query)}&search_simple=1&action=process&json=1&cc=tr&lc=tr');
      final response = await CustomHttpClient.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final int count = data['count'] as int? ?? 0;
        final List? products = data['products'] as List?;

        // If count is greater than 0 and the products list is not empty,
        // it means Open Food Facts found at least one registered food item.
        return count > 0 && products != null && products.isNotEmpty;
      }
      return false;
    } catch (e) {
      // Handle network exceptions or timeouts
      debugPrint('Food validation error: $e');
      return false;
    }
  }

  /// Fetches product suggestions based on a partial [query].
  /// Returns a list of unique, cleaned product names.
  Future<List<String>> getSuggestions(String query) async {
    final searchTerms = query.trim();
    if (searchTerms.length < 3) return [];

    try {
      final uri = Uri.parse('$_baseUrl?search_terms=${Uri.encodeComponent(searchTerms)}&search_simple=1&action=process&json=1&page_size=20&fields=product_name&cc=tr&lc=tr');
      final response = await CustomHttpClient.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List? products = data['products'] as List?;
        if (products != null) {
          return _cleanAndFilterSuggestions(products, searchTerms);
        }
      }
      return [searchTerms[0].toUpperCase() + searchTerms.substring(1).toLowerCase()];
    } catch (e) {
      debugPrint('Error getting suggestions: $e');
      return [searchTerms[0].toUpperCase() + searchTerms.substring(1).toLowerCase()];
    }
  }

  /// Cleans and filters product names to return only high-quality Turkish food suggestions.
  List<String> _cleanAndFilterSuggestions(List<dynamic> products, String query) {
    final List<String> cleanedSuggestions = [];

    // Foreign stop words to exclude foreign products/descriptions
    final foreignStopWords = {
      'de', 'la', 'le', 'les', 'en', 'et', 'con', 'y', 'del', 'au', 'with', 'and', 'of',
      'graines', 'flocons', 'avoine', 'muesli', 'quinoa', 'chocolate', 'negro', 'tartine',
      'croustillante', 'sel', 'biscuit', 'bio', 'organic', 'sans', 'gluten', 'nature',
      'sucre', 'lait', 'chocolat', 'noir', 'rouge', 'vert', 'blanc', 'croustillantes'
    };

    for (var p in products) {
      final String? rawName = p['product_name'] as String?;
      if (rawName == null || rawName.trim().isEmpty) continue;

      var name = rawName.trim();

      // 1. Remove weights/sizes (e.g. 200g, 1L, 500 ml, 12 adet, 245g)
      name = name.replaceAll(RegExp(r'\d+\s*(g|ml|kg|l|oz|adet|gr|oz|cl)\b', caseSensitive: false), '');
      
      // 2. Remove punctuation and special characters
      name = name.replaceAll(RegExp(r'[\(\[\{\)\]\}]|\+|-|&|/|\\|,|\.|\*|\|'), ' ');
      
      // 3. Replace multiple spaces with a single space
      name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

      if (name.isEmpty) continue;

      // 4. Heuristic: Product name shouldn't be too long (max 4 words)
      final words = name.split(' ');
      if (words.length > 4) continue;

      // 5. Heuristic: Exclude if it contains any common foreign stop words
      bool hasForeignWords = false;
      for (var w in words) {
        if (foreignStopWords.contains(w.toLowerCase())) {
          hasForeignWords = true;
          break;
        }
      }
      if (hasForeignWords) continue;

      // 6. Heuristic: Must contain the typed query (case-insensitive)
      if (!name.toLowerCase().contains(query.toLowerCase())) continue;

      // 7. Capitalize first letter of each word for clean UI presentation
      final capitalized = words.map((w) {
        if (w.isEmpty) return '';
        return w[0].toUpperCase() + w.substring(1).toLowerCase();
      }).join(' ').trim();

      if (capitalized.isNotEmpty && 
          !cleanedSuggestions.any((s) => s.toLowerCase() == capitalized.toLowerCase())) {
        cleanedSuggestions.add(capitalized);
      }
    }

    // Fallback: If no clean web results survived the filters, add the capitalized version of the query itself
    if (cleanedSuggestions.isEmpty && query.trim().length >= 3) {
      final q = query.trim();
      final capitalizedQuery = q[0].toUpperCase() + q.substring(1).toLowerCase();
      cleanedSuggestions.add(capitalizedQuery);
    }

    return cleanedSuggestions;
  }
}
