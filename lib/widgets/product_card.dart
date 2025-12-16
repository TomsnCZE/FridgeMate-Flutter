import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final expDate = product.expirationDate;
    final expirationStatus = _getExpirationStatus(expDate);
    
    final unit = product.extra?['unit'] ?? 'ks';
    final type = product.extra?['type'] ?? 'Jídlo';
    final location = product.extra?['location'] ?? 'Neznámé';
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

    return Dismissible(
      key: Key('product_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(context, product.name);
      },
      onDismissed: (direction) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onEdit,
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
                      color: _getColorForExpirationStatus(expirationStatus, typeColor, colors),
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
                            if (expirationStatus != 'fresh' && expirationStatus != 'noDate')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                                fontWeight: expirationStatus == 'soon' ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    icon: Icon(
                      Icons.more_vert, 
                      color: colors.onSurface.withOpacity(0.6)
                    ),
                    onPressed: onEdit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // LOGIKA PRO URČENÍ STAVU EXPIRACE
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

  // BARVY PODLE STAVU EXPIRACE
  Color _getColorForExpirationStatus(String status, Color typeColor, ColorScheme colors) {
    switch (status) {
      case 'expired':
        return colors.error;
      case 'today':
        return colors.primary;
      case 'soon':
        return colors.primary;
      case 'fresh':
        return colors.secondary;
      case 'noDate':
        return typeColor;
      default:
        return typeColor;
    }
  }

  Color _getStatusColor(String status, ColorScheme colors) {
    switch (status) {
      case 'expired':
        return colors.error;
      case 'today':
        return colors.primary;
      case 'soon':
        return colors.primary;
      case 'fresh':
        return colors.secondary;
      case 'noDate':
        return colors.onSurface.withOpacity(0.5);
      default:
        return colors.onSurface.withOpacity(0.5);
    }
  }

  Color _getIconColor(String status, ColorScheme colors) {
    switch (status) {
      case 'expired':
        return colors.error;
      case 'today':
        return colors.primary;
      case 'soon':
        return colors.primary;
      case 'fresh':
        return colors.secondary;
      case 'noDate':
        return colors.onSurface.withOpacity(0.5);
      default:
        return colors.onSurface.withOpacity(0.5);
    }
  }

  Color _getTextColor(String status, ColorScheme colors) {
    switch (status) {
      case 'expired':
        return colors.error;
      case 'today':
        return colors.primary;
      case 'soon':
        return colors.primary;
      case 'fresh':
        return colors.secondary;
      case 'noDate':
        return colors.onSurface.withOpacity(0.7);
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
      case 'noDate':
        return '—';
      default:
        return '—';
    }
  }

  Border? _getBorderForExpirationStatus(String status, ColorScheme colors) {
    switch (status) {
      case 'expired':
        return Border.all(color: colors.error, width: 2);
      case 'today':
        return Border.all(color: colors.primary, width: 1);
      case 'soon':
        return Border.all(color: colors.primary, width: 1);
      case 'fresh':
      case 'noDate':
        return null;
      default:
        return null;
    }
  }

  Widget _buildProductImage(IconData icon, Color color, String? localImagePath, ColorScheme colors) {
    if (localImagePath != null && localImagePath.isNotEmpty) {
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

  Future<bool> _showDeleteConfirmation(BuildContext context, String productName) async {
    final colors = Theme.of(context).colorScheme;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Smazat produkt?'),
        content: Text('Opravdu chceš smazat "$productName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Smazat', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }
}