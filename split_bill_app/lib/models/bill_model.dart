import 'participant_model.dart';

class BillModel {
  final String id;
  final String judul;
  final DateTime tanggal;
  final double total;
  final double persentasePajak;
  final double persentaseLayanan;
  final List<ParticipantModel> peserta;
  final bool isLunas;
  final String userId;

  const BillModel({
    required this.id,
    required this.judul,
    required this.tanggal,
    required this.total,
    this.persentasePajak = 0.0,
    this.persentaseLayanan = 0.0,
    this.peserta = const [],
    this.isLunas = false,
    required this.userId,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    final rawParticipants = json['peserta'] ?? json['participants'];
    final parsedParticipants = rawParticipants is List
        ? rawParticipants
            .whereType()
            .map(
              (item) => ParticipantModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : <ParticipantModel>[];

    return BillModel(
      id: (json['id'] ?? '').toString(),
      judul: (json['judul'] ?? '').toString(),
      tanggal: _toDateTime(json['tanggal']),
      total: _toDouble(json['total']),
      persentasePajak: _toDouble(
        json['persentasePajak'] ?? json['persentase_pajak'],
      ),
      persentaseLayanan: _toDouble(
        json['persentaseLayanan'] ?? json['persentase_layanan'],
      ),
      peserta: parsedParticipants,
      isLunas: _toBool(json['isLunas'] ?? json['is_lunas']),
      userId: (json['userId'] ?? json['user_id'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judul': judul,
      'tanggal': tanggal.toIso8601String(),
      'total': total,
      'persentasePajak': persentasePajak,
      'persentaseLayanan': persentaseLayanan,
      'peserta': peserta.map((p) => p.toJson()).toList(),
      'isLunas': isLunas,
      'userId': userId,
    };
  }

  BillModel copyWith({
    String? id,
    String? judul,
    DateTime? tanggal,
    double? total,
    double? persentasePajak,
    double? persentaseLayanan,
    List<ParticipantModel>? peserta,
    bool? isLunas,
    String? userId,
  }) {
    return BillModel(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      tanggal: tanggal ?? this.tanggal,
      total: total ?? this.total,
      persentasePajak: persentasePajak ?? this.persentasePajak,
      persentaseLayanan: persentaseLayanan ?? this.persentaseLayanan,
      peserta: peserta ?? this.peserta,
      isLunas: isLunas ?? this.isLunas,
      userId: userId ?? this.userId,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value != null && value.toString().contains('toDate')) {
      // Mendukung Timestamp Firestore jika suatu saat dikirim langsung
      return (value as dynamic).toDate() as DateTime;
    }
    return DateTime.now();
  }
}