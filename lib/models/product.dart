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

  // JSON (stávající)
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imageUrl': imageUrl,
        'brand': brand,
        'category': category,
        'expirationDate': expirationDate?.toIso8601String(),
        'quantity': quantity,
        'extra': extra,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'],
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

  // SQLite map
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
      id: map['id'],
      name: map['name'],
      brand: map['brand'],
      category: map['category'],
      quantity: (map['quantity'] ?? 1).toDouble(),
      expirationDate: map['expirationDate'] != null
          ? DateTime.parse(map['expirationDate'])
          : null,
      extra: {
        'unit': map['unit'],
        'type': map['type'],
        'localImagePath': map['localImagePath'],
      },
    );
  }
}