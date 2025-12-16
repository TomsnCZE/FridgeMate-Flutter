import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductGridCard extends StatelessWidget {
  final Product product;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const ProductGridCard({
    super.key,
    required this.product,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final expDate = product.expirationDate;
    final expirationStatus = _getExpirationStatus(expDate);

    final unit = product.extra?['unit'] ?? 'ks';
    final type = product.extra?['type'] ?? 'Jídlo';
    final location = product.extra?['location'] ?? 'Neznámé';
    final localImagePath = product.extra?['localImagePath'];

    final colorScheme = Theme.of(context).colorScheme;

    Color typeColor;
    IconData typeIcon;

    switch (type) {
      case 'Pití':
        typeColor = colorScheme.primary;
        typeIcon = Icons.local_drink_outlined;
        break;
      case 'Ostatní':
        typeColor = colorScheme.secondary;
        typeIcon = Icons.category_outlined;
        break;
      default:
        typeColor = colorScheme.primary;
        typeIcon = Icons.fastfood_outlined;
    }

    return Dismissible(
      key: Key('grid_product_$index'),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.edit, color: Colors.white, size: 30),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await _showDeleteConfirmation(context, product.name);
        } else if (direction == DismissDirection.startToEnd) {
          onEdit();
          return false;
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete();
        }
      },
      child: GestureDetector(
        onTap: onTap,
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
                  // Fotka
                  Container(
                    height: 80,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: _buildProductImage(typeIcon, typeColor, localImagePath, context),
                  ),
                  
                  // Čára
                  Container(
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: _statusColor(expirationStatus, context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Název a status
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
                      if (expirationStatus != 'fresh' && expirationStatus != 'noDate')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  
                  // Typ a lokace
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
                  
                  // Množství a datum
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Množství
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
                      
                      // Datum
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
        return Border.all(color: Theme.of(context).colorScheme.primary, width: 1);
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
        return Theme.of(context).colorScheme.primary;
      case 'fresh':
        return cs.primary;
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

  Widget _buildProductImage(IconData icon, Color color, String? localImagePath, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
      ),
      child: localImagePath != null && localImagePath.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(localImagePath),
                fit: BoxFit.cover,
              ),
            )
          : Center(
              child: Icon(icon, color: color, size: 32),
            ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context, String productName) async {
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
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Smazat', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }
}