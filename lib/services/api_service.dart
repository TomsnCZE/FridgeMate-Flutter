import 'package:openfoodfacts/openfoodfacts.dart' as off;
import '../models/product.dart';

class ApiService {
  /// Vyhledá produkt podle čárového / QR kódu
  Future<Product?> fetchProductByBarcode(String barcode) async {
    try {
      // Konfigurace dotazu
      final configuration = off.ProductQueryConfiguration(
        barcode,
        version: off.ProductQueryVersion.v3,
        language: off.OpenFoodFactsLanguage.CZECH,
        fields: [off.ProductField.ALL],
      );

      // Zavolání API
      final result = await off.OpenFoodAPIClient.getProductV3(configuration);

      // Kontrola, zda byl produkt nalezen
      if (result.status == off.ProductResultV3.statusSuccess && 
          result.product != null) {
        final offProduct = result.product!;

        // Získání základních informací
        final name = offProduct.productName ?? 'Neznámý produkt';
        final brand = offProduct.brands ?? '';
        final imageUrl = offProduct.imageFrontUrl ?? '';

        // Kategorie
        final categoryTags = offProduct.categoriesTags ?? [];
        final category = categoryTags.isNotEmpty
            ? categoryTags.first.replaceAll(RegExp(r'^[a-z]{2}:'), '')
            : 'Neznámá';

        // Složení
        final ingredients = offProduct.ingredientsText ?? 'Složení není dostupné';

        // Kalorie - robustní způsob získání energie
        String calories = 'N/A';
        if (offProduct.nutriments != null) {
          try {
            final energy = offProduct.nutriments!.getValue(
              off.Nutrient.energyKCal,
              off.PerSize.oneHundredGrams,
            );
            if (energy != null) {
              calories = energy.toStringAsFixed(0); // Zaokrouhlení na celé číslo
            }
          } catch (e) {
            // Pokud getValue selže, zkusíme alternativní přístup
            print('⚠️ Nepodařilo se získat kalorie: $e');
          }
        }

        // 🧠 Automatická detekce typu (Jídlo / Pití / Ostatní)
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
        return null; // Produkt nenalezen
      }
    } catch (e) {
      print('❌ Chyba při načítání produktu: $e');
      return null;
    }
  }
}