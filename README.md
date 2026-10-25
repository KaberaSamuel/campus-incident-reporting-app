# Campus Incidents

Android Flutter app for ALU campus incident reporting. See [product.md](./product.md) and [implementation-plan.md](./implementation-plan.md).

## Setup

1. Install [Flutter](https://docs.flutter.dev/get-started/install) (stable).
2. **Firebase:** Create a Firebase project, enable Auth (email/password), Firestore, and Storage. Run:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This replaces `lib/firebase_options.dart` and `android/app/google-services.json`.
3. Run on Android: `flutter run`

## App ID

`com.alu.campus_incidents` — display name **Campus Incidents**.
