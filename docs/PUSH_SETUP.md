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

You need the Firebase **service account JSON** on the server (the same file as local `Ekaadh-backend/storage/app/firebase-credentials.json`). Do **not** commit it to git.

### 1. Persistent storage (required)

In Coolify → your app → **Storages** / **Persistent Storage**, mount a volume on:

| Container path | Purpose |
|----------------|---------|
| `/app/storage/app` | Uploads + `firebase-credentials.json` |

Without this, the file is wiped on every redeploy.

### 2. Upload `firebase-credentials.json`

**Option A — Coolify Terminal (easiest)**

1. Coolify → your app → **Terminal** (open a shell in the running container).
2. Confirm the storage folder exists:

```bash
mkdir -p /app/storage/app
ls -la /app/storage/app
```

3. Create the file. Paste the **full** JSON from your local machine (one shot):

```bash
cat > /app/storage/app/firebase-credentials.json << 'EOF'
{ ... paste entire service account JSON here ... }
EOF
```

4. Lock permissions and verify:

```bash
chmod 600 /app/storage/app/firebase-credentials.json
ls -la /app/storage/app/firebase-credentials.json
php -r "echo json_decode(file_get_contents('/app/storage/app/firebase-credentials.json'))->project_id, PHP_EOL;"
```

Expected output: `ekaadh-71c90`

**Option B — From your PC with `scp` / SFTP**

If you have SSH to the Coolify host (not only the app terminal), copy into the volume that maps to `/app/storage/app`, then rename to `firebase-credentials.json`.

**Option C — Coolify File Manager** (if enabled on your install)

Upload the JSON into the mounted `storage/app` folder and name it exactly `firebase-credentials.json`.

### 3. Environment variables

Coolify → your app → **Environment Variables** → add/update:

```env
FCM_ENABLED=true
FCM_PROJECT_ID=ekaadh-71c90
FCM_CREDENTIALS=/app/storage/app/firebase-credentials.json
```

Save / redeploy so the container picks up the env (or restart the app).

### 4. Clear config cache

In Coolify Terminal:

```bash
php artisan config:clear
php artisan config:show fcm
```

You should see `enabled=true`, `project_id=ekaadh-71c90`, and the credentials path readable.

### 5. Scheduler (event reminders)

Ensure Coolify runs Laravel’s scheduler every minute (`php artisan schedule:run`) so `events:send-reminders` can fire. See `Ekaadh-backend/DEPLOY.md`.

## Verify

1. Sign in on Android.
2. Confirm a row in `device_tokens`.
3. Admin → Support → reply to that user → phone shows **Support replied**.
