# Ekaadh Mobile

Flutter customer + staff check-in app for **Ekaadh**.

## Setup

```bash
flutter pub get
flutter run
```

API base URL is chosen automatically:

- **Flutter web / web-server** → uses the host in the browser address bar  
  (open `http://YOUR_LAN_IP:8080` → API calls `http://YOUR_LAN_IP/ekaadh/...`)
- Chrome on this PC → `http://localhost/ekaadh/Ekaadh-backend/public/api/v1`
- Android emulator → `http://10.0.2.2/ekaadh/Ekaadh-backend/public/api/v1`

Access from another phone/laptop on the same Wi‑Fi:

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

Then open `http://192.168.x.x:8080` (this PC’s LAN IP). Keep XAMPP Apache running.

Optional overrides:

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080 --dart-define=API_HOST=192.168.100.54
# or full URL:
flutter run --dart-define=API_BASE_URL=http://192.168.100.54/ekaadh/Ekaadh-backend/public/api/v1
```

Production:

```bash
flutter build apk --dart-define=API_BASE_URL=https://your-domain.com/api/v1
```

## Brand

Colors match the web app brand (`#323891`) — see `lib/core/theme.dart`.

## Staff check-in

Login screen → **Staff check-in portal** → `staff@ekaadh.com` / `password` → select event → scan QR.
