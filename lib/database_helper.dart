import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'mylist.db'),
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE items (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            name TEXT NOT NULL,
            artist TEXT NOT NULL,
            image TEXT NOT NULL,
            parentId TEXT,
            isExpanded INTEGER DEFAULT 0 -- New column
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE items ADD COLUMN parentId TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE items ADD COLUMN isExpanded INTEGER DEFAULT 0');
        }
      },
    );
  }

  Future<void> insertItem(Map<String, dynamic> item) async {
    final db = await database;
    await db.insert('items', item, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    final db = await database;
    return db.query('items', orderBy: 'rowid ASC');
  }

  Future<void> deleteItem(String id) async {
    final db = await database;
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteItemsByParentId(String parentId) async {
    final db = await database;
    await db.delete('items', where: 'parentId = ?', whereArgs: [parentId]);
  }

  Future<void> updateItemExpanded(String id, bool isExpanded) async {
    final db = await database;
    await db.update(
      'items',
      {'isExpanded': isExpanded ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}