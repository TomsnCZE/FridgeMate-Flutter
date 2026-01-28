import 'package:easy_localization/easy_localization.dart';

class Product {
  final int? id;
  final String name;
  final String? imageUrl;
  final String? brand;
  final String category;
  final DateTime? expirationDate;
  final double quantity;
  final Map<String, dynamic>? extra;

  Product({
    this.id,
    required this.name,
    this.imageUrl,
    this.brand,
    required this.category,
    this.expirationDate,
    this.quantity = 1,
    this.extra,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'category': category,
      'quantity': quantity,
      'unit': extra?['unit'],
      'type': extra?['type'],
      'expirationDate': expirationDate?.toIso8601String(),
      'localImagePath': extra?['localImagePath'],
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'],
      brand: map['brand'],
      category: map['category'] ?? 'add_product.food'.tr(),
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      expirationDate: map['expirationDate'] != null
          ? DateTime.tryParse(map['expirationDate'])
          : null,
      extra: {
        'unit': map['unit'] ?? 'add_product.pieces'.tr(),
        'type': map['type'] ?? 'add_product.food'.tr(),
        'localImagePath': map['localImagePath'],
      },
    );
  }
}