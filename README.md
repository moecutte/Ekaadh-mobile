# Ekaadh Mobile

Flutter customer + staff check-in app for **Ekaadh**.

## Setup

```bash
flutter pub get
flutter run
```

API base URL is chosen automatically:

- Chrome / localhost on this PC → `http://127.0.0.1:8000/api/v1`
- Android emulator → `http://10.0.2.2:8000/api/v1`
- **Flutter web on LAN** → uses the host in the browser address bar  
  (open `http://YOUR_LAN_IP:8080` → API calls `http://YOUR_LAN_IP/Ekaadh-backend/public/api/v1`)

Start the Laravel API first (from `C:\xampp\htdocs\Ekaadh-backend`). Needs **PHP 8.3+** (use `C:\php\php.exe`, not XAMPP’s 8.2). Prefer the CORS router so Chrome can load event images:

```bash
cd C:\xampp\htdocs\Ekaadh-backend
C:\php\php.exe -S 127.0.0.1:8000 -t public public/router.php
```

Or plain artisan (images still work in the app via HTML img fallback):

```bash
C:\php\php.exe artisan serve --host=127.0.0.1 --port=8000
```

Keep XAMPP **MySQL** running. Apache is optional unless you use the LAN/Apache path above.

Access from another phone/laptop on the same Wi‑Fi:

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

Then open `http://192.168.x.x:8080` (this PC’s LAN IP).

Production:

```bash
flutter build apk --dart-define=API_BASE_URL=https://your-domain.com/api/v1
```

## Support

Profile → **Support** opens in-app FAQ and chat (same backend as the website widget). Admins reply from **Admin → Support → Inbox**.

## Push notifications

See [docs/PUSH_SETUP.md](docs/PUSH_SETUP.md). Without Firebase dart-defines the app runs normally and skips FCM.

## Brand

Colors match the web app brand (`#323891`) — see `lib/core/theme.dart`.

## Staff check-in

Login screen → **Staff check-in portal** → `staff@ekaadh.com` / `password` → select event → scan QR.
