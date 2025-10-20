import 'dart:io';

import 'package:flutter/material.dart';
import '../models/product.dart';
import 'package:intl/intl.dart';

class ProductDetailBottomSheet extends StatelessWidget {
  final Product product;

  const ProductDetailBottomSheet({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = product.expirationDate != null &&
        product.expirationDate!.isBefore(DateTime.now());
    
    final isExpiringSoon = product.expirationDate != null &&
        product.expirationDate!.isAfter(DateTime.now()) &&
        product.expirationDate!.difference(DateTime.now()).inDays <= 3;

    final hasImage = product.extra?['localImagePath'] != null ||
        (product.imageUrl != null && product.imageUrl!.isNotEmpty);

    final calories = product.extra?['calories'];
    final ingredients = product.extra?['ingredients'];
    final type = product.extra?['type'] ?? 'Neuvedeno';
    final location = product.extra?['location'] ?? product.category;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header s tlačítkem zavřít
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Detail produktu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // FOTKA PRODUKTU
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
              ),
              child: hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: product.extra?['localImagePath'] != null
                          ? Image.file(
                              File(product.extra!['localImagePath']!),
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildNoImagePlaceholder();
                              },
                            ),
                    )
                  : _buildNoImagePlaceholder(),
            ),
          ),

          const SizedBox(height: 16),

          // NÁZEV PRODUKTU
          Center(
            child: Text(
              product.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // ZNAČKA
          if (product.brand != null && product.brand!.isNotEmpty)
            Center(
              child: Text(
                product.brand!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),

          const SizedBox(height: 20),

          // ZÁKLADNÍ INFORMACE
          _buildInfoSection(
            icon: Icons.category,
            title: 'Kategorie',
            value: product.category,
          ),

          _buildInfoSection(
            icon: Icons.location_on,
            title: 'Umístění',
            value: location,
          ),

          _buildInfoSection(
            icon: Icons.fastfood,
            title: 'Typ produktu',
            value: type,
          ),

          // DATUM SPOTŘEBY
          if (product.expirationDate != null)
            _buildInfoSection(
              icon: isExpired ? Icons.warning : Icons.calendar_today,
              title: 'Datum spotřeby',
              value: _formatDate(product.expirationDate!),
              isWarning: isExpired || isExpiringSoon,
              warningText: isExpired ? 'PROŠLÉ' : (isExpiringSoon ? 'BRZY EXPIRUJE' : null),
            )
          else
            _buildInfoSection(
              icon: Icons.calendar_today,
              title: 'Datum spotřeby',
              value: 'Neuvedeno',
            ),

          // KALORIE
          _buildInfoSection(
            icon: Icons.local_fire_department,
            title: 'Kalorie',
            value: calories != null ? '$calories kcal/100g' : 'Neuvedeno',
          ),

          const SizedBox(height: 16),

          // SLOŽENÍ
          const Text(
            'Složení:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ingredients ?? 'Neuvedeno',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 24),

          // STATUS INDIKÁTOR
          if (isExpired || isExpiringSoon)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isExpired ? Colors.red[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isExpired ? Colors.red : Colors.orange,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: isExpired ? Colors.red : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isExpired 
                          ? 'Produkt prošel expirací!'
                          : 'Produkt brzy expiruje!',
                      style: TextStyle(
                        color: isExpired ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.photo_camera, size: 40, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text(
          'Žádná fotka',
          style: TextStyle(color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String value,
    bool isWarning = false,
    String? warningText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: isWarning ? Colors.orange : Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 16,
                          color: isWarning ? Colors.orange : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (warningText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          warningText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }
}