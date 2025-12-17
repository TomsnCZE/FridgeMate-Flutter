import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../screens/product_edit_screen.dart';

class ProductActionSheet extends StatelessWidget {
  final Product product;
  final BuildContext parentContext;
  final VoidCallback onChanged;

  const ProductActionSheet({
    super.key,
    required this.product,
    required this.parentContext,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),

            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Upravit'),
              onTap: () async {
                Navigator.pop(context); // zavře sheet

                final result = await Navigator.push(
                  parentContext,
                  MaterialPageRoute(
                    builder: (_) => EditProductScreen(product: product),
                  ),
                );

                if (result != null) {
                  onChanged();
                }
              },
            ),

            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Smazat',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Smazat produkt?'),
                    content: Text(
                      'Opravdu chceš smazat "${product.name}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Zrušit'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Smazat'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && product.id != null) {
                  await DatabaseService.instance.deleteProduct(product.id!);
                  Navigator.pop(context); // zavře sheet
                  onChanged();
                }
              },
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}