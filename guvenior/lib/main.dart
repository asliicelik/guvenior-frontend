import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/services/api_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr', null);
  await ApiService.loadToken();
  runApp(const GuveniorApp());
}

class GuveniorApp extends StatelessWidget {
  const GuveniorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Güvenior',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: ApiService.hasToken ? const DashboardScreen() : const LoginScreen(),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('tr'), Locale('en')],
    );
  }
}
