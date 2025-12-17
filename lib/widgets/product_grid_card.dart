import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/action_sheet.dart';

class ProductGridCard extends StatelessWidget {
  final Product product;
  final int index; // může zůstat kvůli kompatibilitě, ale nevyužívá se
  final VoidCallback onTap;
  final VoidCallback onChanged;

  const ProductGridCard({
    super.key,
    required this.product,
    required this.index,
    required this.onTap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
        margin: const EdgeInsets.all(8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).cardColor,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: _getBorderForExpirationStatus(expirationStatus, context),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 80,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: _buildProductImage(
                    typeIcon,
                    typeColor,
                    localImagePath,
                    context,
                  ),
                ),

                Container(
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: _statusColor(expirationStatus, context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                          color: _statusColor(expirationStatus, context),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getStatusText(expirationStatus),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
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
                    fontSize: 14,
                    color: Theme.of(context).hintColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.scale, size: 12, color: Colors.orange[700]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${product.quantity} $unit',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: _statusColor(expirationStatus, context),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            expDate != null
                                ? '${expDate.day}.${expDate.month}.${expDate.year}'
                                : '—',
                            style: TextStyle(
                              fontSize: 14,
                              color: _statusColor(expirationStatus, context),
                              fontWeight: expirationStatus == 'soon'
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Border? _getBorderForExpirationStatus(String status, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (status) {
      case 'expired':
        return Border.all(color: cs.error, width: 2);
      case 'today':
      case 'soon':
        return Border.all(color: cs.primary, width: 1);
      default:
        return null;
    }
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

  Color _statusColor(String status, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (status) {
      case 'expired':
        return cs.error;
      case 'today':
      case 'soon':
        return cs.primary;
      case 'fresh':
        return cs.secondary;
      default:
        return cs.outline;
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

  Widget _buildProductImage(
    IconData icon,
    Color color,
    String? localImagePath,
    BuildContext context,
  ) {
    final cs = Theme.of(context).colorScheme;

    if (localImagePath != null &&
        localImagePath.isNotEmpty &&
        File(localImagePath).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(File(localImagePath), fit: BoxFit.cover),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cs.primary.withOpacity(0.08),
      ),
      child: Center(child: Icon(icon, color: color, size: 32)),
    );
  }
}