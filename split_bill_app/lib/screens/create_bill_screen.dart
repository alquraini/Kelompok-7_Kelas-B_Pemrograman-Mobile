import 'package:flutter/material.dart';
import '../providers/app_routes.dart';
import '../widgets/exchange_rate_card.dart';
import '../services/sync_service.dart';

class CreateBillScreen extends StatefulWidget {
  const CreateBillScreen({super.key});

  @override
  State<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends State<CreateBillScreen> {
  bool _isSaving = false;

  Future<void> _saveAndOpenDetail() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final billId = DateTime.now().millisecondsSinceEpoch.toString();
    final nowIso = DateTime.now().toIso8601String();

    final billData = <String, dynamic>{
      'id': billId,
      'title': 'Tagihan #${billId.substring(billId.length - 4)}',
      'baseCurrency': 'USD',
      'targetCurrency': 'IDR',
      'amount': 100.0,
      'createdAt': nowIso,
      'updatedAt': nowIso,
    };

    try {
      await SyncService().saveBillLocalFirst(billData);

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.billDetail,
        arguments: billId,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan tagihan: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveAndOpenDetail,
              child: Text(_isSaving ? 'Menyimpan...' : 'Simpan & Lihat Detail'),
            ),
          ],
        ),
      ),
    );
  }
}