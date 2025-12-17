import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/action_sheet.dart';

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

    final unit = product.extra?['unit'] ?? 'ks';
    final type = product.extra?['type'] ?? 'Jídlo';
    final location = product.extra?['location'] ?? product.category;
    final localImagePath = product.extra?['localImagePath'];

    Color typeColor;
    IconData typeIcon;

    switch (type) {
      case 'Pití':
        typeColor = Colors.blueAccent;
        typeIcon = Icons.local_drink_outlined;
        break;
      case 'Ostatní':
        typeColor = Colors.grey;
        typeIcon = Icons.category_outlined;
        break;
      default:
        typeColor = Colors.orange;
        typeIcon = Icons.fastfood_outlined;
    }

    return GestureDetector(
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
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        color: colors.surface,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: _getBorderForExpirationStatus(expirationStatus, colors),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getColorForExpirationStatus(
                      expirationStatus,
                      typeColor,
                      colors,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),

                _buildProductImage(typeIcon, typeColor, localImagePath, colors),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colors.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (expirationStatus != 'fresh' &&
                              expirationStatus != 'noDate')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(expirationStatus, colors),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getStatusText(expirationStatus),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$type • $location',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.scale, size: 14, color: colors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${product.quantity} $unit',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: _getIconColor(expirationStatus, colors),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            expDate != null
                                ? '${expDate.day}.${expDate.month}.${expDate.year}'
                                : '—',
                            style: TextStyle(
                              fontSize: 13,
                              color: _getTextColor(expirationStatus, colors),
                              fontWeight: expirationStatus == 'soon'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
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

  Color _getColorForExpirationStatus(
    String status,
    Color typeColor,
    ColorScheme colors,
  ) {
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
        return typeColor;
    }
  }

  Color _getStatusColor(String status, ColorScheme colors) {
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
        return colors.onSurface.withOpacity(0.5);
    }
  }

  Color _getIconColor(String status, ColorScheme colors) {
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
        return colors.onSurface.withOpacity(0.5);
    }
  }

  Color _getTextColor(String status, ColorScheme colors) {
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
        return colors.onSurface.withOpacity(0.7);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'expired':
        return 'EXPIROVÁNO';
      case 'today':
        return 'DNES';
      case 'soon':
        return 'BRZY';
      case 'fresh':
        return 'ČERSTVÉ';
      default:
        return '—';
    }
  }

  Border? _getBorderForExpirationStatus(String status, ColorScheme colors) {
    switch (status) {
      case 'expired':
        return Border.all(color: colors.error, width: 2);
      case 'today':
      case 'soon':
        return Border.all(color: colors.primary, width: 1);
      default:
        return null;
    }
  }

  Widget _buildProductImage(
    IconData icon,
    Color color,
    String? localImagePath,
    ColorScheme colors,
  ) {
    if (localImagePath != null &&
        localImagePath.isNotEmpty &&
        File(localImagePath).existsSync()) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(
            image: FileImage(File(localImagePath)),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.primary.withOpacity(0.4), width: 1),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}