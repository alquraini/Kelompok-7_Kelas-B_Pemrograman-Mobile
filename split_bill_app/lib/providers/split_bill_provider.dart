import 'package:flutter/foundation.dart';
import '../models/bill_model.dart';
import '../models/participant_model.dart';

class SplitBillProvider extends ChangeNotifier {
  final List<BillModel> _bills = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BillModel> get bills => List.unmodifiable(_bills);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Getter untuk memisahkan tagihan aktif dan arsip lunas
  List<BillModel> get activeBills =>
      _bills.where((bill) => !bill.isLunas).toList();

  List<BillModel> get settledBills =>
      _bills.where((bill) => bill.isLunas).toList();

  /// Sinkronisasi daftar tagihan dari lapisan data (Firestore / Local Storage)
  void setBills(List<BillModel> loadedBills) {
    _bills
      ..clear()
      ..addAll(loadedBills.map(_evaluateSettlementStatus));
    _errorMessage = null;
    notifyListeners();
  }

  /// SB-13 & SB-14: Perhitungan Bagi Rata + Pajak & Service Proporsional
  List<ParticipantModel>? calculateEqualSplit({
    required double subtotal,
    required List<String> participantNames,
    double taxPercent = 0,
    double servicePercent = 0,
  }) {
    final cleanedNames = participantNames
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    if (!_validateCommonInputs(
      subtotal: subtotal,
      participantCount: cleanedNames.length,
      taxPercent: taxPercent,
      servicePercent: servicePercent,
    )) {
      return null;
    }

    final basePerPerson = subtotal / cleanedNames.length;
    final customMap = <String, double>{
      for (final name in cleanedNames) name: basePerPerson,
    };

    return _applyProportionalTaxAndService(
      subtotal: subtotal,
      baseAmounts: customMap,
      taxPercent: taxPercent,
      servicePercent: servicePercent,
    );
  }

  /// SB-13 & SB-14: Perhitungan Custom + Pajak & Service Proporsional
  List<ParticipantModel>? calculateCustomSplit({
    required double subtotal,
    required Map<String, double> customAmounts,
    double taxPercent = 0,
    double servicePercent = 0,
  }) {
    if (!_validateCommonInputs(
      subtotal: subtotal,
      participantCount: customAmounts.length,
      taxPercent: taxPercent,
      servicePercent: servicePercent,
    )) {
      return null;
    }

    double customSum = 0;
    for (final entry in customAmounts.entries) {
      if (entry.key.trim().isEmpty) {
        _setError('Nama peserta tidak boleh kosong.');
        return null;
      }
      if (entry.value < 0) {
        _setError('Nominal untuk ${entry.key} tidak boleh negatif.');
        return null;
      }
      customSum += entry.value;
    }

    // Toleransi selisih pembulatan desimal (0.01)
    if ((customSum - subtotal).abs() > 0.01) {
      _setError(
        'Total nominal custom (Rp ${customSum.toStringAsFixed(0)}) harus sama dengan subtotal (Rp ${subtotal.toStringAsFixed(0)}).',
      );
      return null;
    }

    return _applyProportionalTaxAndService(
      subtotal: subtotal,
      baseAmounts: customAmounts,
      taxPercent: taxPercent,
      servicePercent: servicePercent,
    );
  }

  /// Menambahkan tagihan baru berbasis BillModel ke state
  Future<bool> createBill({
    required String title,
    required double subtotal,
    required List<ParticipantModel> participants,
    double taxPercent = 0,
    double servicePercent = 0,
    String userId = '',
    Future<void> Function(BillModel bill)? onSyncToData,
  }) async {
    if (title.trim().isEmpty) {
      _setError('Judul tagihan tidak boleh kosong.');
      return false;
    }
    if (participants.isEmpty) {
      _setError('Minimal harus ada 1 peserta.');
      return false;
    }

    final totalTax = subtotal * (taxPercent / 100);
    final totalService = subtotal * (servicePercent / 100);
    final grandTotal = subtotal + totalTax + totalService;

    final newBill = BillModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      judul: title.trim(),
      tanggal: DateTime.now(),
      total: double.parse(grandTotal.toStringAsFixed(2)),
      persentasePajak: taxPercent,
      persentaseLayanan: servicePercent,
      peserta: participants,
      isLunas: participants.isNotEmpty && participants.every((p) => p.isPaid),
      userId: userId,
    );

