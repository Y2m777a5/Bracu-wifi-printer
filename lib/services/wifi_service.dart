import 'dart:async';
import 'package:http/http.dart' as http;

class WifiService {
  static const String defaultPortalUrl =
      'http://10.10.0.1/eportal/InterFace.do?method=login';
  
  static const String connectivityProbeUrl = 
      'http://connectivitycheck.gstatic.com/generate_204';

  /// Checks if the internet is actually accessible
  static Future<bool> isConnectedToInternet() async {
    try {
      final response = await http
          .get(Uri.parse(connectivityProbeUrl))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  /// Attempts to find the actual login portal URL by following redirects
  static Future<String> _resolvePortalUrl() async {
    try {
      // We use a probe URL that we know will be intercepted by a captive portal
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(connectivityProbeUrl))
        ..followRedirects = false;
      
      final response = await client.send(request).timeout(const Duration(seconds: 5));
      
      if (response.statusCode >= 300 && response.statusCode < 400) {
        final location = response.headers['location'];
        if (location != null) return location;
      }
      
      // If no redirect, maybe we are already connected or it's a non-standard portal
      return defaultPortalUrl;
    } catch (_) {
      return defaultPortalUrl;
    }
  }

  /// Authenticates student credentials with the campus Ruijie captive portal
  static Future<bool> login({
    required String username,
    required String password,
    String? portalUrl,
  }) async {
    try {
      // If portalUrl is not provided, try to resolve it automatically
      final targetUrl = portalUrl ?? await _resolvePortalUrl();
      
      final uri = Uri.parse(targetUrl);
      
      // Ruijie portals often require the query parameters from the redirect URL
      // to be present in the POST body or just keep them in the URI.
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            },
            body: {
              'userId': username,
              'password': password,
              'queryString': uri.query,
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
        // Check for success markers in the response body
        final isSuccess = body.contains('"result":"success"') ||
            body.contains('success') ||
            body.contains('200') ||
            await isConnectedToInternet();
            
        return isSuccess;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to communicate with Wi-Fi Portal: $e');
    }
  }
}
