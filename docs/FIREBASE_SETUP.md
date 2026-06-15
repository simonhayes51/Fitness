# Firebase setup (optional)

ForgeFit runs fully offline without Firebase. Follow these steps to enable
cloud auth, sync, storage and push notifications.

## 1. Create the project & apps

1. Create a project in the [Firebase console](https://console.firebase.google.com/).
2. Install the CLI tools:
   ```bash
   dart pub global activate flutterfire_cli
   npm install -g firebase-tools
   firebase login
   ```
3. From the repo root, generate platform config:
   ```bash
   flutterfire configure
   ```
   This writes `lib/firebase_options.dart` (git-ignored) and the native config
   files (`google-services.json`, `GoogleService-Info.plist`).

## 2. Turn it on in `main.dart`

Uncomment the Firebase block in `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

## 3. Enable auth providers

In **Authentication → Sign-in method**, enable:

- **Email/Password**
- **Google** — add your SHA-1/SHA-256 (Android) and reversed client id (iOS).
- **Apple** — configure a Services ID and key (required for App Store).

The `sign_in_with_apple` and `google_sign_in` packages are already in
`pubspec.yaml`. Add an `AuthService` wrapping `FirebaseAuth` and a
`StreamProvider<User?>` to gate the router on auth state.

## 4. Firestore & rules

Create a Firestore database and paste the rules from
[`DATABASE_SCHEMA.md`](DATABASE_SCHEMA.md). Implement `FirestoreSyncService` as
described in [`ARCHITECTURE.md`](ARCHITECTURE.md) — the local repositories are
the only integration surface.

## 5. Push notifications (FCM)

`firebase_messaging` is included. On startup, request a token and pass it to
`NotificationService.pushIntegrationPoint(token)` to register the device with
your backend for coach messages, social and re-engagement pushes.

## 6. Secrets

**Never commit** `firebase_options.dart`, `google-services.json`,
`GoogleService-Info.plist` or API keys — they are already in `.gitignore`.
Provide third-party keys (e.g. a food API or LLM proxy) via:

```bash
flutter run --dart-define=NUTRITION_API_KEY=xxx --dart-define=COACH_API_URL=yyy
```
