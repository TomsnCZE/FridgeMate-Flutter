import 'package:hive/hive.dart';
import '../models/product.dart';

class DatabaseService {
  static const String boxName = 'productsBox';

  Future<void> addProduct(Product product) async {
    final box = await Hive.openBox(boxName);
    await box.add(product.toJson());
    print('✅ Produkt přidán: ${product.name}'); // DEBUG
  }

  Future<List<Product>> getProducts() async {
    final box = await Hive.openBox(boxName);
    final products = box.values
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    print('✅ Načteno produktů: ${products.length}'); // DEBUG
    return products;
  }

  Future<void> deleteProduct(int index) async {
    final box = await Hive.openBox(boxName);
    await box.deleteAt(index);
  }

  Future<void> clearAll() async {
    final box = await Hive.openBox(boxName);
    await box.clear();
  }
}