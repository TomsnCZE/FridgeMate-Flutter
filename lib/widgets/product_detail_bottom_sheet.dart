import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product.dart';
import 'package:easy_localization/easy_localization.dart';

class ProductDetailBottomSheet extends StatelessWidget {
  final Product product;

  const ProductDetailBottomSheet({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    final isExpired = product.expirationDate != null &&
        product.expirationDate!.isBefore(DateTime.now());
    
    final isExpiringSoon = product.expirationDate != null &&
        product.expirationDate!.isAfter(DateTime.now()) &&
        product.expirationDate!.difference(DateTime.now()).inDays <= 3;

    final hasImage = product.extra?['localImagePath'] != null ||
        (product.imageUrl != null && product.imageUrl!.isNotEmpty);

    final typeLabel = _typeLabel(product).tr();
    final locationLabel = _locationLabel(product).tr();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.only(
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
              Text(
                'product_detail.title'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: colors.onSurface),
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
                color: colors.surfaceVariant,
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
                                return _buildNoImagePlaceholder(colors);
                              },
                            ),
                    )
                  : _buildNoImagePlaceholder(colors),
            ),
          ),

          const SizedBox(height: 16),

          // NÁZEV PRODUKTU
          Center(
            child: Text(
              product.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
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
                  color: colors.onSurface.withOpacity(0.6),
                ),
              ),
            ),

          const SizedBox(height: 20),

          _buildInfoSection(
            icon: Icons.location_on,
            title: 'product_detail.location_title'.tr(),
            value: locationLabel,
            theme: theme,
          ),

          _buildInfoSection(
            icon: Icons.fastfood,
            title: 'product_detail.type_title'.tr(),
            value: typeLabel,
            theme: theme,
          ),

          // DATUM SPOTŘEBY
          if (product.expirationDate != null)
            _buildInfoSection(
              icon: Icons.calendar_today,
              title: 'product_detail.expiration_title'.tr(),
              value: _formatDate(product.expirationDate!),
              theme: theme,
            )
          else
            _buildInfoSection(
              icon: Icons.calendar_today,
              title: 'product_detail.expiration_title'.tr(),
              value: 'product_detail.not_provided'.tr(),
              theme: theme,
            ),

          // MNOŽSTVÍ
          _buildInfoSection(
            icon: Icons.scale,
            title: 'add_product.quantity'.tr(),
            value: _formatQuantity(product),
            theme: theme,
          ),

          const SizedBox(height: 16),

          // STATUS INDIKÁTOR
          if (isExpired || isExpiringSoon)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isExpired 
                    ? colors.error.withOpacity(0.12) 
                    : colors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isExpired ? colors.error : colors.primary,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: isExpired ? colors.error : colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isExpired 
                          ? 'product_detail.expired_banner'.tr()
                          : 'product_detail.expiring_banner'.tr(),
                      style: TextStyle(
                        color: isExpired ? colors.error : colors.primary,
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

  Widget _buildNoImagePlaceholder(ColorScheme colors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.photo_camera, 
          size: 40, 
          color: colors.onSurface.withOpacity(0.4)
        ),
        const SizedBox(height: 8),
        Text(
          'product_detail.no_photo'.tr(),
          style: TextStyle(
            color: colors.onSurface.withOpacity(0.4)
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String value,
    required ThemeData theme,
    bool isWarning = false,
    String? warningText,
  }) {
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: isWarning ? colors.primary : colors.onSurface.withOpacity(0.6),
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
                    color: colors.onSurface.withOpacity(0.6),
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
                          color: isWarning 
                              ? colors.primary 
                              : colors.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (warningText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          warningText,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.primary,
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

  String _typeLabel(Product p) {
    final raw = (p.extra?['type'] ?? 'food').toString();
    switch (raw) {
      case 'food':
      case 'Jídlo':
        return 'add_product.food';
      case 'beverage':
      case 'Pití':
      case 'Nápoj':
        return 'add_product.beverage';
      case 'other':
      case 'Ostatní':
        return 'add_product.other';
      default:
        return 'product_detail.not_provided';
    }
  }

  String _locationLabel(Product p) {
    final raw = (p.extra?['location'] ?? p.category).toString();
    switch (raw) {
      case 'fridge':
      case 'Lednice':
        return 'add_product.fridge';
      case 'freezer':
      case 'Mrazák':
        return 'add_product.freezer';
      case 'pantry':
      case 'Spíž':
        return 'add_product.pantry';
      default:
        // fall back to showing category as-is, but prefer not_provided if empty
        return raw.trim().isEmpty ? 'product_detail.not_provided' : raw;
    }
  }
}
  String _unitKeyFromRaw(String raw) {
    final v = raw.trim().toLowerCase();
    // handle legacy + localized labels
    if (v == 'ks' || v == 'pieces' || v == 'pcs' || v == 'stk.' || v == 'stk') {
      return 'pieces';
    }
    if (v == 'g' || v == 'kg' || v == 'ml' || v == 'l') {
      return v;
    }
    return 'pieces';
  }

  String _unitLabel(String unitKey) {
    switch (unitKey) {
      case 'pieces':
        return 'add_product.pieces'.tr();
      default:
        // g/kg/ml/l are neutral abbreviations
        return unitKey;
    }
  }

  String _formatQuantity(Product p) {
    final rawUnit = (p.extra?['unit'] ?? 'ks').toString();
    final unitKey = _unitKeyFromRaw(rawUnit);
    final unitText = _unitLabel(unitKey);

    // keep it simple: show integers without .0
    final q = p.quantity;
    final qText = (q % 1 == 0) ? q.toInt().toString() : q.toString();
    return '$qText $unitText';
  }