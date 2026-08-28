import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyPortalUrl = 'portal_url';
  static const String _keyPrinterIp = 'printer_ip';
  static const String _keyLpdPort = 'lpd_port';

  static const String defaultPortalUrl = 'http://10.10.0.1/eportal/InterFace.do?method=login';
  static const String defaultPrinterIp = '10.10.0.50';
  static const int defaultLpdPort = 515;

  static Future<String> getPortalUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPortalUrl) ?? defaultPortalUrl;
  }

  static Future<void> setPortalUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPortalUrl, value);
  }

  static Future<String> getPrinterIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPrinterIp) ?? defaultPrinterIp;
  }

  static Future<void> setPrinterIp(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPrinterIp, value);
  }

  static Future<int> getLpdPort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyLpdPort) ?? defaultLpdPort;
  }

  static Future<void> setLpdPort(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLpdPort, value);
  }
}
