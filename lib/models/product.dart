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
      name: map['name'] as String,
      brand: map['brand'] as String?,
      category: (map['category'] as String?) ?? 'fridge',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      expirationDate: map['expirationDate'] != null
          ? DateTime.tryParse(map['expirationDate'] as String)
          : null,
      extra: {
        'unit': (map['unit'] as String?) ?? 'ks',
        'type': (map['type'] as String?) ?? 'food',
        'localImagePath': map['localImagePath'] as String?,
      },
    );
  }
}