import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/services/http_client.dart';

class FoodValidationService {
  // Open Food Facts API search url
  static const String _baseUrl = 'https://world.openfoodfacts.org/cgi/search.pl';

  /// Validates if the given [ingredientName] is a valid food item.
  /// Returns `true` if Open Food Facts API returns matching food products.
  Future<bool> validateIngredient(String ingredientName) async {
    final query = ingredientName.trim();
    if (query.isEmpty) return false;

    try {
      final uri = Uri.parse('$_baseUrl?search_terms=${Uri.encodeComponent(query)}&search_simple=1&action=process&json=1');
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
  /// Returns a list of unique product names.
  Future<List<String>> getSuggestions(String query) async {
    final searchTerms = query.trim();
    if (searchTerms.length < 3) return [];

    try {
      final uri = Uri.parse('$_baseUrl?search_terms=${Uri.encodeComponent(searchTerms)}&search_simple=1&action=process&json=1&page_size=8&fields=product_name');
      final response = await CustomHttpClient.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List? products = data['products'] as List?;
        if (products != null) {
          final List<String> suggestions = [];
          for (var p in products) {
            final name = p['product_name'] as String?;
            if (name != null && name.trim().isNotEmpty) {
              final cleanName = name.trim();
              if (!suggestions.any((s) => s.toLowerCase() == cleanName.toLowerCase())) {
                suggestions.add(cleanName);
              }
            }
          }
          return suggestions;
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error getting suggestions: $e');
      return [];
    }
  }
}
