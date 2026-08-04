import 'package:ekaadh_mobile/core/api_config.dart';

/// Rewrites Laravel `asset()` URLs (often `localhost`) to the host the app uses for API calls.
class MediaUrl {
  static String? resolve(String? url) {
    if (url == null || url.trim().isEmpty) return null;

    final trimmed = url.trim();
    if (trimmed.startsWith('/')) {
      return '${ApiConfig.assetOrigin}$trimmed';
    }

    final parsed = Uri.tryParse(trimmed);
    if (parsed == null || !parsed.hasScheme) return trimmed;

    final host = parsed.host.toLowerCase();
    if (host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2') {
      final api = Uri.parse(ApiConfig.assetOrigin);
      final port = api.hasPort && api.port != 80 && api.port != 443 ? ':${api.port}' : '';
      final origin = '${api.scheme}://${api.host}$port';
      return '$origin${parsed.path}${parsed.hasQuery ? '?${parsed.query}' : ''}';
    }

    return trimmed;
  }
}
