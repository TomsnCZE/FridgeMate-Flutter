import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  static const String baseUrl =
      'https://world.openfoodfacts.org/api/v0/product/';

  /// Vyhledá produkt podle čárového / QR kódu
  Future<Product?> fetchProductByBarcode(String barcode) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$barcode.json'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 1 && data['product'] != null) {
          final productData = data['product'];

          final name = productData['product_name'] ?? 'Neznámý produkt';
          final brand = productData['brands'] ?? '';
          final imageUrl = productData['image_url'] ?? '';

          final categoryTags = (productData['categories_tags'] ?? [])
              .cast<String>()
              .map((e) => e.toLowerCase())
              .toList();

          final category = categoryTags.isNotEmpty
              ? categoryTags.first.replaceAll(RegExp(r'^[a-z]{2}:'), '')
              : 'Neznámá';

          final ingredients =
              productData['ingredients_text'] ?? 'Složení není dostupné';

          final calories = productData['nutriments']?['energy-kcal_100g']
                  ?.toString() ??
              'N/A';

          // 🧠 Automatická detekce typu (Jídlo / Pití / Ostatní)
          String type = 'Ostatní';
          if (categoryTags.any((t) =>
              t.contains('beverages') ||
              t.contains('drink') ||
              t.contains('soda') ||
              t.contains('juice'))) {
            type = 'Pití';
          } else if (categoryTags.any((t) =>
              t.contains('food') ||
              t.contains('meal') ||
              t.contains('snack') ||
              t.contains('dish'))) {
            type = 'Jídlo';
          }

          return Product(
            name: name,
            brand: brand,
            imageUrl: imageUrl,
            category: category,
            extra: {
              'ingredients': ingredients,
              'calories': calories,
              'type': type,
            },
          );
        } else {
          return null; // Produkt nenalezen
        }
      } else {
        print('HTTP chyba: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Chyba při načítání produktu: $e');
      return null;
    }
  }
}