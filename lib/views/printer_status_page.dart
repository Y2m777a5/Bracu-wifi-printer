import 'dart:io';
import 'package:flutter/material.dart';

class PrinterStatusPage extends StatefulWidget {
  const PrinterStatusPage({super.key});

  @override
  State<PrinterStatusPage> createState() => _PrinterStatusPageState();
}

class _PrinterStatusPageState extends State<PrinterStatusPage> {
  final TextEditingController _ipController =
      TextEditingController(text: '10.10.0.50');
  bool _isChecking = false;
  String _statusMessage = 'Unknown';
  bool? _isOnline;

  Future<void> _checkPrinterStatus() async {
    setState(() {
      _isChecking = true;
      _statusMessage = 'Pinging printer at ${_ipController.text}:515...';
    });

    try {
      final socket = await Socket.connect(
        _ipController.text.trim(),
        515,
        timeout: const Duration(seconds: 4),
      );
      await socket.close();

      setState(() {
        _isOnline = true;
        _statusMessage = 'Printer is ONLINE and accepting LPD requests.';
      });
    } catch (e) {
      setState(() {
        _isOnline = false;
        _statusMessage =
            'Printer unreachable. Ensure you are connected to Campus Wi-Fi.';
      });
    } finally {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Printer Network Status')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        labelText: 'Target Printer IP',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isChecking ? null : _checkPrinterStatus,
                      icon: _isChecking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: const Text('Check LPD Socket (Port 515)'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isOnline != null)
              Card(
                color: _isOnline! ? Colors.green.shade50 : Colors.red.shade50,
                child: ListTile(
                  leading: Icon(
                    _isOnline! ? Icons.check_circle : Icons.error,
                    color: _isOnline! ? Colors.green : Colors.red,
                  ),
                  title: Text(
                    _isOnline! ? 'Online' : 'Offline / Unreachable',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isOnline! ? Colors.green.shade900 : Colors.red.shade900,
                    ),
                  ),
                  subtitle: Text(_statusMessage),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
