import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Production API (default for run/build when no override is passed).
  static const _productionApi = 'https://ekaadh.com/api/v1';

  /// Path under a shared XAMPP/Apache host (no scheme/host).
  static const _apiPath = '/Ekaadh-backend/public/api/v1';

  /// Override production with:
  /// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1`
  static const _envBase = String.fromEnvironment('API_BASE_URL');

  /// Optional LAN host for phones / LAN web when not using dart-define, e.g.
  /// `--dart-define=API_HOST=192.168.100.54`
  /// Uses Apache path on that host (port 80). For artisan on LAN use API_BASE_URL.
  static const _envHost = String.fromEnvironment('API_HOST');

  static String get baseUrl {
    if (_envBase.isNotEmpty) return _envBase.replaceAll(RegExp(r'/+$'), '');

    if (_envHost.isNotEmpty) {
      return 'http://${_envHost.trim()}$_apiPath';
    }

    // Default: production.
    // Local/LAN: pass API_BASE_URL or API_HOST (see above).
    if (kIsWeb) {
      return _webBaseUrl();
    }

    return _productionApi;
  }

  /// Local `php artisan serve` (bound to IPv4). Prefer 127.0.0.1 over localhost
  /// so Windows does not try IPv6 (::1) and miss the listener.
  static const _localArtisanApi = 'http://127.0.0.1:8000/api/v1';

  static String _webBaseUrl() {
    final page = Uri.base;
    final host = page.host;
    // Chrome / localhost on this PC → local Laravel, not production.
    // Production CORS does not allow the Flutter web debug origin, which the
    // app previously showed as “no internet”.
    if (host.isEmpty || host == 'localhost' || host == '127.0.0.1') {
      return _localArtisanApi;
    }
    // If the Flutter web app is hosted on the same domain as the API (or LAN),
    // prefer that host’s Apache API path for non-production hosts.
    if (host == 'ekaadh.com' || host == 'www.ekaadh.com') {
      return _productionApi;
    }
    final scheme = page.scheme.isNotEmpty ? page.scheme : 'http';
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
