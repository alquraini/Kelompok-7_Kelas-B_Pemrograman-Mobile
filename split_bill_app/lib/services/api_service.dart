import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/exchange_rate_model.dart';

class ApiService {
  Future<ExchangeRateModel> fetchExchangeRate({
    String base = 'USD',
    String target = 'IDR',
  }) async {
    final uri = Uri.parse(
      'https://api.frankfurter.app/latest?from=$base&to=$target',
    );

    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return ExchangeRateModel.fromJson(decoded, target);
    } else {
      throw Exception('Gagal mengambil data kurs (HTTP ${response.statusCode})');
    }
  }
}