import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/bill_model.dart';
import '../models/participant_model.dart';

class LocalStorageService {
  LocalStorageService._();
  static final LocalStorageService instance = LocalStorageService._();

  static const String _dbName = 'split_bill_offline.db';
  static const int _dbVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bills (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL DEFAULT '',
        judul TEXT NOT NULL,
        tanggal TEXT NOT NULL,
        total REAL NOT NULL,
        persentase_pajak REAL NOT NULL DEFAULT 0,
        persentase_layanan REAL NOT NULL DEFAULT 0,
        is_lunas INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE participants (
        id TEXT NOT NULL,
        bill_id TEXT NOT NULL,
        nama TEXT NOT NULL,
        nominal REAL NOT NULL,
        is_paid INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (bill_id, id),
        FOREIGN KEY (bill_id) REFERENCES bills (id) ON DELETE CASCADE
      )
    ''');
  }

  /// INSERT / REPLACE satu tagihan beserta seluruh pesertanya
  Future<void> insertBill(BillModel bill) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'bills',
        {
          'id': bill.id,
          'user_id': bill.userId,
          'judul': bill.judul,
          'tanggal': bill.tanggal.toIso8601String(),
          'total': bill.total,
          'persentase_pajak': bill.persentasePajak,
          'persentase_layanan': bill.persentaseLayanan,
          'is_lunas': bill.isLunas ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.delete(
        'participants',
        where: 'bill_id = ?',
        whereArgs: [bill.id],
      );

      for (final p in bill.peserta) {
        await txn.insert(
          'participants',
          {
            'id': p.id,
            'bill_id': bill.id,
            'nama': p.nama,
            'nominal': p.nominal,
            'is_paid': p.isPaid ? 1 : 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// READ seluruh tagihan offline beserta pesertanya
  Future<List<BillModel>> getBills() async {
    final db = await database;
    final billRows = await db.query(
      'bills',
      orderBy: 'tanggal DESC',
    );

    final List<BillModel> result = [];
    for (final row in billRows) {
      final billId = row['id'] as String;
      final participantRows = await db.query(
        'participants',
        where: 'bill_id = ?',
        whereArgs: [billId],
      );

      final peserta = participantRows
          .map(
            (pRow) => ParticipantModel(
              id: pRow['id'] as String,
              nama: pRow['nama'] as String,
              nominal: (pRow['nominal'] as num).toDouble(),
              isPaid: (pRow['is_paid'] as int) == 1,
            ),
          )
          .toList();

      result.add(
        BillModel(
          id: billId,
          judul: row['judul'] as String,
          userId: (row['user_id'] as String?) ?? '',
          tanggal: DateTime.parse(row['tanggal'] as String),
          total: (row['total'] as num).toDouble(),
          persentasePajak: (row['persentase_pajak'] as num).toDouble(),
          persentaseLayanan: (row['persentase_layanan'] as num).toDouble(),
          peserta: peserta,
          isLunas: (row['is_paid'] ?? row['is_lunas']) == 1,
        ),
      );
    }
    return result;
  }

  /// UPDATE status bayar peserta dan perbarui status lunas tagihan
  Future<void> updateParticipantPayment({
    required String billId,
    required String participantId,
    required bool isPaid,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'participants',
        {'is_paid': isPaid ? 1 : 0},
        where: 'bill_id = ? AND id = ?',
        whereArgs: [billId, participantId],
      );

      final allParticipants = await txn.query(
        'participants',
        columns: ['is_paid'],
        where: 'bill_id = ?',
        whereArgs: [billId],
      );

      final allPaid = allParticipants.isNotEmpty &&
          allParticipants.every((p) => (p['is_paid'] as int) == 1);

      await txn.update(
        'bills',
        {'is_lunas': allPaid ? 1 : 0},
        where: 'id = ?',
        whereArgs: [billId],
      );
    });
  }
}