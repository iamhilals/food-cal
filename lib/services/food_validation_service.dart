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
}
