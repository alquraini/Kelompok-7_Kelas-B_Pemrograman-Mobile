import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/bill_model.dart';
import '../models/participant_model.dart';

/// Model opsional untuk menampung rincian item pesanan tiap peserta saat dicetak ke nota
class BillLineItem {
  final String name;
  final double price;

  const BillLineItem({
    required this.name,
    required this.price,
  });
}

class ShareService {
  /// 1. AKSI UNTUK TOMBOL "SALIN" PER PESERTA (Nota Individu ke Clipboard)
  static Future<String> copyIndividualBillText({
    required BillModel bill,
    required ParticipantModel participant,
    List<BillLineItem> items = const [],
    double? taxShare,
    double? serviceShare,
    double? discountShare,
    String? paymentAccountInfo,
  }) async {
    final text = formatIndividualBillText(
      bill: bill,
      participant: participant,
      items: items,
      taxShare: taxShare,
      serviceShare: serviceShare,
      discountShare: discountShare,
      paymentAccountInfo: paymentAccountInfo,
    );
    await Clipboard.setData(ClipboardData(text: text));
    return text;
  }

  /// Menyusun teks nota formal khusus untuk 1 peserta lengkap dengan pesanan & pajak
  static String formatIndividualBillText({
    required BillModel bill,
    required ParticipantModel participant,
    List<BillLineItem> items = const [],
    double? taxShare,
    double? serviceShare,
    double? discountShare,
    String? paymentAccountInfo,
  }) {
    final buffer = StringBuffer();
    final status = participant.isPaid ? 'LUNAS' : 'BELUM LUNAS';

    // Hitung estimasi porsi pajak & layanan proporsional jika tidak dikirim eksplisit dari UI
    final totalMultiplier =
        1 + ((bill.persentasePajak + bill.persentaseLayanan) / 100);
    final estimatedBase = totalMultiplier > 0
        ? (participant.nominal / totalMultiplier)
        : participant.nominal;
    final computedTax =
        taxShare ?? (estimatedBase * (bill.persentasePajak / 100));
    final computedService =
        serviceShare ?? (estimatedBase * (bill.persentaseLayanan / 100));

    buffer.writeln('*NOTA TAGIHAN INDIVIDU*');
    buffer.writeln('====================================');
    buffer.writeln('Tagihan       : ${bill.judul}');
    buffer.writeln('Tanggal       : ${_formatDate(bill.tanggal)}');
    buffer.writeln('Peserta       : ${participant.nama}');
    buffer.writeln('------------------------------------');

    if (items.isNotEmpty) {
      buffer.writeln('*RINCIAN PESANAN*');
      for (final item in items) {
        buffer.writeln('- ${item.name} : ${_formatCurrency(item.price)}');
      }
      buffer.writeln('------------------------------------');
    } else {
      buffer.writeln('Porsi Pesanan : ${_formatCurrency(estimatedBase)}');
    }

    if (computedTax > 0) {
      buffer.writeln(
        'Pajak (${bill.persentasePajak.toStringAsFixed(0)}%)   : ${_formatCurrency(computedTax)}',
      );
    }

    if (computedService > 0) {
      buffer.writeln(
        'Layanan (${bill.persentaseLayanan.toStringAsFixed(0)}%) : ${_formatCurrency(computedService)}',
      );
    }

    if (discountShare != null && discountShare > 0) {
      buffer.writeln('Diskon        : -${_formatCurrency(discountShare)}');
    }

    buffer.writeln('------------------------------------');
    buffer.writeln('*TOTAL BAYAR   : ${_formatCurrency(participant.nominal)}*');
    buffer.writeln('Status        : $status');

    if (paymentAccountInfo != null && paymentAccountInfo.trim().isNotEmpty) {
      buffer.writeln('------------------------------------');
      buffer.writeln('*TUJUAN TRANSFER*');
      buffer.writeln(paymentAccountInfo.trim());
    }

    buffer.writeln('====================================');
    if (participant.isPaid) {
      buffer.writeln('Terima kasih, pembayaran Anda telah tercatat lunas.');
    } else {
      buffer.writeln(
        'Mohon melakukan pembayaran sesuai nominal pada nota ini. Terima kasih.',
      );
    }

    return buffer.toString().trimRight();
  }

