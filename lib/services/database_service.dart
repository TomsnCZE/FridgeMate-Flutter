import 'package:sqflite/sqflite.dart';

Future<Database> openMyDatabase() async {
  return openDatabase(
    'my_database.db',
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE products (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          brand TEXT,
          category TEXT,
          ingredients TEXT,
          calories TEXT,
          imageUrl TEXT,
          type TEXT
        )
      ''');
    },
  );
}
