import 'package:flutter/material.dart';
import '../providers/app_routes.dart';
import '../widgets/exchange_rate_card.dart';

class CreateBillScreen extends StatelessWidget {
  const CreateBillScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Tagihan Baru')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ExchangeRateCard(
              initialBaseCurrency: 'USD',
              targetCurrency: 'IDR',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.billDetail),
              child: const Text('Simpan & Lihat Detail'),
            ),
          ],
        ),
      ),
    );
  }
}