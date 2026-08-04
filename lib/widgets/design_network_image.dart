import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/media_url.dart';

class DesignNetworkImage extends StatelessWidget {
  const DesignNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.fallbackColor = const Color(0xFFF1F5F9),
  });

  final String? url;
  final BoxFit fit;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final resolved = MediaUrl.resolve(url);
    if (resolved == null || resolved.isEmpty) {
      return ColoredBox(color: fallbackColor);
    }

    return Image.network(
      resolved,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ColoredBox(
          color: fallbackColor,
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => ColoredBox(
        color: fallbackColor,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8), size: 28),
        ),
      ),
    );
  }
}
