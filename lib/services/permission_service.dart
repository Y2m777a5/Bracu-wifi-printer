import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestWifiPermissions() async {
    if (kIsWeb) return true;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        // Android 13+ uses NEARBY_WIFI_DEVICES
        final status = await Permission.nearbyWifiDevices.request();
        return status.isGranted;
      } else {
        // Older versions use Location
        final status = await Permission.location.request();
        return status.isGranted;
      }
    }
    
    // For iOS, just return true as SSID detection behavior is different
    // (requires Location for network_info_plus)
    if (defaultTargetPlatform == TargetPlatform.iOS) {
       final status = await Permission.locationWhenInUse.request();
       return status.isGranted;
    }

    return true;
  }

  static Future<bool> hasWifiPermissions() async {
    if (kIsWeb) return true;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        return await Permission.nearbyWifiDevices.isGranted;
      } else {
        return await Permission.location.isGranted;
      }
    }
    
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await Permission.locationWhenInUse.isGranted;
    }

    return true;
  }
}
