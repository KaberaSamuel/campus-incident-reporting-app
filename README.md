# Campus Incident Reporting App

Android app built with Flutter for ALU students and staff to report campus problems (broken facilities, water or electricity outages, furniture, sanitation, safety) and follow them until they are resolved.

**Author:** Samuel Kabera Nshuti · [s.kabera@alustudent.com](mailto:s.kabera@alustudent.com)

## Features

- **Students:** report an incident with category, title, description, location and up to 3 photos; browse all campus reports; search and filter (category, status, location, *My reports*); see status timeline; delete own report while still `submitted`.
- **Staff:** dashboard with counts per status, update status with a staff note, manage locations.
- **Notifications:** push (FCM) and in-app inbox when an incident is created (staff) or its status changes (reporter). Tapping opens the incident.
- **Auth:** Firebase email/password, restricted to `@alustudent.com` (student) and `@alueducation.com` (staff), with email verification, password reset and change password.

## Tech stack

| Area | Choice |
|---|---|
| App | Flutter, Provider (`AuthProvider`, `IncidentListProvider`), `go_router` |
| Backend | Firebase Auth, Cloud Firestore (+ security rules), Cloud Functions, FCM |
| Photos | Cloudflare R2 behind a Cloudflare Worker (`worker/`) that verifies the Firebase ID token; images compressed on-device |

Firebase Storage was not used because it requires the paid Blaze plan.

## Architecture

Feature folders in `lib/` (`auth, incidents, locations, notifications, profile, staff, student`), each split into screens, models, providers and repositories. The UI never talks to Firebase directly; only repositories do. Navigation uses two `ShellRoute`s (student and staff), and a `redirect` sends signed-out users to login and keeps each role on its own screens.

```
Flutter UI → Providers → Repositories ─┬─ Firebase Auth
                                       ├─ Firestore (+ rules)
                                       ├─ Cloud Functions (notifications, password reset)
                                       └─ Cloudflare Worker → R2 (photos)
```

## Data model (Firestore)

| Collection | Purpose |
|---|---|
| `users/{uid}` | email, fullName, role (`student` \| `staff`), fcmTokens |
| `incidents/{id}` | reporter, category, title, description, location, `imageUrls` (max 3), status, staffNote, `statusHistory[]`, timestamps |
| `locations/{id}` | places students can pick (managed by staff) |
| `notifications/{id}` | in-app inbox, written by Cloud Functions |

Status flow: `submitted` → `in_progress` → `resolved`.

## Access control

Enforced in three places, not just by hiding buttons:

1. **Router:** role-based redirects.
2. **Firestore rules:** students create only their own `submitted` incidents; only staff update `status`, `staffNote`, `updatedAt`, `statusHistory`; only staff edit locations; users read only their own profile and notifications.
3. **Cloudflare Worker:** ALU accounts only, max 3 photos per incident, 5 MB each; delete allowed for the reporter (while `submitted`) or staff.

## Getting started

Prerequisites: Flutter (stable), Android SDK, Node.js, Firebase CLI, a Firebase project and a Cloudflare account.

1. Create the Firebase project, register Android app `com.alu.campus_incidents` (with debug SHA-1), enable Email/Password auth and create a Firestore database. Details: [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md).
2. `flutterfire configure` to generate `lib/firebase_options.dart` and `android/app/google-services.json`.
3. Deploy rules and functions:
   ```bash
   firebase deploy --only firestore
   cd functions && npm install && cd .. && firebase deploy --only functions
   ```
4. Deploy the photo Worker (see [worker/README.md](worker/README.md)).
5. Run the app:
   ```bash
   flutter pub get
   flutter run
   ```

Staff must add at least one location before students can submit reports.

### Staff account

Staff are created from the `@alueducation.com` domain. To create a pre-verified staff account for a demo:

```bash
SERVICE_ACCOUNT=./service-account.json \
SEED_EMAIL=staff@alueducation.com SEED_NAME="ALU Staff" SEED_PASSWORD='<password>' \
node scripts/seed-staff.js
```

`service-account.json` is git-ignored; never commit it.

## Testing

- **Automated:** unit/widget tests in `test/` (`flutter test`).
- **Manual (Android emulator):** register/login for both domains; reset and change password; submit reports with 0–3 photos; search and filter; delete own report only while `submitted`; staff status update and note; manage locations (delete blocked when in use); push notification and inbox; tapping a notification opens the incident.

## Project layout

```
lib/          Flutter app
functions/    Cloud Functions (FCM + notifications, password reset)
worker/       Cloudflare Worker for R2 photo uploads
scripts/      seed-staff.js
test/         Tests
docs/         Setup guide and assignment report
firestore.rules, firestore.indexes.json
```
