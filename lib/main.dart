import 'package:flutter/material.dart';
import 'views/navigation_screen.dart';
import 'services/settings_service.dart';

void main() {
  runApp(const BracuPrintApp());
}

class BracuPrintApp extends StatefulWidget {
  const BracuPrintApp({super.key});

  static BracuPrintAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<BracuPrintAppState>();

  @override
  State<BracuPrintApp> createState() => BracuPrintAppState();
}

class BracuPrintAppState extends State<BracuPrintApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final mode = await SettingsService.getThemeMode();
    setState(() {
      _themeMode = _parseThemeMode(mode);
    });
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    const bracuBlue = Color(0xFF003366);
    
    return MaterialApp(
      title: 'BRACU Wi-Fi Printer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: bracuBlue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: bracuBlue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: const NavigationScreen(),
    );
  }
}
