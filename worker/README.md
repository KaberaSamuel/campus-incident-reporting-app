# Cloudflare R2 photo storage

Incident photos live in **Cloudflare R2**, not Firebase Storage. Firebase Storage
requires the Blaze (billing) plan; R2 works on the free tier.

```
Flutter app ──(Firebase ID token)──> Cloudflare Worker ──> R2 bucket
                                          │
                                          └─ verifies token + role, then writes
                                       
Flutter app <──(public r2.dev URL)───── R2 bucket   (read path, no auth)
```

## Why a Worker sits in the middle

An APK can be unpacked, so R2 secret keys can never ship inside the app. The
Worker is the only place holding them. It verifies the caller's Firebase ID
token, looks up `users/{uid}.role`, and applies the same rules as Firestore:

| Action | Allowed |
| ------ | ------- |
| Upload a photo | `role == student`, max 3 per incident, max 5 MB, JPEG/PNG/WebP |
| Delete a photo | staff (any), or the incident's reporter while `status == submitted` |
| Read a photo | anyone with the public URL (the URL contains a random document ID) |

## One-time setup

### 1. Public access already enabled

The bucket `incident-reporting-app` exists with public access on. Copy its
**r2.dev** public URL from Cloudflare dashboard → R2 → `incident-reporting-app`
→ Settings → Public access.

### 2. Authenticate wrangler

Interactive shells:

```bash
cd worker
npx wrangler login
```

CI or non-interactive shells need a token instead
(Cloudflare dashboard → My Profile → API Tokens → Create Token, template
**Edit Cloudflare Workers**, plus **R2 write** permission):

```bash
export CLOUDFLARE_API_TOKEN=...
```

### 3. Point the Worker at your bucket URL and API key

Edit `worker/wrangler.toml`:

```toml
R2_PUBLIC_URL = "https://pub-<your-id>.r2.dev"
```

Store the Firebase Web API key (same value as `apiKey` in
`lib/firebase_options.dart`) as a secret:

```bash
cd worker
npx wrangler secret put FIREBASE_API_KEY
```

### 4. Deploy

```bash
cd worker
npx wrangler deploy
```

Note the deployed URL, e.g.
`https://campus-incidents-storage.<your-subdomain>.workers.dev`.

### 5. Tell the app where the Worker is

`lib/core/services/image_storage_service.dart` has a compile-time default.
Either edit `defaultBaseUrl`, or pass it at run time:

```bash
flutter run --dart-define=R2_WORKER_URL=https://campus-incidents-storage.<your-subdomain>.workers.dev
```

## Verifying it works

```bash
curl https://campus-incidents-storage.<sub>.workers.dev/health
# {"ok":true}
```

An upload with no token must be rejected:

```bash
curl -i -X POST https://campus-incidents-storage.<sub>.workers.dev/incidents/abc/0_1.jpg \
  -H 'content-type: image/jpeg' --data-binary 'x'
# 401 {"error":"Missing bearer token."}
```

## Notes and limits

- **Firebase Storage is fully removed**: no `firebase_storage` dependency, no
  `storage.rules`, no `storage` block in `firebase.json`. `firebase deploy
  --only firestore` is all you need.
- Deleting an incident removes its photo objects through the Worker; failures are
  swallowed so a missing object never blocks the Firestore delete.
- The photo cap is enforced in two places: the app (`kMaxIncidentPhotos`) and the
  Worker (R2 `list` before each put).
- Public URLs are unguessable but **not secret**. Anyone you share one with can
  view it. If that ever matters, switch the bucket off public access and serve
  images through the Worker with a signed URL (`handleDownload` would be the
  place to add it).
