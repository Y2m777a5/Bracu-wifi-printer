import 'dart:io';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const WifiPrinterApp());
}

class WifiPrinterApp extends StatelessWidget {
  const WifiPrinterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BRACU Wi-Fi Printer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF003366)),
        useMaterial3: true,
      ),
      home: const PrinterScreen(),
    );
  }
}

class PrinterScreen extends StatefulWidget {
  const PrinterScreen({super.key});

  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  final NetworkInfo _networkInfo = NetworkInfo();
  String _wifiName = 'Unknown';
  String _wifiIP = 'Unknown';
  File? _selectedFile;
  bool _isUploading = false;
  String _statusMessage = '';

  // Configuration for campus network & printer endpoint
  static const String _requiredSSID = 'BRACU-STUDENT'; // Adjust to exact SSID
  static const String _printServerUrl = 'http://10.0.0.50:8080/api/print'; // Adjust printer IP/Port

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndNetwork();
  }

  Future<void> _checkPermissionsAndNetwork() async {
    await [Permission.location].request();
    
    String? ssid = await _networkInfo.getWifiName();
    String? ip = await _networkInfo.getWifiIP();

    setState(() {
      _wifiName = ssid?.replaceAll('"', '') ?? 'Not Connected';
      _wifiIP = ip ?? '0.0.0.0';
    });
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {

      setState(() {
        _selectedFile = File(result.files.single.path!);
        _statusMessage = 'File loaded: ${result.files.single.name}';
      });
    }
  }

  Future<void> _sendPrintJob() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file first.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _statusMessage = 'Submitting job to printer queue...';
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse(_printServerUrl));
      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedFile!.path),
      );
      request.fields['student_id'] = 'YOUR_STUDENT_ID';

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = 'Print request successfully queued!';
        });
      } else {
        setState(() {
          _statusMessage = 'Failed to queue print job. Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error connecting to printer server: $e';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isConnectedToCampusWifi = _wifiName == _requiredSSID || _wifiName != 'Not Connected';

    return Scaffold(
      appBar: AppBar(
        title: const Text('BRACU Campus Printer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Network Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('SSID: $_wifiName'),
                    Text('IP Address: $_wifiIP'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          isConnectedToCampusWifi ? Icons.check_circle : Icons.warning,
                          color: isConnectedToCampusWifi ? Colors.green : Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isConnectedToCampusWifi
                                ? 'Connected to campus network.'
                                : 'Connect to campus Wi-Fi to send print requests.',
                            style: TextStyle(
                              color: isConnectedToCampusWifi ? Colors.green : Colors.amber[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: const Text('Select Document (PDF/DOCX)'),
            ),
            if (_selectedFile != null) ...[
              const SizedBox(height: 12),
              Text('Selected: ${_selectedFile!.path.split('/').last}'),
            ],
            const Spacer(),
            if (_statusMessage.isNotEmpty)
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: (_isUploading || !isConnectedToCampusWifi) ? null : _sendPrintJob,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit to Print Queue', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
