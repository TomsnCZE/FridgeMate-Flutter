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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
      key: Key('grid_product_$index'),
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
          margin: const EdgeInsets.all(8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: isDark ? Colors.grey[850] : Colors.white,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fotka - středově zarovnaná s okraji
                  Container(
                    height: 70,
                    margin: const EdgeInsets.fromLTRB(40, 16, 40, 8), // Stejné okraje zleva i zprava
                    child: _buildProductImage(typeIcon, typeColor, localImagePath),
                  ),
                  
                  // Čára
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    height: 3,
                    decoration: BoxDecoration(
                      color: _getColorForExpirationStatus(expirationStatus, typeColor),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Textový obsah
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Řádek s názvem a status badge naproti
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (expirationStatus != 'fresh' && expirationStatus != 'noDate')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(expirationStatus),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _getStatusText(expirationStatus),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
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
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Množství
                        Row(
                          children: [
                            Icon(Icons.scale, size: 14, color: Colors.orange[700]),
                            const SizedBox(width: 4),
                            Text(
                              '${product.quantity} $unit',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Datum pod množstvím
                        Row(
                          children: [
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
                                fontSize: 12,
                                color: _getTextColor(expirationStatus),
                                fontWeight: expirationStatus == 'soon'
                                    ? FontWeight.w600
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
              
              // Tlačítko editace - VPRAVO NAHORE CARDU MIMO FOTKU
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(Icons.more_vert, size: 20, color: isDark ? Colors.white70 : Colors.black54),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  splashRadius: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Logika stavu expirace
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

  // Barvy a styl
  Color _getColorForExpirationStatus(String status, Color typeColor) {
    switch (status) {
      case 'expired':
        return Colors.red;
      case 'today':
      case 'soon':
        return Colors.orange;
      case 'fresh':
        return Colors.green;
      case 'noDate':
      default:
        return typeColor;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'expired':
        return Colors.red;
      case 'today':
      case 'soon':
        return Colors.orange;
      case 'fresh':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getIconColor(String status) {
    switch (status) {
      case 'expired':
        return Colors.red;
      case 'today':
      case 'soon':
        return Colors.orange;
      case 'fresh':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getTextColor(String status) {
    switch (status) {
      case 'expired':
        return Colors.red;
      case 'today':
      case 'soon':
        return Colors.orange;
      case 'fresh':
        return Colors.green;
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
      default:
        return '—';
    }
  }

  // Obrázek produktu
  Widget _buildProductImage(IconData icon, Color color, String? localImagePath) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.1),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Smazat', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }
}