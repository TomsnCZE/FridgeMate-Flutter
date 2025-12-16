import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fridge.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        brand TEXT,
        category TEXT,
        quantity REAL,
        unit TEXT,
        type TEXT,
        expirationDate TEXT,
        localImagePath TEXT
      )
    ''');
  }

  // INSERT -> returns inserted id
  Future<int> insertProduct(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('products', data);
  }

  // GET ALL
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await instance.database;
    return await db.query('products', orderBy: 'name ASC');
  }

  // DELETE
  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // UPDATE
  Future<int> updateProduct(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update(
      'products',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}