import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/core/locale_service.dart';
import 'package:ekaadh_mobile/core/locale_scope.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/screens/splash_screen.dart';
import 'package:ekaadh_mobile/screens/onboarding_screen.dart';
import 'package:ekaadh_mobile/screens/home_shell.dart';
import 'package:ekaadh_mobile/screens/staff_login_screen.dart';
import 'package:ekaadh_mobile/services/push_notification_service.dart';

const _onboardingKey = 'onboarding_complete';

/// Light status bar matching the app's white/gray chrome.
const _lightSystemUi = SystemUiOverlayStyle(
  statusBarColor: Colors.white,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: Colors.white,
  systemNavigationBarIconBrightness: Brightness.dark,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(_lightSystemUi);
  await PushNotificationService.init();
  runApp(const EkaadhApp());
}

class EkaadhApp extends StatefulWidget {
  const EkaadhApp({super.key});

  @override
  State<EkaadhApp> createState() => _EkaadhAppState();
}

class _EkaadhAppState extends State<EkaadhApp> {
  final AuthService _auth = AuthService();
  final LocaleService _locale = LocaleService();
  bool _booting = true;
  bool _signedIn = false;
  bool _onboardingDone = false;

  bool get _isStaff {
    final role = _auth.user?.role;
    return role == 'staff' || role == 'admin';
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final started = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    _onboardingDone = prefs.getBool(_onboardingKey) ?? false;

    await _locale.init();
    await _auth.init();
    if (_auth.token != null) {
      final ok = await _auth.fetchMe();
      _signedIn = ok;
      if (ok && (_auth.user?.pushNotificationsEnabled ?? true)) {
        await PushNotificationService.syncToken(_auth);
      }
    }

    // Match design reference splash duration (~2.2s).
    final elapsed = DateTime.now().difference(started);
    const minSplash = Duration(milliseconds: 2200);
    if (elapsed < minSplash) {
      await Future<void>.delayed(minSplash - elapsed);
    }

    if (mounted) {
      setState(() => _booting = false);
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    if (mounted) {
      setState(() => _onboardingDone = true);
    }
  }

  void _onSignedIn() {
    setState(() => _signedIn = true);
    if (_auth.user?.pushNotificationsEnabled ?? true) {
      PushNotificationService.syncToken(_auth);
    }
  }

  Future<void> _onSignOut() async {
    await PushNotificationService.clearToken(_auth);
    await _auth.logout();
    if (mounted) {
      setState(() => _signedIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Built outside ListenableBuilder so locale toggles don't remount screens.
    final Widget home;
    if (_booting) {
      home = const SplashScreen();
    } else if (!_onboardingDone) {
      home = OnboardingScreen(onComplete: _completeOnboarding);
    } else if (_signedIn && _isStaff) {
      home = StaffHome(auth: _auth, onSignOut: _onSignOut);
    } else {
      home = HomeShell(
        auth: _auth,
        onSignedIn: _onSignedIn,
        onSignOut: _onSignOut,
      );
    }

    return LocaleScope(
      service: _locale,
      child: ListenableBuilder(
        listenable: _locale,
        builder: (context, _) {
          return MaterialApp(
            title: 'Ekaadh',
            debugShowCheckedModeBanner: false,
            locale: Locale(_locale.code),
            theme: ThemeData(
              useMaterial3: true,
              // SF Pro on iOS; Roboto on Android and Chrome.
              typography: Typography.material2021(
                platform: kIsWeb
                    ? TargetPlatform.android
                    : defaultTargetPlatform,
              ),
              colorScheme: ColorScheme.fromSeed(
                seedColor: EkaadhColors.brand,
                primary: EkaadhColors.brand,
                surface: EkaadhColors.surface,
              ),
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: EkaadhColors.dark,
                elevation: 0,
                systemOverlayStyle: _lightSystemUi,
              ),
              inputDecorationTheme: InputDecorationTheme(
                hintStyle: EkaadhTextStyles.fieldHint,
                filled: true,
                fillColor: EkaadhColors.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: EkaadhColors.fieldBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: EkaadhColors.brand, width: 1.5),
                ),
              ),
              snackBarTheme: SnackBarThemeData(
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.white,
                contentTextStyle: const TextStyle(
                  color: EkaadhColors.dark,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 8,
              ),
            ),
            home: home,
          );
        },
      ),
    );
  }
}
