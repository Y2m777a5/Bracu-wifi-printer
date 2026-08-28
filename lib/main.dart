import 'package:flutter/material.dart';
import 'views/home_page.dart'; // If using multi-tab navigation, import 'views/navigation_screen.dart' instead

void main() {
  runApp(const BracuPrintApp());
}

class BracuPrintApp extends StatelessWidget {
  const BracuPrintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BRACU Wi-Fi Printer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF003366)),
        useMaterial3: true,
      ),
      home: const CampusPrinterHomePage(),
      // If you built navigation_screen.dart from earlier, replace CampusPrinterHomePage() with NavigationScreen()
    );
  }
}
