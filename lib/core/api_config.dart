import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Local Laravel (`php artisan serve`) API root.
  static const _localApi = 'http://127.0.0.1:8000/api/v1';

  /// Path under a shared XAMPP/Apache host (no scheme/host).
  static const _apiPath = '/Ekaadh-backend/public/api/v1';

  /// Override with:
  /// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1`
  static const _envBase = String.fromEnvironment('API_BASE_URL');

  /// Optional LAN host for phones / LAN web when not using dart-define, e.g.
  /// `--dart-define=API_HOST=192.168.100.54`
  /// Uses Apache path on that host (port 80). For artisan on LAN use API_BASE_URL.
  static const _envHost = String.fromEnvironment('API_HOST');

  static String get baseUrl {
    if (_envBase.isNotEmpty) return _envBase.replaceAll(RegExp(r'/+$'), '');

    // Flutter web (incl. web-server on 0.0.0.0): use the host the browser opened.
    if (kIsWeb) {
      return _webBaseUrl();
    }

    if (_envHost.isNotEmpty) {
      return 'http://${_envHost.trim()}$_apiPath';
    }

    // Android emulator → host machine loopback (artisan serve).
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }

    // iOS simulator / desktop on the same machine as artisan serve.
    return _localApi;
  }

  static String _webBaseUrl() {
    final page = Uri.base;
    final host = page.host;
    // Chrome / localhost on this PC → artisan serve.
    if (host.isEmpty || host == 'localhost' || host == '127.0.0.1') {
      if (_envHost.isNotEmpty) {
        return 'http://${_envHost.trim()}$_apiPath';
      }
      return _localApi;
    }
    final scheme = page.scheme.isNotEmpty ? page.scheme : 'http';
    // Phone/LAN: hit this machine’s Apache on :80 — do not reuse Flutter’s :8080.
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

  /// Public website origin for shareable event links.
  /// Falls back to production when the API host is local/LAN.
  static String get webOrigin {
    final origin = assetOrigin;
    final uri = Uri.tryParse(origin);
    if (uri == null || uri.host.isEmpty) {
      return 'https://ekaadh.com';
    }
    final host = uri.host;
    final isLocal = host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '10.0.2.2' ||
        host.startsWith('192.168.') ||
        host.startsWith('10.') ||
        origin.contains('Ekaadh-backend');
    if (isLocal) return 'https://ekaadh.com';

    final port = (uri.hasPort && uri.port != 80 && uri.port != 443)
        ? ':${uri.port}'
        : '';
    return '${uri.scheme}://$host$port';
  }

  static String eventShareUrl(String slug) => '$webOrigin/events/$slug';
}
