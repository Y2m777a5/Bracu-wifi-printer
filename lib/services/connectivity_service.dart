import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'wifi_service.dart';
import 'secure_storage_service.dart';
import 'permission_service.dart';

class ConnectivityService {
  final _connectivity = Connectivity();
  final _networkInfo = NetworkInfo();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  void startMonitoring(Function(String) onStatusChange) {
    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      if (results.contains(ConnectivityResult.wifi)) {
        await _handleWifiConnected(onStatusChange);
      }
    });
  }

  void stopMonitoring() {
    _subscription?.cancel();
  }

  Future<void> _handleWifiConnected(Function(String) onStatusChange) async {
    final isAutoLogin = await SecureStorageService.isAutoLoginEnabled();
    if (!isAutoLogin) return;

    final hasPermission = await PermissionService.hasWifiPermissions();
    if (!hasPermission) {
      onStatusChange('Auto-login failed: WiFi permissions missing.');
      return;
    }

    try {
      final wifiName = await _networkInfo.getWifiName();
      // Note: wifiName might be quoted like "BRACU-WiFi"
      final ssid = wifiName?.replaceAll('"', '') ?? '';

      // Target SSIDs - common campus patterns
      if (ssid.contains('BRACU')) {
        onStatusChange('Campus Wi-Fi detected ($ssid). Attempting auto-login...');
        
        final id = await SecureStorageService.getStudentId();
        final password = await SecureStorageService.getPassword();

        if (id != null && password != null) {
          final success = await WifiService.login(username: id, password: password);
          if (success) {
            onStatusChange('Auto-login successful!');
          } else {
            onStatusChange('Auto-login failed. Please check credentials.');
          }
        } else {
          onStatusChange('Auto-login skipped: No credentials saved.');
        }
      }
    } catch (e) {
      onStatusChange('Error during auto-login: $e');
    }
  }
}
