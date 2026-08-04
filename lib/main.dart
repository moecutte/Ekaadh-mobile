import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/screens/splash_screen.dart';
import 'package:ekaadh_mobile/screens/onboarding_screen.dart';
import 'package:ekaadh_mobile/screens/home_shell.dart';
import 'package:ekaadh_mobile/screens/staff_login_screen.dart';

const _onboardingKey = 'onboarding_complete';

/// Light status bar matching the app's white/gray chrome.
const _lightSystemUi = SystemUiOverlayStyle(
  statusBarColor: Colors.white,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: Colors.white,
  systemNavigationBarIconBrightness: Brightness.dark,
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(_lightSystemUi);
  runApp(const EkaadhApp());
}

class EkaadhApp extends StatefulWidget {
  const EkaadhApp({super.key});

  @override
  State<EkaadhApp> createState() => _EkaadhAppState();
}

class _EkaadhAppState extends State<EkaadhApp> {
  final AuthService _auth = AuthService();
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

    await _auth.init();
    if (_auth.token != null) {
      final ok = await _auth.fetchMe();
      _signedIn = ok;
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
  }

  Future<void> _onSignOut() async {
    await _auth.logout();
    if (mounted) {
      setState(() => _signedIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (_booting) {
      home = const SplashScreen();
    } else if (!_onboardingDone) {
      home = OnboardingScreen(onComplete: _completeOnboarding);
    } else if (_signedIn && _isStaff) {
      home = StaffHome(auth: _auth, onSignOut: _onSignOut);
    } else {
      // Guests and signed-in customers land on Home — login is optional.
      home = HomeShell(
        auth: _auth,
        onSignedIn: _onSignedIn,
        onSignOut: _onSignOut,
      );
    }

    return MaterialApp(
      title: 'Ekaadh',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: EkaadhColors.brand,
          primary: EkaadhColors.brand,
          surface: EkaadhColors.surface,
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            borderSide: const BorderSide(color: EkaadhColors.brand, width: 1.5),
          ),
        ),
      ),
      home: home,
    );
  }
}
