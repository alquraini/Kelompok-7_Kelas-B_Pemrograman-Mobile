import 'package:flutter/foundation.dart';
import '../models/bill_model.dart';
import '../models/participant_model.dart';

class SplitBillProvider extends ChangeNotifier {
  final List<BillModel> _bills = [];
  final bool _isLoading = false;
  String? _errorMessage;

  List<BillModel> get bills => List.unmodifiable(_bills);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Getter untuk filter Tab Beranda (SB-18)
  List<BillModel> get activeBills =>
      _bills.where((bill) => !bill.isLunas).toList();

  List<BillModel> get settledBills =>
      _bills.where((bill) => bill.isLunas).toList();

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
        'Total nominal custom (Rp ${customSum.toStringAsFixed(0)}) harus sama dengan subtotal (Rp${subtotal.toStringAsFixed(0)}).',
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
  bool createBill({
    required String title,
    required double subtotal,
    required List<ParticipantModel> participants,
    double taxPercent = 0,
    double servicePercent = 0,
    String userId = '',
  }) {
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
      isLunas: participants.every((p) => p.isPaid),
      userId: userId,
    );

    _bills.add(newBill);
    _errorMessage = null;
    notifyListeners();
    return true;
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
      final finalAmount = entry.value + taxShare + service