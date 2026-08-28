import 'dart:async';

typedef ClearUiArtifacts = Future<void> Function();

class AuthUiBridge {
  AuthUiBridge._();

  static ClearUiArtifacts? _clearHomeUi;

  static void configure({
    required ClearUiArtifacts clearHomeUi,
  }) {
    _clearHomeUi = clearHomeUi;
  }

  /// Triggers the UI cleanup across registered pages
  static Future<void> clearSessionUi() async {
    await _clearHomeUi?.call();
  }
}
