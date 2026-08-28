import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _keyStudentId = 'student_id';
  static const String _keyPassword = 'student_password';
  static const String _keyAutoLoginEnabled = 'auto_login_enabled';

  static Future<void> saveCredentials(String id, String password) async {
    await _storage.write(key: _keyStudentId, value: id);
    await _storage.write(key: _keyPassword, value: password);
  }

  static Future<String?> getStudentId() async {
    return await _storage.read(key: _keyStudentId);
  }

  static Future<String?> getPassword() async {
    return await _storage.read(key: _keyPassword);
  }

  static Future<void> clearCredentials() async {
    await _storage.delete(key: _keyStudentId);
    await _storage.delete(key: _keyPassword);
  }

  static Future<bool> isAutoLoginEnabled() async {
    final value = await _storage.read(key: _keyAutoLoginEnabled);
    return value == 'true';
  }

  static Future<void> setAutoLoginEnabled(bool enabled) async {
    await _storage.write(key: _keyAutoLoginEnabled, value: enabled.toString());
  }
}
