import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/secure_storage_service.dart';
import '../services/history_service.dart';
import '../services/auth_bridge.dart';
import '../main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _portalUrlController = TextEditingController();
  final _printerIpController = TextEditingController();
  final _lpdPortController = TextEditingController();
  final _lpdQueueController = TextEditingController();
  String _selectedTheme = 'system';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _portalUrlController.dispose();
    _printerIpController.dispose();
    _lpdPortController.dispose();
    _lpdQueueController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final portalUrl = await SettingsService.getPortalUrl();
    final printerIp = await SettingsService.getPrinterIp();
    final lpdPort = await SettingsService.getLpdPort();
    final lpdQueue = await SettingsService.getLpdQueue();
    final theme = await SettingsService.getThemeMode();

    setState(() {
      _portalUrlController.text = portalUrl;
      _printerIpController.text = printerIp;
      _lpdPortController.text = lpdPort.toString();
      _lpdQueueController.text = lpdQueue;
      _selectedTheme = theme;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final port = int.tryParse(_lpdPortController.text) ?? 515;

    await SettingsService.setPortalUrl(_portalUrlController.text.trim());
    await SettingsService.setPrinterIp(_printerIpController.text.trim());
    await SettingsService.setLpdPort(port);
    await SettingsService.setLpdQueue(_lpdQueueController.text.trim());
    await SettingsService.setThemeMode(_selectedTheme);

    if (mounted) {
      // Update app theme immediately
      final themeMode = _parseThemeMode(_selectedTheme);
      BracuPrintApp.of(context)?.setThemeMode(themeMode);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    }
  }

  Future<void> _handleFullWipe() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wipe All Data?'),
        content: const Text('This will delete your saved credentials, print history, and network settings. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('WIPE EVERYTHING'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show blocking progress dialog during wipe
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Securing data cleanup...'),
            ],
          ),
        ),
      ),
    );

    try {
      // 1. Wipe Services (Wait for completion)
      await Future.delayed(const Duration(seconds: 1)); // Give user time to see the status
      await SecureStorageService.clearCredentials();
      await SecureStorageService.setAutoLoginEnabled(false);
      await HistoryService.clearHistory();
      await SettingsService.resetToDefaults();

      // 2. Wipe UI via Bridge
      await AuthUiBridge.clearSessionUi();

      // 3. Reset Local State
      await _loadSettings();

      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data has been securely wiped.')),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('Display Theme', style: TextStyle(fontWeight: FontWeight.bold)),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'system', label: Text('System'), icon: Icon(Icons.settings_brightness)),
              ButtonSegment(value: 'light', label: Text('Light'), icon: Icon(Icons.light_mode)),
              ButtonSegment(value: 'dark', label: Text('Dark'), icon: Icon(Icons.dark_mode)),
            ],
            selected: {_selectedTheme},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _selectedTheme = newSelection.first;
              });
              _saveSettings();
            },
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          const Text('Network Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _portalUrlController,
            decoration: const InputDecoration(
              labelText: 'Wi-Fi Portal URL',
              helperText: 'Default Ruijie login URL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _printerIpController,
            decoration: const InputDecoration(
              labelText: 'Default Printer IP',
              helperText: 'LPD Server address',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _lpdPortController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'LPD Port',
              helperText: 'Default is 515',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _lpdQueueController,
            decoration: const InputDecoration(
              labelText: 'LPD Queue Name',
              helperText: 'Try "secure" or "raw"',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveSettings,
            child: const Text('Save Settings'),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 8),
          const Text('Security & Privacy', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _handleFullWipe,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Log Out & Wipe All Data'),
          ),
          const SizedBox(height: 12),
          const Text(
            'This securely deletes your encrypted Student ID, password, print history, and resets all network configurations.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
