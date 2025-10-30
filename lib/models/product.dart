class Product {
  final String name;
  final String? imageUrl;
  final String? brand;
  final String category;
  final DateTime? expirationDate;
  final double quantity;
  final Map<String, dynamic>? extra;

  Product({
    required this.name,
    this.imageUrl,
    this.brand,
    required this.category,
    this.expirationDate,
    this.quantity = 1,
    this.extra,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'imageUrl': imageUrl,
        'brand': brand,
        'category': category,
        'expirationDate': expirationDate?.toIso8601String(),
        'quantity': quantity,
        'extra': extra,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        name: json['name'],
        imageUrl: json['imageUrl'],
        brand: json['brand'],
        category: json['category'],
        expirationDate: json['expirationDate'] != null
            ? DateTime.parse(json['expirationDate'])
            : null,
        quantity: (json['quantity'] ?? 1).toDouble(),
        extra: json['extra'] != null
            ? Map<String, dynamic>.from(json['extra'])
            : null,
      );
}