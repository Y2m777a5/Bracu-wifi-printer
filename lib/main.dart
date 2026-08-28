import 'package:flutter/material.dart';
import 'views/navigation_screen.dart';

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
      home: const NavigationScreen(),
    );
  }
}
