# RentNear — Environment & DevOps

---

## 1. Environment Overview

| Environment | Purpose | Supabase | Firebase |
|---|---|---|---|
| **Local** | Development & testing | Local CLI (`supabase start`) | Debug mode |
| **Staging** | Pre-release testing | Staging project (optional) | Debug/staging |
| **Production** | Live app | Production project | Release mode |

---

## 2. Prerequisites

### Development Machine Setup

| Tool | Version | Installation |
|---|---|---|
| Flutter SDK | 3.x (stable) | [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install) |
| Dart SDK | Bundled with Flutter | — |
| Android Studio | Latest | For Android SDK + emulators |
| Xcode | Latest (macOS only) | For iOS builds |
| VS Code | Latest | Recommended IDE |
| Git | Latest | Version control |
| Node.js | 18+ | For Supabase CLI |
| Supabase CLI | Latest | `npm install -g supabase` |
| Firebase CLI | Latest | `npm install -g firebase-tools` |

### VS Code Recommended Extensions
- Dart
- Flutter
- Supabase
- Firebase Explorer
- GitLens
- Error Lens

---

## 3. Project Bootstrap

### 3.1 Flutter Project Setup
```bash
# Create Flutter project
flutter create rentnear
cd rentnear

# Add core dependencies
flutter pub add supabase_flutter
flutter pub add flutter_riverpod
flutter pub add riverpod_annotation
flutter pub add go_router
flutter pub add hive
flutter pub add hive_flutter
flutter pub add sqflite
flutter pub add flutter_secure_storage
flutter pub add firebase_core
flutter pub add firebase_analytics
flutter pub add firebase_crashlytics
flutter pub add firebase_messaging
flutter pub add geolocator
flutter pub add image_picker
flutter pub add cached_network_image
flutter pub add intl
flutter pub add connectivity_plus

# Dev dependencies
flutter pub add --dev build_runner
flutter pub add --dev riverpod_generator
flutter pub add --dev hive_generator
flutter pub add --dev flutter_lints

# Verify
flutter pub get
flutter analyze
```

### 3.2 Supabase Setup
```bash
# Install Supabase CLI
npm install -g supabase

# Login
supabase login

# Initialize in project root
supabase init

# Link to remote project
supabase link --project-ref <your_project_ref>

# Start local Supabase (Docker required)
supabase start

# Apply migrations
supabase db reset        # local
supabase db push         # production
```

### 3.3 Firebase Setup
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for the Flutter project
flutterfire configure --project=<your_firebase_project_id>
```

---

## 4. Environment Variables

### `.env.example` (template)
```env
# Supabase
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<your-anon-key>

# Firebase (configured via google-services.json / GoogleService-Info.plist)
# No manual env vars needed — FlutterFire handles this

# FCM Server Key (for Edge Functions only)
FCM_SERVER_KEY=<your-fcm-server-key>
```

### Flutter Build-Time Variables
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_key

flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_key
```

### Usage in Code
```dart
await Supabase.initialize(
  url: const String.fromEnvironment('SUPABASE_URL'),
  anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
);
```

### Supabase Edge Function Secrets
```bash
# Set secrets for Edge Functions
supabase secrets set FCM_SERVER_KEY=<your-key>
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>
```

---

## 5. Supabase Migration Workflow

### Create a New Migration
```bash
supabase migration new <description_in_snake_case>
# Creates: supabase/migrations/YYYYMMDDHHMMSS_description.sql
```

### Apply Locally
```bash
supabase db reset    # Drops and recreates from migrations
```

### Push to Production
```bash
supabase db push     # Applies pending migrations to remote
```

### Pull Remote Changes
```bash
supabase db pull     # Generates migration from remote diff
```

### Migration Naming Convention
```
YYYYMMDDHHMMSS_description.sql
Example: 20260301000000_create_users_table.sql
```

> ⚠️ **Rule:** Never edit production schema directly. All changes go through migration files.

---

## 6. Edge Function Deployment

### Deploy an Edge Function
```bash
supabase functions deploy broadcast_request
```

### Test Locally
```bash
supabase functions serve broadcast_request --env-file .env
```

### Invoke (test)
```bash
curl -i --location --request POST \
  'http://localhost:54321/functions/v1/broadcast_request' \
  --header 'Authorization: Bearer <anon_key>' \
  --header 'Content-Type: application/json' \
  --data '{"requestId":"test","lat":19.0,"lng":72.8,"category":"tools"}'
```

---

## 7. CI/CD Pipeline — GitHub Actions

### `.github/workflows/ci.yml`
```yaml
name: RentNear CI

on:
  push:
    branches: [main, dev]
  pull_request:
    branches: [main]

jobs:
  analyze-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Analyze
        run: flutter analyze --fatal-infos

      - name: Run tests
        run: flutter test --coverage

      - name: Build APK (verify)
        run: flutter build appbundle --release
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
```

### GitHub Secrets to Configure

| Secret | Value |
|---|---|
| `SUPABASE_URL` | `https://<ref>.supabase.co` |
| `SUPABASE_ANON_KEY` | Supabase anon public key |
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded release keystore |
| `ANDROID_KEY_ALIAS` | Key alias |
| `ANDROID_KEY_PASSWORD` | Key password |
| `ANDROID_STORE_PASSWORD` | Store password |

---

## 8. Release Build Process

### Android
```bash
# Generate keystore (one-time)
keytool -genkey -v -keystore ~/rentnear-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias rentnear

# Configure key.properties
echo "storePassword=<password>
keyPassword=<password>
keyAlias=rentnear
storeFile=<path/to/rentnear-release.jks>" > android/key.properties

# Build
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=<url> \
  --dart-define=SUPABASE_ANON_KEY=<key>
```

### iOS
```bash
# Build IPA
flutter build ipa --release \
  --dart-define=SUPABASE_URL=<url> \
  --dart-define=SUPABASE_ANON_KEY=<key>

# Upload via Xcode Organizer or Transporter
```

---

## 9. Monitoring & Observability

| Tool | What It Monitors | Dashboard |
|---|---|---|
| Firebase Crashlytics | Runtime crashes | Firebase Console |
| Firebase Analytics | User sessions, events | Firebase Console |
| Supabase Dashboard | Database usage, Auth logs, API traffic | Supabase Console |
| Supabase Logs | Edge Function logs, Postgres logs | Supabase Console |
| GitHub Actions | Build status, test results | GitHub repo |

### Key Metrics to Track

| Metric | Tool | Alert Threshold |
|---|---|---|
| Crash-free sessions | Crashlytics | < 99.5% |
| Auth failures | Supabase Auth logs | > 5% of attempts |
| API response time | Supabase dashboard | > 800ms p95 |
| Edge Function errors | Supabase logs | Any 5xx |
| Database connections | Supabase dashboard | > 80% of limit |

---

## 10. Estimated Costs

| Service | MVP (Free Tier) | Growth (Pro) |
|---|---|---|
| Supabase | $0/month | $25/month |
| Firebase (Spark) | $0/month | Pay-as-you-go |
| Google Play | $25 (one-time) | — |
| Apple Developer | $99/year | — |
| Domain + Privacy Policy | ~$10/year | — |
| **Total Year 1** | **~$135** | **~$435** |
