import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'lib/Home Screen.dart';
import 'lib/l10n/app_localizations.dart';
import 'lib/locale_provider.dart';   // lib/lib/locale_provider.dart
import 'lib/login_screen.dart';
import 'lib/services/api_service.dart';
import 'lib/theme_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

const Color _brand = Color(0xFF13366B);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme  = Provider.of<ThemeProvider>(context);
    final locale = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'joRide',
      themeMode: theme.themeMode,
      locale: locale.locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── Light theme ─────────────────────────────────────────────────────────
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _brand,
          brightness: Brightness.light,
          primary: _brand,
          onPrimary: Colors.white,
          secondary: const Color(0xFF2A5298),
          surface: Colors.white,
          onSurface: Colors.black87,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FD),
        primaryColor: _brand,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F9FD),
          foregroundColor: _brand,
          elevation: 0,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),

      // ── Dark theme ──────────────────────────────────────────────────────────
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _brand,
          brightness: Brightness.dark,
          primary: const Color(0xFF5B8DEF),
          onPrimary: Colors.white,
          secondary: const Color(0xFF7BA7F0),
          surface: const Color(0xFF1E1E2E),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF121220),
        primaryColor: _brand,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E2E),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A3E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E2E),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Color(0xFF1E1E2E),
        ),
      ),

      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: ApiService.getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final token = snapshot.data;
        if (token != null && token.isNotEmpty) return const HomeScreen();
        return const LoginScreen();
      },
    );
  }
}
