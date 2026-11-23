import 'package:flutter/material.dart';
import '../providers/app_routes.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login - Split Bill')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
          child: const Text('Masuk ke Home'),
        ),
      ),
    );
  }
}