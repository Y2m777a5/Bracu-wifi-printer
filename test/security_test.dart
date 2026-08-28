import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bracu_wifi_printer/services/secure_storage_service.dart';
import 'package:bracu_wifi_printer/services/history_service.dart';
import 'package:bracu_wifi_printer/services/settings_service.dart';
import 'package:bracu_wifi_printer/models/print_job.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Master Purge Security Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('Full Wipe operation deletes all sensitive data and history', () async {
      // 1. Fill the app with sensitive data
      await SecureStorageService.saveCredentials('20101234', 'super-secret-pass');
      await SecureStorageService.setAutoLoginEnabled(true);
      
      await HistoryService.addJob(PrintJob(
        id: '1',
        fileName: 'confidential.pdf',
        printerIp: '10.10.0.50',
        timestamp: DateTime.now(),
        status: 'Success',
      ));

      await SettingsService.setPrinterIp('99.99.99.99');

      // Verify data exists
      expect(await SecureStorageService.getStudentId(), '20101234');
      expect((await HistoryService.getHistory()).length, 1);
      expect(await SettingsService.getPrinterIp(), '99.99.99.99');

      // 2. Perform the FULL WIPE
      await SecureStorageService.clearCredentials();
      await SecureStorageService.setAutoLoginEnabled(false);
      await HistoryService.clearHistory();
      await SettingsService.resetToDefaults();

      // 3. Verify EVERYTHING is gone
      expect(await SecureStorageService.getStudentId(), isNull);
      expect(await SecureStorageService.getPassword(), isNull);
      expect(await SecureStorageService.isAutoLoginEnabled(), isFalse);
      
      final history = await HistoryService.getHistory();
      expect(history, isEmpty);

      // Verify settings returned to defaults
      expect(await SettingsService.getPrinterIp(), SettingsService.defaultPrinterIp);
    });
  });
}
