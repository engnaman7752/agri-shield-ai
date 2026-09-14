import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_app/core/theme/app_theme.dart';
import 'package:farmer_app/features/auth/presentation/pages/login_page.dart';
import 'package:farmer_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:farmer_app/features/insurance/presentation/pages/apply_insurance_page.dart';
import 'package:farmer_app/features/profile/presentation/pages/profile_page.dart';
import 'package:farmer_app/core/services/notification_service.dart';
import 'package:farmer_app/l10n/app_localizations.dart';
import 'package:farmer_app/core/providers/locale_provider.dart';
import 'package:farmer_app/features/settings/presentation/pages/language_settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Show detailed error on screen instead of white screen crash
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crash Log'), backgroundColor: Colors.red),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            details.exceptionAsString() + '\n\n' + (details.stack.toString()),
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ),
      ),
    );
  };

  await NotificationService().initialize();
  runApp(const ProviderScope(child: FarmerApp()));
}

class FarmerApp extends ConsumerWidget {
  const FarmerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Farmer Shield',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: currentLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/apply-insurance': (context) => const ApplyInsurancePage(),
        '/profile': (context) => const ProfilePage(),
        '/settings/language': (context) => const LanguageSettingsPage(),
      },
    );
  }
}
