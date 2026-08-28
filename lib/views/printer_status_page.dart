import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/snmp_service.dart';

class PrinterStatusPage extends StatefulWidget {
  const PrinterStatusPage({super.key});

  @override
  State<PrinterStatusPage> createState() => _PrinterStatusPageState();
}

class _PrinterStatusPageState extends State<PrinterStatusPage> with SingleTickerProviderStateMixin {
  final TextEditingController _ipController =
      TextEditingController(text: SettingsService.defaultPrinterIp);
  
  bool _isChecking = false;
  
  // Basic reachability status
  final Map<String, bool?> _onlineStatus = {
    SettingsService.defaultPrinterIp: null,
    SettingsService.fallbackPrinterIp: null,
  };

  // Detailed SNMP diagnostics
  final Map<String, SnmpPrinterStatus?> _printerDetails = {
    SettingsService.defaultPrinterIp: null,
    SettingsService.fallbackPrinterIp: null,
  };

  Timer? _liveTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _startLiveMonitoring();
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _pulseController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  void _startLiveMonitoring() {
    _liveTimer?.cancel();
    _checkAllPrinters();
    _liveTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _checkAllPrinters();
    });
  }

  Future<void> _checkAllPrinters() async {
    final ips = _onlineStatus.keys.toList();
    for (final ip in ips) {
      _refreshPrinterStatus(ip);
    }
  }

  Future<void> _refreshPrinterStatus(String ip) async {
    // 1. Basic LPD Probe (TCP 515)
    bool isOnline = false;
    try {
      final socket = await Socket.connect(ip, 515, timeout: const Duration(seconds: 2));
      await socket.close();
      isOnline = true;
    } catch (_) {
      isOnline = false;
    }

    // 2. Detailed SNMP Probe (UDP 161)
    SnmpPrinterStatus? details;
    if (isOnline) {
      details = await SnmpClient.queryPrinterStatus(ip);
    }

    if (mounted) {
      setState(() {
        _onlineStatus[ip] = isOnline;
        _printerDetails[ip] = details;
      });
    }
  }

  Future<void> _manualCheck() async {
    final customIp = _ipController.text.trim();
    if (customIp.isEmpty) return;

    setState(() => _isChecking = true);
    await _refreshPrinterStatus(customIp);
    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Printer Dashboard'),
        actions: [
          if (_isChecking)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Hardware Diagnostics (SNMP)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          
          _buildStatusCard(SettingsService.defaultPrinterIp, 'Primary Queue'),
          const SizedBox(height: 12),
          _buildStatusCard(SettingsService.fallbackPrinterIp, 'Lab Queue (Alternate)'),
          
          const Divider(height: 40),
          
          const Text(
            'Manual Diagnostic Probe',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Printer IP',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isChecking ? null : _manualCheck,
                    icon: const Icon(Icons.radar),
                    label: const Text('Probe Hardware Status'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String ip, String label) {
    final bool? isOnline = _onlineStatus[ip];
    final details = _printerDetails[ip];
    
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: FadeTransition(
              opacity: _pulseController,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline == null
                      ? Colors.grey
                      : (isOnline ? Colors.green : Colors.red),
                  boxShadow: isOnline == true
                      ? [BoxShadow(color: Colors.green.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)]
                      : null,
                ),
              ),
            ),
            title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(ip),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isOnline == null ? 'SCANNING' : (isOnline ? 'READY' : 'OFFLINE'),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: isOnline == true ? Colors.green : (isOnline == false ? Colors.red : Colors.grey),
                  ),
                ),
                if (details != null)
                  Text(
                    details.printerStatusLabel.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
              ],
            ),
          ),
          if (details != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (details.description != null)
                    Text(
                      details.description!,
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (details.hasErrors) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: details.errorFlags.map((err) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
                            const SizedBox(width: 4),
                            Text(
                              err.toUpperCase(),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ] else if (isOnline == true) ...[
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text('Hardware check passed', style: TextStyle(fontSize: 11, color: Colors.green)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
