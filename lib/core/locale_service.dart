import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ekaadh_mobile/l10n/app_strings.dart';

const _localeKey = 'app_locale';

/// Persists and broadcasts the active app language (`en` / `so`).
class LocaleService extends ChangeNotifier {
  String _code = 'en';

  String get code => _code;

  bool get isSomali => _code == 'so';

  String t(String key) => AppStrings.t(_code, key);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_localeKey);
    if (saved != null && AppStrings.supported.contains(saved)) {
      _code = saved;
    }
  }

  Future<void> setLocale(String code) async {
    if (!AppStrings.supported.contains(code) || code == _code) return;
    _code = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, code);
    notifyListeners();
  }

  Future<void> toggle() => setLocale(_code == 'en' ? 'so' : 'en');
}
