# Ekaadh Mobile

Flutter customer + staff check-in app for **Ekaadh**.

## Setup

```bash
flutter pub get
flutter run
```

By default the app talks to **production**: `https://ekaadh.com/api/v1`.

Override for local Laravel:

```bash
# Android emulator → artisan on this PC
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1

# Physical phone / LAN → your PC IP
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000/api/v1
```

Start local Laravel only when using those overrides (from `Ekaadh-backend`). Needs **PHP 8.3+**:

```bash
cd C:\xampp\htdocs\Ekaadh\Ekaadh-backend
C:\php\php.exe -S 127.0.0.1:8000 -t public public/router.php
```

Release APK (already defaults to ekaadh.com):

```bash
flutter build apk --release
```

Android release signing: copy `android/key.properties.example` to `android/key.properties` and point it at your upload keystore. Without that file, local `--release` still uses the debug keystore so `flutter run --release` works.

Push: Android release uses `google-services.json`. Optional dart-defines still override it (see [docs/PUSH_SETUP.md](docs/PUSH_SETUP.md)).

## Support

Profile → **Support** opens in-app FAQ and chat (same backend as the website widget). Admins reply from **Admin → Support → Inbox**.

## Push notifications

See [docs/PUSH_SETUP.md](docs/PUSH_SETUP.md). Android release includes Firebase from `google-services.json`. iOS still needs an `GoogleService-Info.plist` / dart-defines.

## Brand

Colors match the web app brand (`#323891`) — see `lib/core/theme.dart`.

## Staff check-in

Login screen → **Staff check-in portal**. Seeded staff login is `staff@ekaadh.com` / `password`.
