import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/product.dart';
import '../screens/add_product_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});
  //kunda

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final ingredients =
        (product.extra?['ingredients'] as String?)?.trim().isNotEmpty == true
        ? (product.extra?['ingredients'] as String).trim()
        : 'product_detail.not_provided'.tr();

    final calories =
        (product.extra?['calories'] as String?)?.trim().isNotEmpty == true
        ? (product.extra?['calories'] as String).trim()
        : 'product_detail.na'.tr();

    final rawType = product.extra?['type'] ?? 'food';

    final typeKey = _normalizeType(rawType);

    final typeText = 'add_product.$typeKey'.tr();

    final localImage = product.extra?['localImagePath'];

    Widget imageWidget;
    if (localImage != null && localImage.isNotEmpty) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(localImage),
          width: 200,
          height: 200,
          fit: BoxFit.cover,
        ),
      );
    } else {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          (product.imageUrl?.isNotEmpty ?? false)
              ? product.imageUrl!
              : 'https://upload.wikimedia.org/wikipedia/commons/1/14/No_Image_Available.jpg',
          width: 200,
          height: 200,
          fit: BoxFit.cover,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('product_detail.title'.tr()),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.18),
            width: 1,
          ),
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: imageWidget),
            const SizedBox(height: 20),

            Text(
              product.name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (product.brand != null && product.brand!.isNotEmpty)
              Text(
                product.brand!,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),

            const SizedBox(height: 12),

            Row(
              children: [
                Icon(Icons.fastfood, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'product_detail.type'.tr(namedArgs: {'value': typeText}),
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'product_detail.calories'.tr(namedArgs: {'value': calories}),
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              'product_detail.ingredients_title'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              ingredients,
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text('product_detail.add_to_inventory'.tr()),
                  onPressed: () async {
                    final productToPrefill = Product(
                      id: null,
                      name: product.name,
                      brand: product.brand,
                      imageUrl: product.imageUrl,
                      category: _mapApiCategory(product.category),
                      expirationDate: product.expirationDate,
                      quantity: 1,
                      extra: {
                        'unit': product.extra?['unit'] ?? 'pieces',
                        'type': typeKey,
                        'localImagePath': product.extra?['localImagePath'],
                        'ingredients': product.extra?['ingredients'],
                        'calories': product.extra?['calories'],
                      },
                    );

                    final inserted = await Navigator.push<Product?>(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddProductScreen(existingProduct: productToPrefill),
                      ),
                    );

                    if (inserted != null && context.mounted) {
                      // předáme vložený produkt nahoru (QR scanner nebo inventory)
                      Navigator.pop(context, inserted);
                    }
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.close),
                  label: Text('product_detail.close'.tr()),
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

  String _normalizeType(dynamic v) {
    final s = (v ?? '').toString().trim();
    if (s.isEmpty) return 'food';

    final l = s.toLowerCase();

    // already stored keys
    if (l == 'food') return 'food';
    if (l == 'beverage' || l == 'drink') return 'beverage';
    if (l == 'other') return 'other';

    // Czech values
    if (l == 'jídlo' || l == 'jidlo') return 'food';
    if (l == 'pití' || l == 'piti') return 'beverage';
    if (l == 'ostatní' || l == 'ostatni') return 'other';

    // German values
    if (l == 'lebensmittel' || l == 'essen') return 'food';
    if (l == 'getränk' || l == 'getraenk' || l == 'getraenke')
      return 'beverage';
    if (l == 'sonstiges') return 'other';

    return 'food';
  }

  String _mapApiCategory(String apiCategory) {
    final lower = apiCategory.toLowerCase();
    if (lower.contains('beverages') ||
        lower.contains('beverage') ||
        lower.contains('drink')) {
      return 'beverage';
    }
    if (lower.contains('food') ||
        lower.contains('meal') ||
        lower.contains('groceries')) {
      return 'food';
    }
    return 'other';
  }
}
