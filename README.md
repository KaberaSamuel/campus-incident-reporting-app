# Campus Incidents

Android Flutter app for ALU campus incident reporting. See [product.md](./product.md) and [implementation-plan.md](./implementation-plan.md).

## Setup

**Full Firebase + Flutter steps:** [docs/FIREBASE_SETUP.md](./docs/FIREBASE_SETUP.md)

Quick summary:

1. Install [Flutter](https://docs.flutter.dev/get-started/install) (stable) and Android Studio / SDK.
2. Firebase project **campus-incident-reporting-app**: Android app `com.alu.campus_incidents`, **debug SHA-1**, Email/Password Auth, **Firestore** (database ID must match `kFirestoreDatabaseId` in `lib/core/firebase/app_firestore.dart`), Blaze for Functions. Photos use **Cloudflare R2** (see `worker/`), not Firebase Storage.
3. `flutterfire configure` → updates `lib/firebase_options.dart` and `android/app/google-services.json`.
4. `firebase deploy --only firestore,storage` then `firebase deploy --only functions` (after `cd functions && npm install`).
5. `flutter pub get` && `flutter run`.

If logs say **`database (default) does not exist`** but you created **`campus-incidents-db`**, either add a `(default)` database in Firebase or set `kFirestoreDatabaseId = 'campus-incidents-db'`.

## App ID

`com.alu.campus_incidents` — display name **Campus Incidents**.

## Test accounts

Sign up with **full name**, password, and any email ending in `@alustudent.com` or `@alueducation.com` (use a real inbox you can open). A verification email is sent at sign-up; the app stays locked on the "Verify your email" screen until the link is opened.

**Reset password** (from sign-in): email + new password (requires `firebase deploy --only functions` for `resetSchoolPassword`). **Change password** (from Profile): current + new password while signed in.

**Firebase project checklist** (fixes common log errors):

1. [Create a Firestore database](https://console.cloud.google.com/datastore/setup?project=campus-incident-reporting-app) (Native mode) and [enable the Firestore API](https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=campus-incident-reporting-app) for `campus-incident-reporting-app`. Without a database, the app can hang on launch while loading your profile.
2. Authentication → **Email/Password** enabled; Android app has your debug **SHA-1**; fresh `google-services.json` in `android/app/`.
3. Authentication → **Settings** → **Authorized domains** includes `campus-incident-reporting-app.firebaseapp.com`.

Staff should add at least one **location** before students can submit reports.

## Manual test checklist

- [ ] Register/login for both domains; reset password; change password; logout
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
- `worker/` — Cloudflare Worker that authorizes Cloudflare R2 photo uploads
- `firestore.rules`, `firestore.indexes.json`
