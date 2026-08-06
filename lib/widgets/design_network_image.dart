import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/media_url.dart';

/// Network image that works on Flutter web (uses an HTML img element to avoid
/// CORS failures when Laravel serves static files without Access-Control headers).
class DesignNetworkImage extends StatelessWidget {
  const DesignNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.fallbackColor = const Color(0xFFF1F5F9),
    this.width,
    this.height,
  });

  final String? url;
  final BoxFit fit;
  final Color fallbackColor;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final resolved = MediaUrl.resolve(url);
    if (resolved == null || resolved.isEmpty) {
      return ColoredBox(
        color: fallbackColor,
        child: SizedBox(width: width, height: height),
      );
    }

    return Image.network(
      resolved,
      width: width,
      height: height,
      fit: fit,
      // Chrome/web: HTML img can display cross-origin images without CORS.
      // Default canvas decode requires Access-Control-Allow-Origin.
      webHtmlElementStrategy:
          kIsWeb ? WebHtmlElementStrategy.prefer : WebHtmlElementStrategy.never,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ColoredBox(
          color: fallbackColor,
          child: SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => ColoredBox(
        color: fallbackColor,
        child: SizedBox(
          width: width,
          height: height,
          child: const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Color(0xFF94A3B8),
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
