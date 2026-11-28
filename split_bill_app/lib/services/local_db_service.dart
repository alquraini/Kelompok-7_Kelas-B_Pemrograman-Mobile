import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDbService {
  static final LocalDbService instance = LocalDbService._internal();
  LocalDbService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'split_bill_cache.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE bills_cache (
            id TEXT PRIMARY KEY,
            data_json TEXT NOT NULL,
            is_synced INTEGER NOT NULL DEFAULT 1,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> upsertBill({
    required String id,
    required String dataJson,
    required bool isSynced,
  }) async {
    final db = await database;
    await db.insert(
      'bills_cache',
      {
        'id': id,
        'data_json': dataJson,
        'is_synced': isSynced ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List> getAllCachedBills() async {
    final db = await database;
    return db.query('bills_cache', orderBy: 'updated_at DESC');
  }

  Future<List> getUnsyncedBills() async {
    final db = await database;
    return db.query(
      'bills_cache',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
  }

  Future<void> markAsSynced(String id) async {
    final db = await database;
    await db.update(
      'bills_cache',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}