import 'package:openfoodfacts/openfoodfacts.dart' as off;
import '../models/product.dart';

class ApiService {
  /// vyhleda produkt podle caroveho kodu
  Future<Product?> fetchProductByBarcode(String barcode) async {
    try {
      // konfigurace dotazu
      final configuration = off.ProductQueryConfiguration(
        barcode,
        version: off.ProductQueryVersion.v3,
        language: off.OpenFoodFactsLanguage.CZECH,
        fields: [off.ProductField.ALL],
      );

      // zavolani API
      final result = await off.OpenFoodAPIClient.getProductV3(configuration);

      // kontrola jestli byl produkt nalezen
      if (result.status == off.ProductResultV3.statusSuccess && 
          result.product != null) {
        final offProduct = result.product!;

        // ziskani zakl. informaci
        final name = offProduct.productName ?? 'Neznámý produkt';
        final brand = offProduct.brands ?? '';
        final imageUrl = offProduct.imageFrontUrl ?? '';

        // kategorie
        final categoryTags = offProduct.categoriesTags ?? [];
        final category = categoryTags.isNotEmpty
            ? categoryTags.first.replaceAll(RegExp(r'^[a-z]{2}:'), '')
            : 'Neznámá';

        final ingredients = offProduct.ingredientsText ?? 'Složení není dostupné';

        String calories = 'N/A';
        if (offProduct.nutriments != null) {
          try {
            final energy = offProduct.nutriments!.getValue(
              off.Nutrient.energyKCal,
              off.PerSize.oneHundredGrams,
            );
            if (energy != null) {
              calories = energy.toStringAsFixed(0);
            }
          } catch (e) {
            print('Nepodařilo se získat kalorie: $e');
          }
        }

        String type = 'Ostatní';
        final lowerCaseTags = categoryTags.map((t) => t.toLowerCase()).toList();
        
        if (lowerCaseTags.any((t) =>
            t.contains('beverages') ||
            t.contains('drink') ||
            t.contains('soda') ||
            t.contains('juice'))) {
          type = 'Pití';
        } else if (lowerCaseTags.any((t) =>
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
        return null;
      }
    } catch (e) {
      print('Chyba při načítání produktu: $e');
      return null;
    }
  }
}