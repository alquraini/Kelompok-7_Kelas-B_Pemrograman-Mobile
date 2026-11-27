import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/split_bill_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_bill_screen.dart';
import 'screens/bill_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'services/preferences_service.dart';

void main() async {
  // Pastikan binding Flutter siap untuk fungsi async
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization skipped/failed: $e');
  }
  runApp(const SplitBillApp());
}

class SplitBillApp extends StatelessWidget {
  final AppInitialPreferences? initialPreferences;
  const SplitBillApp({super.key, this.initialPreferences});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SplitBillProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Split Bill App',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.login,
        routes: {
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.home: (context) => const HomeScreen(),
          AppRoutes.createBill: (context) => const CreateBillScreen(),
          AppRoutes.billDetail: (context) => const BillDetailScreen(),
          AppRoutes.profile: (context) => const ProfileScreen(),
        },
      ),
    );
  }
}