    _bills.add(newBill);
    _errorMessage = null;
    notifyListeners();

    if (onSyncToData != null) {
      await _syncBillUpdate(newBill, onSyncToData);
    }
    return true;
  }

  /// Mengubah status bayar (isPaid) peserta dan otomatis memperbarui status Lunas tagihan
  Future<bool> toggleParticipantPaid({
    required String billId,
    required String participantId,
    bool? isPaid,
    Future<void> Function(BillModel updatedBill)? onSyncToData,
  }) async {
    final billIndex = _bills.indexWhere((b) => b.id == billId);
    if (billIndex == -1) {
      _setError('Tagihan tidak ditemukan.');
      return false;
    }

    final currentBill = _bills[billIndex];
    bool participantFound = false;

    final updatedParticipants = currentBill.peserta.map((participant) {
      if (participant.id == participantId) {
        participantFound = true;
        return participant.copyWith(isPaid: isPaid ?? !participant.isPaid);
      }
      return participant;
    }).toList();

    if (!participantFound) {
      _setError('Peserta tidak ditemukan dalam tagihan ini.');
      return false;
    }

    // Otomatis ubah status tagihan menjadi Lunas jika seluruh peserta isPaid == true
    final allPaid = updatedParticipants.isNotEmpty &&
        updatedParticipants.every((p) => p.isPaid);

    final updatedBill = currentBill.copyWith(
      peserta: updatedParticipants,
      isLunas: allPaid,
    );

    _bills[billIndex] = updatedBill;
    _errorMessage = null;
    notifyListeners();

    // Sinkronkan perubahan status ke lapisan data (jika callback service diberikan)
    if (onSyncToData != null) {
      return await _syncBillUpdate(updatedBill, onSyncToData);
    }

    return true;
  }

  /// Helper mengevaluasi status lunas suatu BillModel
  BillModel _evaluateSettlementStatus(BillModel bill) {
    final allPaid =
        bill.peserta.isNotEmpty && bill.peserta.every((p) => p.isPaid);
    return bill.copyWith(isLunas: allPaid);
  }

  /// Helper sinkronisasi perubahan tagihan ke lapisan data (Firestore)
  Future<bool> _syncBillUpdate(
    BillModel bill,
    Future<void> Function(BillModel bill) onSyncToData,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      await onSyncToData(bill);
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menyinkronkan status tagihan: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Validasi umum input nominal & peserta
  bool _validateCommonInputs({
    required double subtotal,
    required int participantCount,
    required double taxPercent,
    required double servicePercent,
  }) {
    if (subtotal <= 0) {
      _setError('Subtotal tagihan harus lebih besar dari Rp 0.');
      return false;
    }
    if (participantCount <= 0) {
      _setError('Tambahkan minimal 1 peserta patungan.');
      return false;
    }
    if (taxPercent < 0 || servicePercent < 0) {
      _setError('Persentase pajak atau biaya layanan tidak boleh negatif.');
      return false;
    }
    _errorMessage = null;
    return true;
  }

  /// Pembagian pajak (PPN) & biaya layanan secara proporsional sesuai porsi tagihan
  List<ParticipantModel> _applyProportionalTaxAndService({
    required double subtotal,
    required Map<String, double> baseAmounts,
    required double taxPercent,
    required double servicePercent,
  }) {
    final totalTax = subtotal * (taxPercent / 100);
    final totalService = subtotal * (servicePercent / 100);
    int index = 0;

    final result = baseAmounts.entries.map((entry) {
      index++;
      final ratio = entry.value / subtotal;
      final taxShare = totalTax * ratio;
      final serviceShare = totalService * ratio;
      final finalAmount = entry.value + taxShare + serviceShare;

      return ParticipantModel(
        id: 'p_$index',
        nama: entry.key.trim(),
        nominal: double.parse(finalAmount.toStringAsFixed(2)),
        isPaid: false,
      );
    }).toList();

    notifyListeners();
    return result;
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}