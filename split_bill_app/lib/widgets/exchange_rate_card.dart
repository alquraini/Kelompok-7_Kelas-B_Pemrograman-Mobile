import 'package:flutter/material.dart';
import '../models/exchange_rate_model.dart';
import '../services/api_service.dart';

class ExchangeRateCard extends StatefulWidget {
  final String initialBaseCurrency;
  final String targetCurrency;

  const ExchangeRateCard({
    super.key,
    this.initialBaseCurrency = 'USD',
    this.targetCurrency = 'IDR',
  });

  @override
  State<ExchangeRateCard> createState() => _ExchangeRateCardState();
}

class _ExchangeRateCardState extends State<ExchangeRateCard> {
  final ApiService _apiService = ApiService();
  late String _selectedBase;
  late Future<ExchangeRateModel> _rateFuture;

  static const List<String> _currencies = ['USD', 'SGD', 'EUR', 'JPY'];

  @override
  void initState() {
    super.initState();
    _selectedBase = widget.initialBaseCurrency;
    _rateFuture = _loadRate();
  }

  Future<ExchangeRateModel> _loadRate() {
    return _apiService.fetchExchangeRate(
      base: _selectedBase,
      target: widget.targetCurrency,
    );
  }

  void _refreshRate() {
    setState(() {
      _rateFuture = _loadRate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kurs ke ${widget.targetCurrency}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: _selectedBase,
                      underline: const SizedBox(),
                      items: _currencies
                          .map(
                            (code) => DropdownMenuItem(
                              value: code,
                              child: Text(code),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedBase = value;
                          _rateFuture = _loadRate();
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Muat ulang kurs',
                      onPressed: _refreshRate,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<ExchangeRateModel>(
              future: _rateFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gagal memuat kurs: ${snapshot.error}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _refreshRate,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  );
                }

                final data = snapshot.data;
                if (data == null) {
                  return const Text('Data kurs tidak ditemukan.');
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1 ${data.baseCurrency} = ${data.rate} ${data.targetCurrency}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Per tanggal: ${data.date}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}