import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;

/// Loads design fonts (Fontsource TTFs) for PDF text that matches web overlays.
class InvitationPdfFonts {
  InvitationPdfFonts._();

  static const catalog = <String, String>{
    'Great Vibes': 'great-vibes',
    'Dancing Script': 'dancing-script',
    'Sacramento': 'sacramento',
    'Pinyon Script': 'pinyon-script',
    'Allura': 'allura',
    'Alex Brush': 'alex-brush',
    'Italianno': 'italianno',
    'Parisienne': 'parisienne',
    'Satisfy': 'satisfy',
    'Tangerine': 'tangerine',
    'Rouge Script': 'rouge-script',
    'Mr De Haviland': 'mr-de-haviland',
    'Playfair Display': 'playfair-display',
    'Cormorant Garamond': 'cormorant-garamond',
    'Cinzel': 'cinzel',
    'Lora': 'lora',
    'EB Garamond': 'eb-garamond',
    'Libre Baskerville': 'libre-baskerville',
    'Merriweather': 'merriweather',
    'Amiri': 'amiri',
    'Montserrat': 'montserrat',
    'Poppins': 'poppins',
    'Source Sans 3': 'source-sans-3',
    'Raleway': 'raleway',
    'Josefin Sans': 'josefin-sans',
    'Quicksand': 'quicksand',
  };

  static final Map<String, pw.Font> _cache = {};

  static Future<pw.Font?> load(
    String? family, {
    int weight = 400,
    bool italic = false,
  }) async {
    final name = family?.trim() ?? '';
    final id = catalog[name];
    if (id == null) return null;

    final w = weight >= 700 ? 700 : (weight >= 600 ? 600 : 400);
    final style = italic ? 'italic' : 'normal';
    final key = '$id-$w-$style';
    final cached = _cache[key];
    if (cached != null) return cached;

    final urls = <String>[
      'https://cdn.jsdelivr.net/fontsource/fonts/$id@latest/latin-$w-$style.ttf',
      if (w != 400 || italic)
        'https://cdn.jsdelivr.net/fontsource/fonts/$id@latest/latin-400-normal.ttf',
    ];

    for (final url in urls) {
      try {
        final response =
            await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
        if (response.statusCode != 200 || response.bodyBytes.length < 1000) {
          continue;
        }
        final font = pw.Font.ttf(ByteData.sublistView(response.bodyBytes));
        _cache[key] = font;
        return font;
      } catch (_) {
        continue;
      }
    }

    return null;
  }
}
