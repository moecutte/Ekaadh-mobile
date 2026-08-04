import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Path under the XAMPP host (no scheme/host).
  static const _apiPath = '/ekaadh/Ekaadh-backend/public/api/v1';

  /// Override with:
  /// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10/ekaadh/Ekaadh-backend/public/api/v1`
  static const _envBase = String.fromEnvironment('API_BASE_URL');

  /// Optional LAN host for non-web devices when not using dart-define, e.g.
  /// `--dart-define=API_HOST=192.168.100.54`
  static const _envHost = String.fromEnvironment('API_HOST');

  static String get baseUrl {
    if (_envBase.isNotEmpty) return _envBase.replaceAll(RegExp(r'/+$'), '');

    // Flutter web (incl. web-server on 0.0.0.0): use the host the browser opened.
    // Phone opens http://192.168.x.x:8080 → API becomes http://192.168.x.x/...
    if (kIsWeb) {
      return _webBaseUrl();
    }

    if (_envHost.isNotEmpty) {
      return 'http://${_envHost.trim()}$_apiPath';
    }

    // Android emulator → host machine loopback.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2$_apiPath';
    }

    // iOS simulator / desktop on the same machine as XAMPP.
    return 'http://localhost$_apiPath';
  }

  static String _webBaseUrl() {
    final page = Uri.base;
    final host = page.host;
    // Prefer the page host so LAN devices hit this machine’s Apache, not their own localhost.
    if (host.isEmpty || host == 'localhost' || host == '127.0.0.1') {
      // Still on this PC — keep localhost (or API_HOST if set).
      if (_envHost.isNotEmpty) {
        return 'http://${_envHost.trim()}$_apiPath';
      }
      return 'http://localhost$_apiPath';
    }
    final scheme = page.scheme.isNotEmpty ? page.scheme : 'http';
    // Apache serves on :80 — do not reuse Flutter’s :8080.
    return '$scheme://$host$_apiPath';
  }

  /// Laravel `APP_URL` origin (no `/api/v1`) — use for design images & uploads.
  static String get assetOrigin {
    final base = baseUrl;
    const suffix = '/api/v1';
    if (base.endsWith(suffix)) {
      return base.substring(0, base.length - suffix.length);
    }
    return base;
  }
}
