import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ekaadh_mobile/core/api_config.dart';
import 'package:ekaadh_mobile/firebase_options.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';

/// Background isolate handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op: data is handled when the user opens the app.
}

class PushNotificationService {
  PushNotificationService._();

  static bool _ready = false;
  static String? _fcmToken;

  static bool get isReady => _ready;

  static Future<void> init() async {
    if (_ready) return;
    if (!DefaultFirebaseOptions.isConfigured) {
      if (kDebugMode) {
        debugPrint(
          'FCM skipped: pass FIREBASE_* dart-defines (see docs/PUSH_SETUP.md).',
        );
      }
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      _fcmToken = await messaging.getToken();
      messaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
      });

      FirebaseMessaging.onMessage.listen((message) {
        if (kDebugMode) {
          debugPrint(
            'FCM foreground: ${message.notification?.title} ${message.data}',
          );
        }
      });

      _ready = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM init failed: $e');
      }
    }
  }

  static String get _platform {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'android';
  }

  static Future<void> syncToken(AuthService auth) async {
    if (!_ready || auth.token == null) return;

    final token = _fcmToken ?? await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;
    _fcmToken = token;

    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/device-token'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.token}',
        },
        body: jsonEncode({
          'token': token,
          'platform': _platform,
          'device_name': 'flutter',
        }),
      );
    } catch (_) {
      // Ignore network errors — next login/resume will retry.
    }
  }

  static Future<void> clearToken(AuthService auth) async {
    final token = _fcmToken;
    if (!_ready || auth.token == null || token == null) return;

    try {
      await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/auth/device-token'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.token}',
        },
        body: jsonEncode({'token': token}),
      );
    } catch (_) {}
  }
}
