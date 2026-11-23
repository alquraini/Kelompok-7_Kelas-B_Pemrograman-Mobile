import 'package:flutter/material.dart';

class BillDetailScreen extends StatelessWidget {
  const BillDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rincian Pembagian Tagihan')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kembali'),
        ),
      ),
    );
  }
}