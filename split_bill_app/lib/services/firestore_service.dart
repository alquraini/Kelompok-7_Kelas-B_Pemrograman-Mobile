import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bill_model.dart';


class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collectionName = 'bills';

  CollectionReference get _billsRef => _db.collection(_collectionName);

  /// Tambah tagihan baru menggunakan collection().add()
  Future<String> addBill(BillModel bill) async {
    try {
      final docRef = await _billsRef.add(bill.toJson());
      await docRef.update({'id': docRef.id});
      return docRef.id;
    } on FirebaseException catch (e) {
      throw Exception(
        'Gagal menambah tagihan ke Firestore: ${e.message ?? e.code}',
      );
    } catch (e) {
      throw Exception('Terjadi kesalahan saat menambah tagihan: $e');
    }
  }

  /// Baca daftar tagihan sekali (Future)
  Future<List<BillModel>> getBills({String? userId}) async {
    try {
      var query = _billsRef.orderBy('tanggal', descending: true);
      if (userId != null && userId.isNotEmpty) {
        query = query.where('userId', isEqualTo: userId);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final raw = doc.data();
        final data = raw is Map
            ? Map<String, dynamic>.from(raw)
            : <String, dynamic>{};
        final currentId = (data['id'] ?? '').toString();
        data['id'] = currentId.isEmpty ? doc.id : currentId;
        return BillModel.fromJson(data);
      }).toList();
    } on FirebaseException catch (e) {
      throw Exception(
        'Gagal memuat daftar tagihan: ${e.message ?? e.code}',
      );
    } catch (e) {
      throw Exception('Terjadi kesalahan saat memuat tagihan: $e');
    }
  }

  /// Pantau daftar tagihan secara real-time (Stream)
  Stream<List<BillModel>> watchBills({String? userId}) {
    var query = _billsRef.orderBy('tanggal', descending: true);
    if (userId != null && userId.isNotEmpty) {
      query = query.where('userId', isEqualTo: userId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final raw = doc.data();
        final data = raw is Map
            ? Map<String, dynamic>.from(raw)
            : <String, dynamic>{};
        final currentId = (data['id'] ?? '').toString();
        data['id'] = currentId.isEmpty ? doc.id : currentId;
        return BillModel.fromJson(data);
      }).toList();
    });
  }

  /// Update status bayar peserta (isPaid) & status lunas tagihan (isLunas)
  Future<void> updateParticipantPayment({
    required String billId,
    required String participantId,
    required bool isPaid,
  }) async {
    try {
      final docRef = _billsRef.doc(billId);
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        final rawData = snapshot.data();
        if (!snapshot.exists || rawData == null || rawData is! Map) {
          throw Exception('Tagihan tidak ditemukan di Firestore.');
        }

        final data = Map<String, dynamic>.from(rawData);
        final currentId = (data['id'] ?? '').toString();
        data['id'] = currentId.isEmpty ? snapshot.id : currentId;
        final bill = BillModel.fromJson(data);

        final updatedParticipants = bill.peserta.map((p) {
          if (p.id == participantId) {
            return p.copyWith(isPaid: isPaid);
          }
          return p;
        }).toList();

        final allPaid = updatedParticipants.isNotEmpty &&
            updatedParticipants.every((p) => p.isPaid);

        transaction.update(docRef, {
          'peserta': updatedParticipants.map((p) => p.toJson()).toList(),
          'isLunas': allPaid,
        });
      });
    } on FirebaseException catch (e) {
      throw Exception(
        'Gagal memperbarui status bayar peserta: ${e.message ?? e.code}',
      );
    } catch (e) {
      throw Exception('Terjadi kesalahan saat memperbarui status bayar: $e');
    }
  }

  /// Hapus tagihan berdasarkan billId
  Future<void> deleteBill(String billId) async {
    try {
      await _billsRef.doc(billId).delete();
    } on FirebaseException catch (e) {
      throw Exception('Gagal menghapus tagihan: ${e.message ?? e.code}');
    } catch (e) {
      throw Exception('Terjadi kesalahan saat menghapus tagihan: $e');
    }
  }
}