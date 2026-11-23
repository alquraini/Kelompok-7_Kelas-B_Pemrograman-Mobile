import 'package:flutter/material.dart';
import '../providers/app_routes.dart';

class CreateBillScreen extends StatelessWidget {
  const CreateBillScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Tagihan Baru')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.billDetail),
          child: const Text('Simpan & Lihat Detail'),
        ),
      ),
    );
  }
}