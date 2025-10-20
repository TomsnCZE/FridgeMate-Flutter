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
    final expDate = product.expirationDate;
    final isExpired = expDate != null && expDate.isBefore(DateTime.now());
    final isExpiringSoon = expDate != null && 
        expDate.isAfter(DateTime.now()) && 
        expDate.difference(DateTime.now()).inDays <= 3;

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
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: isExpired 
                ? Border.all(color: Colors.red, width: 2)
                : isExpiringSoon
                  ? Border.all(color: Colors.orange, width: 1)
                  : null,
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
                      color: isExpired 
                        ? Colors.red 
                        : isExpiringSoon
                          ? Colors.orange
                          : typeColor,
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
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            if (isExpired)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'EXPIROVÁNO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else if (isExpiringSoon)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'BRZY',
                                  style: TextStyle(
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
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.scale, size: 14, color: Colors.orange[700]),
                            const SizedBox(width: 4),
                            Text(
                              '${product.quantity} $unit',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.schedule, 
                              size: 14, 
                              color: isExpired ? Colors.red : Colors.grey
                            ),
                            const SizedBox(width: 4),
                            Text(
                              expDate != null 
                                ? '${expDate.day}.${expDate.month}.${expDate.year}'
                                : '—',
                              style: TextStyle(
                                fontSize: 13,
                                color: isExpired ? Colors.red : Colors.grey[700],
                                fontWeight: isExpiringSoon ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
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