  /// 2. AKSI UNTUK TOMBOL "BAGIKAN TAGIHAN KE WHATSAPP" (Nota Keseluruhan)
  static Future<void> shareBillSummary(
    BillModel bill, {
    Map<String, List<BillLineItem>> participantItems = const {},
    String? paymentAccountInfo,
  }) async {
    final text = formatBillSummaryText(
      bill,
      participantItems: participantItems,
      paymentAccountInfo: paymentAccountInfo,
    );
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Nota Tagihan - ${bill.judul}',
      ),
    );
  }

  /// Menyusun teks nota formal seluruh tagihan lengkap dengan rincian menu per peserta
  static String formatBillSummaryText(
    BillModel bill, {
    Map<String, List<BillLineItem>> participantItems = const {},
    String? paymentAccountInfo,
  }) {
    final buffer = StringBuffer();
    final totalMultiplier =
        1 + ((bill.persentasePajak + bill.persentaseLayanan) / 100);
    final subtotal =
        totalMultiplier > 0 ? (bill.total / totalMultiplier) : bill.total;

    buffer.writeln('*NOTA PEMBAGIAN TAGIHAN*');
    buffer.writeln('====================================');
    buffer.writeln('Judul Tagihan : ${bill.judul}');
    buffer.writeln('Tanggal       : ${_formatDate(bill.tanggal)}');
    buffer.writeln('Status        : ${bill.isLunas ? 'LUNAS' : 'BELUM LUNAS'}');
    buffer.writeln('------------------------------------');
    buffer.writeln('*RINCIAN PESERTA & PESANAN*');

    for (var i = 0; i < bill.peserta.length; i++) {
      final p = bill.peserta[i];
      final status = p.isPaid ? 'Lunas' : 'Belum Lunas';
      buffer.writeln(
        '${i + 1}. *${p.nama}* — ${_formatCurrency(p.nominal)} ($status)',
      );

      final items = participantItems[p.id] ?? participantItems[p.nama] ?? [];
      for (final item in items) {
        buffer.writeln('   • ${item.name} (${_formatCurrency(item.price)})');
      }
    }

    buffer.writeln('------------------------------------');
    buffer.writeln('*RINGKASAN BIAYA*');
    buffer.writeln('Subtotal      : ${_formatCurrency(subtotal)}');

    if (bill.persentasePajak > 0) {
      final totalTax = subtotal * (bill.persentasePajak / 100);
      buffer.writeln(
        'Pajak (${bill.persentasePajak.toStringAsFixed(0)}%)   : ${_formatCurrency(totalTax)}',
      );
    }

    if (bill.persentaseLayanan > 0) {
      final totalService = subtotal * (bill.persentaseLayanan / 100);
      buffer.writeln(
        'Layanan (${bill.persentaseLayanan.toStringAsFixed(0)}%) : ${_formatCurrency(totalService)}',
      );
    }

    buffer.writeln('*TOTAL TAGIHAN : ${_formatCurrency(bill.total)}*');

    if (paymentAccountInfo != null && paymentAccountInfo.trim().isNotEmpty) {
      buffer.writeln('------------------------------------');
      buffer.writeln('*TUJUAN TRANSFER*');
      buffer.writeln(paymentAccountInfo.trim());
    }

    buffer.writeln('====================================');
    if (bill.isLunas) {
      buffer.writeln(
        'Seluruh kewajiban pembayaran pada tagihan ini telah diselesaikan.',
      );
    } else {
      buffer.writeln(
        'Mohon melakukan penyelesaian pembayaran sesuai rincian masing-masing.',
      );
    }

    return buffer.toString().trimRight();
  }

  /// Helper pemformatan mata uang Rupiah dengan pemisah ribuan titik
  static String _formatCurrency(double amount) {
    final rounded = amount.round().toString();
    final formatted = rounded.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'Rp $formatted';
  }

  /// Helper pemformatan tanggal DD/MM/YYYY
  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}