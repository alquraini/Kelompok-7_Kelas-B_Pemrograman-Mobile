class ParticipantModel {
  final String id;
  final String nama;
  final double nominal;
  final bool isPaid;

  const ParticipantModel({
    required this.id,
    required this.nama,
    required this.nominal,
    this.isPaid = false,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      id: (json['id'] ?? '').toString(),
      nama: (json['nama'] ?? '').toString(),
      nominal: _toDouble(json['nominal']),
      isPaid: _toBool(json['isPaid'] ?? json['is_paid']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'nominal': nominal,
      'isPaid': isPaid,
    };
  }

  ParticipantModel copyWith({
    String? id,
    String? nama,
    double? nominal,
    bool? isPaid,
  }) {
    return ParticipantModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      nominal: nominal ?? this.nominal,
      isPaid: isPaid ?? this.isPaid,
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
}