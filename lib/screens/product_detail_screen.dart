import 'package:flutter/material.dart';
import '../models/product.dart';
import '../screens/add_product_screen.dart'; // ✅ Přidáno

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  final int index;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final ingredients = product.extra?['ingredients'] ?? 'Neuvedeno';
    final calories = product.extra?['calories'] ?? 'N/A';
    final type = product.extra?['type'] ?? 'Jídlo';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail produktu'),
        backgroundColor: const Color.fromARGB(255, 254, 215, 97),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  (product.imageUrl?.isNotEmpty ?? false)
                      ? product.imageUrl!
                      : 'https://upload.wikimedia.org/wikipedia/commons/1/14/No_Image_Available.jpg',
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              product.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (product.brand != null && product.brand!.isNotEmpty)
              Text(
                product.brand!,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.category, color: Colors.orange),
                const SizedBox(width: 6),
                Text(
                  'Kategorie: ${product.category}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.fastfood, color: Colors.orange),
                const SizedBox(width: 6),
                Text('Typ: $type', style: const TextStyle(fontSize: 16)),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange),
                const SizedBox(width: 6),
                Text(
                  'Kalorie: $calories kcal / 100g',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Text(
              'Složení:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              ingredients,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Přidat do skladu'),
                  onPressed: () async {
                    // ✅ OTEVŘI CELÝ ADD PRODUCT SCREEN S PŘEDVYPLNĚNÝMI DATY
                    final newProduct = await Navigator.push<Product>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddProductScreen(
                          initialName: product.name,
                          initialCategory: _mapApiCategory(product.category),
                          initialBrand: product.brand,
                        ),
                      ),
                    );

                    // ✅ VRÁTÍME PRODUKT ZPĚT DO QR SCANNER SCREEN
                    if (newProduct != null && context.mounted) {
                      Navigator.pop(context, newProduct);
                    }
                  },
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.close),
                  label: const Text('Zavřít'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _mapApiCategory(String apiCategory) {
    final lower = apiCategory.toLowerCase();
    if (lower.contains('beverages') || lower.contains('beverage') || lower.contains('drink')) {
      return 'Pití';
    }
    if (lower.contains('food') || lower.contains('meal') || lower.contains('groceries')) {
      return 'Jídlo';
    }
    return 'Ostatní';
  }
}