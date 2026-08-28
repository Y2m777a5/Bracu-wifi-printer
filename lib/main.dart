import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'services/lpd_printer_service.dart';
import 'services/wifi_service.dart';

void main() {
  runApp(const BracuPrintApp());
}

class BracuPrintApp extends StatelessWidget {
  const BracuPrintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BRACU Wi-Fi Printer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF003366)),
        useMaterial3: true,
      ),
      home: const CampusPrinterHomePage(),
    );
  }
}

class CampusPrinterHomePage extends StatefulWidget {
  const CampusPrinterHomePage({super.key});

  @override
  State<CampusPrinterHomePage> createState() => _CampusPrinterHomePageState();
}

class _CampusPrinterHomePageState extends State<CampusPrinterHomePage> {
  // Authentication State
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isWifiConnected = false;
  bool _isConnectingWifi = false;

  // Print Queue State
  final _printerIpController = TextEditingController(text: '10.10.0.50');
  PlatformFile? _selectedFile;
  bool _isSendingPrint = false;

  Future<void> _handleWifiLogin() async {
    if (_studentIdController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage('Please enter Student ID and Password');
      return;
    }

    setState(() => _isConnectingWifi = true);

    try {
      final success = await WifiService.login(
        username: _studentIdController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (success) {
        setState(() => _isWifiConnected = true);
        _showMessage('Successfully connected to Campus Wi-Fi!');
      } else {
        _showMessage('Login failed. Verify credentials or Wi-Fi coverage.');
      }
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      setState(() => _isConnectingWifi = false);
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'ps'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  Future<void> _handlePrintSubmission() async {
    if (_selectedFile == null || _selectedFile!.bytes == null) {
      _showMessage('Please select a valid PDF/Document to print');
      return;
    }

    setState(() => _isSendingPrint = true);

    try {
      final lpdClient = LpdPrinterService(
        printerIp: _printerIpController.text.trim(),
      );

      await lpdClient.sendPrintJob(
        fileBytes: _selectedFile!.bytes!,
        fileName: _selectedFile!.name,
        username: _studentIdController.text.trim().isNotEmpty
            ? _studentIdController.text.trim()
            : 'student',
      );

      _showMessage('Print job queued successfully on campus printer!');
    } catch (e) {
      _showMessage('Print submission failed: $e');
    } finally {
      setState(() => _isSendingPrint = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BRACU Wi-Fi Printer Client'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // STEP 1: Wi-Fi Login Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isWifiConnected
                              ? Icons.wifi_sharp
                              : Icons.wifi_lock_rounded,
                          color: _isWifiConnected ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Step 1: Campus Wi-Fi Authentication',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),
                    TextField(
                      controller: _studentIdController,
                      decoration:
                          const InputDecoration(labelText: 'Student ID / User'),
                    ),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isConnectingWifi ? null : _handleWifiLogin,
                      icon: _isConnectingWifi
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: Text(_isWifiConnected ? 'Re-authenticate' : 'Connect Wi-Fi'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // STEP 2: Print Queue Submission Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.print_rounded, color: Color(0xFF003366)),
                        SizedBox(width: 8),
                        Text(
                          'Step 2: Submit Document to Printer',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),
                    TextField(
                      controller: _printerIpController,
                      decoration: const InputDecoration(
                        labelText: 'Print Queue IP (LPD Server)',
                        hintText: '10.10.0.50',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickDocument,
                      icon: const Icon(Icons.attach_file),
                      label: Text(_selectedFile != null
                          ? 'Selected: ${_selectedFile!.name}'
                          : 'Select PDF Document'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: (_isSendingPrint)
                          ? null
                          : _handlePrintSubmission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366),
                        foregroundColor: Colors.white,
                      ),
                      icon: _isSendingPrint
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      label: const Text('Send to Campus Printer Queue'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
