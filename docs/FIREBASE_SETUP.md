# Firebase setup for Campus Incidents (Flutter Android)

Project ID used in this repo: **`campus-incident-reporting-app`**  
Android package: **`com.alu.campus_incidents`**

Follow these steps in order. Skipping Firestore or using the wrong **database ID** causes splash-screen hangs and `NOT_FOUND` errors in the terminal.

---

## 1. Firebase project

1. Open [Firebase Console](https://console.firebase.google.com/).
2. Use project **campus-incident-reporting-app** (or create it and re-run `flutterfire configure` — see step 3).
3. Upgrade to the **Blaze (pay-as-you-go)** plan only if you will deploy **Cloud Functions** (notifications). Firestore and Auth work on Spark. Photos go to Cloudflare R2, so Firebase Storage is never needed.

---

## 2. Register the Android app

1. Firebase Console → **Project settings** (gear) → **Your apps** → **Add app** → **Android**.
2. **Android package name:** `com.alu.campus_incidents` (must match exactly).
3. Add your **debug SHA-1** (needed for Auth / sign-up on device):

   From the project folder:

   ```bash
   cd android && ./gradlew signingReport
   ```

   Copy **SHA1** under `Variant: debug` (example format `BA:12:42:…`).

4. Paste SHA-1 in Firebase → Android app → **Add fingerprint** → Save.
5. Download **`google-services.json`** → replace  
   `android/app/google-services.json`.

After SHA-1 is added, download **again** — `oauth_client` in the JSON should no longer be empty.

---

## 3. Link Flutter to Firebase (`flutterfire`)

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

- Select project **campus-incident-reporting-app**.
- Select **Android** only (`com.alu.campus_incidents`).

This refreshes:

- `lib/firebase_options.dart`
- `android/app/google-services.json`

---

## 4. Authentication

1. Firebase Console → **Build** → **Authentication** → **Get started**.
2. **Sign-in method** → **Email/Password** → **Enable** → Save.
3. **Settings** → **Authorized domains** — ensure these exist:
   - `localhost`
   - `campus-incident-reporting-app.firebaseapp.com`

**Verification emails:** use a **real inbox** you can open. The app only checks `@alustudent.com` / `@alueducation.com` suffixes; mail is sent by Firebase (check spam). For local dev you can mark a user **Email verified** in Authentication → **Users**.

---

## 5. Firestore (fixes splash / `database (default) does not exist`)

The Flutter app talks to one Firestore database ID, configured in:

`lib/core/firebase/app_firestore.dart` → **`kFirestoreDatabaseId`**

### Option A — Recommended for new setup

Create the **default** database the app expects:

1. Firebase Console → **Build** → **Firestore Database**.
2. If you see **“Create database”**, click it.
3. **Standard** (Native mode, **not** MongoDB compatibility).
4. Pick a region (e.g. `nam5` / us-central — keep one region for everything).
5. When asked for **Database ID**, use **`(default)`** (this is the default name on first create).
6. Start in **test mode** for a quick try, then deploy rules (step 7).

### MongoDB mode vs Native (read this if you see `FAILED_PRECONDITION`)

If logcat says:

- `Access to this database via the Firestore in Native mode API is disabled`
- `Listen queries are not supported for this database`

your database was created in **MongoDB compatibility** mode (Firestore Studio shows a MongoDB connection string). **That mode cannot be switched.** The Flutter app needs **Standard / Native** Firestore.

**Fix:**

1. Firebase Console → **Firestore** → **Add database**.
2. Choose **Standard** (Native) — **not** MongoDB compatibility.
3. Database ID: **`(default)`** (recommended).
4. Leave `kFirestoreDatabaseId = '(default)'` in `lib/core/firebase/app_firestore.dart`.
5. `firebase deploy --only firestore` (see step 7).
6. Full restart: `flutter run`.

You can ignore or delete the old MongoDB-mode `campus-incidents-db` for this app; it will never work with `cloud_firestore`.

Empty collections are normal until someone registers or staff adds locations.

---

## 6. Photo storage (Cloudflare R2)

Incident photos are **not** stored in Firebase Storage, because that requires the
Blaze billing plan. They go to a **Cloudflare R2** bucket through a Worker that
authorizes uploads. Nothing to do in the Firebase console here — follow
[`worker/README.md`](../worker/README.md).

---

## 7. Deploy Firestore rules and indexes (CLI)

Install [Firebase CLI](https://firebase.google.com/docs/cli), then from the **repo root**:

```bash
firebase login
firebase use campus-incident-reporting-app
firebase deploy --only firestore
```

If `firebase use` fails, run `firebase init` and choose the existing project; keep `firestore.rules` and `firestore.indexes.json` from the repo.

**Database target:** `firebase.json` → `firestore.database` must match the database ID the app uses (`kFirestoreDatabaseId`). This repo uses `"(default)"`. If it points at a database that does not exist, `firebase deploy --only firestore` tries to *create* it (needs Blaze billing) and the rules never reach the database the app actually reads — every query then fails with `PERMISSION_DENIED: Missing or insufficient permissions.`

---

## 8. Cloud Functions (push + inbox)

```bash
cd functions && npm install && cd ..
firebase deploy --only functions
```

Requires **Blaze** plan. Until Functions are deployed, the app still runs; notifications may not fire.

---

## 9. Run the app

```bash
flutter pub get
flutter run
```

**Full restart** after changing `google-services.json`, `firebase_options.dart`, or `kFirestoreDatabaseId`.

---

## 10. Quick verification checklist

| Check | Where |
| ----- | ----- |
| Package `com.alu.campus_incidents` | Firebase Android app |
| SHA-1 on Android app | Project settings → Your apps |
| Email/Password enabled | Authentication |
| Firestore database ID matches `kFirestoreDatabaseId` | Firestore + `app_firestore.dart` |
| Rules deployed | `firebase deploy --only firestore` |
| User can register | Authentication → Users appears |
| Profile document | Firestore → `users/{uid}` after sign-up |

---

## Terminal errors → meaning

| Log message | Fix |
| ----------- | --- |
| `PERMISSION_DENIED: Missing or insufficient permissions.` on every read/write | Rules are not deployed to the database the app uses. Run `firebase deploy --only firestore:rules` and confirm `firebase.json` → `firestore.database` matches `kFirestoreDatabaseId`. |
| `database (default) does not exist` | Create a **Native** Firestore DB with ID `(default)` (or set `kFirestoreDatabaseId` to another **Native** DB ID). |
| `Native mode API is disabled` / `Listen queries are not supported` | Database is **MongoDB compatibility** — create a new **Standard / Native** database; mode cannot be changed. |
| `Cloud Firestore API has not been used` / disabled | [Enable Firestore API](https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=campus-incident-reporting-app), wait ~2 minutes. |
| `CONFIGURATION_NOT_FOUND` on sign-up | SHA-1 + Email/Password + new `google-services.json`. |
| Stuck on splash | Usually Firestore profile load failing; fix database ID + rules, then restart. |

---

## First-time app flow after setup

1. Open app → **Student** or **Instructor** → **Create account** with a **real** email on the right domain.
2. Verify email (or mark verified in console for dev).
3. **Instructor:** add at least one **location** so students can submit reports.
