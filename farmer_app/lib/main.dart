import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_app/core/theme/app_theme.dart';
import 'package:farmer_app/features/auth/presentation/pages/login_page.dart';
import 'package:farmer_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:farmer_app/features/insurance/presentation/pages/apply_insurance_page.dart';
import 'package:farmer_app/features/profile/presentation/pages/profile_page.dart';
import 'package:farmer_app/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  runApp(const ProviderScope(child: FarmerApp()));
}

class FarmerApp extends StatelessWidget {
  const FarmerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farmer Shield',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/apply-insurance': (context) => const ApplyInsurancePage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
