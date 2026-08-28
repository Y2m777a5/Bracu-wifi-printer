import 'package:flutter/material.dart';
import '../services/settings_service.dart';
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
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final portalUrl = await SettingsService.getPortalUrl();
    final printerIp = await SettingsService.getPrinterIp();
    final lpdPort = await SettingsService.getLpdPort();
    final theme = await SettingsService.getThemeMode();

    setState(() {
      _portalUrlController.text = portalUrl;
      _printerIpController.text = printerIp;
      _lpdPortController.text = lpdPort.toString();
      _selectedTheme = theme;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final port = int.tryParse(_lpdPortController.text) ?? 515;

    await SettingsService.setPortalUrl(_portalUrlController.text.trim());
    await SettingsService.setPrinterIp(_printerIpController.text.trim());
    await SettingsService.setLpdPort(port);
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
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveSettings,
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}
