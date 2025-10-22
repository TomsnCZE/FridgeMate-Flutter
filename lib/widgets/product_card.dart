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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
          color: Colors.red,
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
          color: isDarkMode ? const Color(0xFF1E1E1E) : const Color.fromARGB(255, 255, 250, 234),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: _getBorderForExpirationStatus(expirationStatus),
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
                      color: _getColorForExpirationStatus(expirationStatus, typeColor),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),

                  _buildProductImage(typeIcon, typeColor, localImagePath),
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
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            if (expirationStatus != 'fresh' && expirationStatus != 'noDate')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(expirationStatus),
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
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.scale, size: 14, color: Colors.orange[700]),
                            const SizedBox(width: 4),
                            Text(
                              '${product.quantity} $unit',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.schedule, 
                              size: 14, 
                              color: _getIconColor(expirationStatus),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              expDate != null 
                                ? '${expDate.day}.${expDate.month}.${expDate.year}'
                                : '—',
                              style: TextStyle(
                                fontSize: 13,
                                color: _getTextColor(expirationStatus),
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
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600]
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
  Color _getColorForExpirationStatus(String status, Color typeColor) {
    switch (status) {
      case 'expired':
        return Colors.red;
      case 'today':
        return Colors.orange;
      case 'soon':
        return Colors.orange;
      case 'fresh':
        return Colors.green;
      case 'noDate':
        return typeColor;
      default:
        return typeColor;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'expired':
        return Colors.red;
      case 'today':
        return Colors.orange;
      case 'soon':
        return Colors.orange;
      case 'fresh':
        return Colors.green;
      case 'noDate':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getIconColor(String status) {
    switch (status) {
      case 'expired':
        return Colors.red;
      case 'today':
        return Colors.orange;
      case 'soon':
        return Colors.orange;
      case 'fresh':
        return Colors.green;
      case 'noDate':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getTextColor(String status) {
    switch (status) {
      case 'expired':
        return Colors.red;
      case 'today':
        return Colors.orange;
      case 'soon':
        return Colors.orange;
      case 'fresh':
        return Colors.green;
      case 'noDate':
        return Colors.grey[700]!;
      default:
        return Colors.grey[700]!;
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

  Border? _getBorderForExpirationStatus(String status) {
    switch (status) {
      case 'expired':
        return Border.all(color: Colors.red, width: 2);
      case 'today':
        return Border.all(color: Colors.orange, width: 1);
      case 'soon':
        return Border.all(color: Colors.orange, width: 1);
      case 'fresh':
      case 'noDate':
        return null;
      default:
        return null;
    }
  }

  Widget _buildProductImage(IconData icon, Color color, String? localImagePath) {
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Icon(icon, color: color, size: 24),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Smazat', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }
}