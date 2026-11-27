import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/split_bill_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_bill_screen.dart';
import 'screens/bill_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'services/preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final initialPrefs = await PreferencesService.instance.loadInitialPreferences();

  runApp(
    SplitBillApp(initialPreferences: initialPrefs),
  );
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
      ),
    );
  }
}