import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/action_sheet.dart';
import 'package:easy_localization/easy_localization.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onChanged;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final expDate = product.expirationDate;
    final expirationStatus = _getExpirationStatus(expDate);

    final rawCategory = product.category;

    final categoryKey = _normalizeCategory(rawCategory);

    final locationText = 'add_product.$categoryKey'.tr();

    String two(int n) => n.toString().padLeft(2, '0');
    final dateText = expDate != null
        ? '${two(expDate.day)}/${two(expDate.month)}/${expDate.year}'
        : '—';

    final localImagePath = product.extra?['localImagePath'] as String?;
    final hasPhoto =
        localImagePath != null &&
        localImagePath.isNotEmpty &&
        File(localImagePath).existsSync();

    const rowHeight = 72.0;


    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (_) => ProductActionSheet(
              product: product,
              parentContext: context,
              onChanged: onChanged,
            ),
          );
        },
        child: Ink(
          height: rowHeight, // 🔑 pevná výška = symetrie
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, // 🔑 centrování
              children: [
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getColorForExpirationStatus(
                      expirationStatus,
                      colors,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),

                if (hasPhoto) ...[
                  _buildProductImage(localImagePath),
                  const SizedBox(width: 12),
                ],

                Expanded(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // 🔑 centrování textu
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(locationText, style: theme.textTheme.bodySmall),
                      const SizedBox(height: 2),
                      Text(
                        dateText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getExpirationStatus(DateTime? expDate) {
    if (expDate == null) return 'noDate';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiration = DateTime(expDate.year, expDate.month, expDate.day);

    final difference = expiration.difference(today).inDays;

    if (difference < 0) return 'expired';
    if (difference == 0) return 'today';
    if (difference <= 3) return 'soon';
    return 'fresh';
  }

  Color _getColorForExpirationStatus(String status, ColorScheme colors) {
    switch (status) {
      case 'expired':
        return colors.error;
      case 'today':
      case 'soon':
        return colors.primary;
      case 'fresh':
        return colors.secondary;
      case 'noDate':
      default:
        return colors.outlineVariant;
    }
  }

  String _normalizeCategory(dynamic v) {
    final s = (v ?? '').toString().trim();
    if (s.isEmpty) return 'fridge';

    final l = s.toLowerCase();

    // already stored keys
    if (l == 'fridge') return 'fridge';
    if (l == 'freezer') return 'freezer';
    if (l == 'pantry') return 'pantry';

    // Czech values
    if (l == 'lednice') return 'fridge';
    if (l == 'mrazák' || l == 'mrazak') return 'freezer';
    if (l == 'spíž' || l == 'spiz') return 'pantry';

    // German values
    if (l == 'kühlschrank' || l == 'kuehlschrank') return 'fridge';
    if (l == 'gefrierschrank') return 'freezer';
    if (l == 'speisekammer') return 'pantry';

    return 'fridge';
  }

  Widget _buildProductImage(String? localImagePath) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        image: DecorationImage(
          image: FileImage(File(localImagePath!)),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
