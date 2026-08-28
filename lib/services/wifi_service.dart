import 'dart:async';
import 'package:http/http.dart' as http;

class WifiService {
  static const String defaultPortalUrl =
      'http://10.10.0.1/eportal/InterFace.do?method=login';

  /// Authenticates student credentials with the campus Ruijie captive portal
  static Future<bool> login({
    required String username,
    required String password,
    String portalUrl = defaultPortalUrl,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(portalUrl),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'userId': username,
              'password': password,
              'queryString': '',
              'service': '',
              'operatorPwd': '',
              'operatorUserId': '',
              'validcode': '',
              'passwordEncrypt': 'false',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = response.body;
        return body.contains('"result":"success"') ||
            body.contains('success') ||
            body.contains('200');
      }
      return false;
    } catch (e) {
      throw Exception('Failed to communicate with Wi-Fi Portal: $e');
    }
  }
}
