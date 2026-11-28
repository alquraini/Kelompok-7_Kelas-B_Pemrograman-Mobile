import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_db_service.dart';

class SyncService {
  final FirebaseFirestore _firestore;
  final LocalDbService _localDb;

  SyncService({
    FirebaseFirestore? firestore,
    LocalDbService? localDb,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _localDb = localDb ?? LocalDbService.instance;

  /// 1. Muat dari Firestore & simpan ke SQLite; jika gagal/offline, fallback ke SQLite
  Future<List> loadBillsWithFallback() async {
    try {
      final snapshot = await _firestore.collection('bills').get();

      for (final doc in snapshot.docs) {
        final payload = <String, dynamic>{
          'id': doc.id,
          ...doc.data(),
        };
        await _localDb.upsertBill(
          id: doc.id,
          dataJson: jsonEncode(payload),
          isSynced: true,
        );
      }

      return snapshot.docs
          .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
          .toList();
    } catch (_) {
      // Fallback ke data lokal SQLite saat offline / gagal terhubung
      final cachedRows = await _localDb.getAllCachedBills();
      return cachedRows
          .map((row) => jsonDecode(row['data_json'] as String) as Map<String, dynamic>)
          .toList();
    }
  }

  /// 2. Simpan perubahan lokal (saat offline) ke SQLite dengan isSynced = false
  Future<void> saveBillLocalFirst(Map<String, dynamic> billData) async {
    final id = billData['id'] as String;
    await _localDb.upsertBill(
      id: id,
      dataJson: jsonEncode(billData),
      isSynced: false,
    );

    // Coba langsung sinkronkan jika sedang online
    await syncPendingBillsToFirestore();
  }

  /// 3. Sinkronkan ulang semua data yang belum tersinkron ke Firestore
  Future<void> syncPendingBillsToFirestore() async {
    try {
      final unsyncedRows = await _localDb.getUnsyncedBills();
      for (final row in unsyncedRows) {
        final id = row['id'] as String;
        final data = jsonDecode(row['data_json'] as String) as Map<String, dynamic>;
        final payload = Map<String, dynamic>.from(data)..remove('id');

        await _firestore.collection('bills').doc(id).set(
              payload,
              SetOptions(merge: true),
            )
            .timeout(const Duration(seconds: 4));
            
        await _localDb.markAsSynced(id);
      }
    } catch (_) {
      // Tetap biarkan is_synced = 0 di SQLite agar dicoba lagi saat online
    }
  }
}