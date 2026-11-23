import 'package:flutter/material.dart';
import 'providers/app_routes.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_bill_screen.dart';
import 'screens/bill_detail_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const SplitBillApp());
}

class SplitBillApp extends StatelessWidget {
  const SplitBillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Split Bill App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.createBill: (context) => const CreateBillScreen(),
        AppRoutes.billDetail: (context) => const BillDetailScreen(),
        AppRoutes.profile: (context) => const ProfileScreen(),
      },
    );
  }
}