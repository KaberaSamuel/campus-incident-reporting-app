# Campus Incidents

Android Flutter app for ALU campus incident reporting. See [product.md](./product.md) and [implementation-plan.md](./implementation-plan.md).

## Setup

1. Install [Flutter](https://docs.flutter.dev/get-started/install) (stable) and Android Studio / SDK.
2. **Firebase:** Create a project on the [Blaze plan](https://firebase.google.com/pricing) (required for Cloud Functions). Enable **Authentication** (email/password), **Firestore**, **Storage**, and **Cloud Messaging**.
3. Link the app:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This generates `lib/firebase_options.dart` and `android/app/google-services.json`.
4. Deploy security rules, indexes, and Storage rules:
   ```bash
   firebase deploy --only firestore,storage
   ```
5. Deploy Cloud Functions (push + in-app inbox):
   ```bash
   cd functions && npm install && cd ..
   firebase deploy --only functions
   ```
6. Run on Android:
   ```bash
   flutter pub get
   flutter run
   ```

## App ID

`com.alu.campus_incidents` — display name **Campus Incidents**.

## Test accounts

Use two Firebase Auth users (verify email before using the app):

| Role    | Email domain        | Example              |
| ------- | ------------------- | -------------------- |
| Student | `@alustudent.com`   | `student@alustudent.com` |
| Staff   | `@alueducation.com` | `staff@alueducation.com` |

Sign up in the app with **full name**, email, and password. Role is assigned from the email domain. Staff should add at least one **location** before students can submit reports.

## Manual test checklist

- [ ] Register/login for both domains; forgot password; logout
- [ ] Email verification gate before student/staff shells
- [ ] Student: submit report with 0–3 photos; blocked when locations empty
- [ ] Student: campus list, **My reports**, **You** tag, search/filters, pagination
- [ ] Student: delete own report only while status is **submitted**
- [ ] Staff: dashboard counts; update status and **staff note**; delete any report
- [ ] Staff: manage locations; delete fails when a location is referenced
- [ ] Push notification + in-app inbox on new report (staff) and status change (reporter)
- [ ] Tap notification opens incident detail

## Project layout

- `lib/` — Flutter app (Provider, `go_router`, feature folders)
- `functions/` — Firestore triggers for FCM + `notifications` collection
- `firestore.rules`, `storage.rules`, `firestore.indexes.json`
