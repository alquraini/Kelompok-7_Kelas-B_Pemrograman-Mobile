class ExchangeRateModel {
  final String baseCurrency;
  final String targetCurrency;
  final double rate;
  final String date;

  const ExchangeRateModel({
    required this.baseCurrency,
    required this.targetCurrency,
    required this.rate,
    required this.date,
  });

  factory ExchangeRateModel.fromJson(
    Map<String, dynamic> json,
    String targetCurrency,
  ) {
    final rates = json['rates'] as Map<String, dynamic>?;
    final rawRate = rates?[targetCurrency];

    if (rawRate == null) {
      throw Exception('Data kurs untuk $targetCurrency tidak tersedia.');
    }

    return ExchangeRateModel(
      baseCurrency: (json['base'] as String?) ?? 'USD',
      targetCurrency: targetCurrency,
      rate: (rawRate as num).toDouble(),
      date: (json['date'] as String?) ?? '-',
    );
  }
}