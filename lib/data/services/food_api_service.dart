import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/food.dart';

/// Looks up packaged-food macros by barcode.
///
/// Uses the free Open Food Facts API by default — no API key required. Swap
/// [_baseUrl] / parsing for a commercial provider (e.g. Nutritionix, USDA
/// FoodData Central) by editing this single file; the rest of the app only
/// depends on the returned [Food] model.
class FoodApiService {
  FoodApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _baseUrl = 'https://world.openfoodfacts.org/api/v2/product';

  /// Fetch a [Food] for an EAN/UPC barcode, or null if not found.
  Future<Food?> lookupBarcode(String barcode) async {
    final uri = Uri.parse(
      '$_baseUrl/$barcode.json'
      '?fields=product_name,brands,nutriments,serving_quantity,quantity',
    );

    try {
      final res = await _client
          .get(uri, headers: {'User-Agent': 'ForgeFit/1.0 (contact@forgefit.app)'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (json['status'] != 1) return null;

      final p = json['product'] as Map<String, dynamic>;
      final n = (p['nutriments'] as Map<String, dynamic>? ?? {});

      double num100(String key) => (n['${key}_100g'] as num?)?.toDouble() ?? 0;

      return Food(
        name: (p['product_name'] as String?)?.trim().isNotEmpty == true
            ? p['product_name'] as String
            : 'Scanned item',
        brand: (p['brands'] as String?)?.split(',').first.trim() ?? '',
        barcode: barcode,
        servingSize: 100, // OFF nutriments are per 100g/ml.
        servingUnit: 'g',
        calories: num100('energy-kcal'),
        protein: num100('proteins'),
        carbs: num100('carbohydrates'),
        fat: num100('fat'),
        fiber: num100('fiber'),
        sugar: num100('sugars'),
        sodium: num100('sodium') * 1000, // g -> mg
      );
    } catch (_) {
      // Network/parse failures degrade gracefully to "not found".
      return null;
    }
  }

  void dispose() => _client.close();
}
