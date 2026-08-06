# Push notifications setup (Firebase Cloud Messaging)

Firebase project: **ekaadh-71c90**

Ekaadh sends these push types from Laravel:

| Type | Trigger |
|------|---------|
| `support_reply` | Admin replies in support chat |
| `event_reminder` | ~24 hours before event start |
| `invitation_received` | Guest (with app account) receives a private invite |
| `private_event_paid` | Host finishes private-event payment |
| `invite_send_failed` | SMS to a guest fails (notifies host) |

## Already configured locally

- `android/app/google-services.json`
- `Ekaadh-backend/storage/app/firebase-credentials.json`
- Laravel `.env` → `FCM_ENABLED=true`, `FCM_PROJECT_ID=ekaadh-71c90`
- Google Services Gradle plugin enabled
- VS Code launch configs under `.vscode/launch.json`

## Run the app (Android)

Use **Run and Debug** → **Ekaadh Android (prod API + FCM)**, or:

```bash
cd Ekaadh-mobile
flutter run -d android ^
  --dart-define=API_BASE_URL=https://ekaadh.com/api/v1 ^
  --dart-define=FIREBASE_API_KEY=AIzaSyDdzFV9IlyJlKUHxWSw6IP0ixi9YE5ahag ^
  --dart-define=FIREBASE_APP_ID=1:1041974530298:android:19a08f42603cd160a4b943 ^
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=1041974530298 ^
  --dart-define=FIREBASE_PROJECT_ID=ekaadh-71c90 ^
  --dart-define=FIREBASE_STORAGE_BUCKET=ekaadh-71c90.firebasestorage.app
```

Allow notification permission when asked. Sign in → check `device_tokens` table.

## Production (Coolify)

1. Upload `firebase-credentials.json` to the server (e.g. `/app/storage/app/firebase-credentials.json`).
2. Set env:

```env
FCM_ENABLED=true
FCM_PROJECT_ID=ekaadh-71c90
FCM_CREDENTIALS=/app/storage/app/firebase-credentials.json
```

3. `php artisan config:clear`

## Verify

1. Sign in on Android.
2. Confirm a row in `device_tokens`.
3. Admin → Support → reply to that user → phone shows **Support replied**.
