/**
 * Campus Incidents — R2 upload proxy.
 *
 * The Android app cannot hold R2 secret keys, so every write goes through this
 * Worker. It verifies the caller's Firebase ID token, then enforces the same
 * ownership rules the app documents for Firestore:
 *
 *   upload  -> ALU student accounts only, <= 3 objects per incident, <= 5 MB
 *   delete  -> reporter of the incident (only while status == submitted),
 *              or any staff account
 *
 * Firestore itself is read with the *caller's* token, so the Firestore security
 * rules are the source of truth for who may touch an incident.
 */

const MAX_BYTES = 5 * 1024 * 1024;
const MAX_PHOTOS = 3;
const ALLOWED_TYPES = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
};

const json = (status, body) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  });

/** Verifies a Firebase ID token and returns { uid, email }. */
async function verifyIdToken(idToken, env) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${env.FIREBASE_API_KEY}`,
    {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ idToken }),
    },
  );
  if (!res.ok) return null;
  const data = await res.json();
  const user = (data.users || [])[0];
  if (!user || !user.email) return null;
  if (user.disabled) return null;
  return {
    uid: user.localId,
    email: String(user.email).toLowerCase(),
    emailVerified: user.emailVerified === true,
  };
}

/** Reads a Firestore document using the caller's own token (rules apply). */
async function readDoc(collection, id, idToken, env) {
  const url =
    `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}` +
    `/databases/(default)/documents/${collection}/${encodeURIComponent(id)}`;
  const res = await fetch(url, { headers: { authorization: `Bearer ${idToken}` } });
  if (res.status === 404) return null;
  if (!res.ok) return undefined;
  return res.json();
}

/** Flattens a Firestore REST document into { fieldName: primitive }. */
function fieldsOf(doc) {
  const out = {};
  for (const [key, value] of Object.entries(doc.fields || {})) {
    if (value.stringValue !== undefined) out[key] = value.stringValue;
    else if (value.booleanValue !== undefined) out[key] = value.booleanValue;
  }
  return out;
}

async function readRoleAndOwnership(uid, incidentId, idToken, env) {
  const userDoc = await readDoc('users', uid, idToken, env);
  if (!userDoc) return { role: null };
  const profile = fieldsOf(userDoc);

  let incident = null;
  if (incidentId) {
    const incidentDoc = await readDoc('incidents', incidentId, idToken, env);
    if (incidentDoc === undefined) return { role: profile.role, incidentUnreadable: true };
    if (incidentDoc) incident = fieldsOf(incidentDoc);
  }

  return { role: profile.role, incident };
}

/**
 * Only simple, predictable keys are accepted: incidents/<id>/<index>_<ts>.<ext>
 * This blocks path traversal and objects landing anywhere but the incident folder.
 */
function parseKey(pathname) {
  const parts = pathname.replace(/^\/+/, '').split('/').filter(Boolean);
  if (parts.length < 3) return null;
  const [root, incidentId, ...rest] = parts;
  const fileName = rest.join('/');
  if (root !== 'incidents') return null;
  if (!/^[A-Za-z0-9_-]{1,64}$/.test(incidentId)) return null;
  if (!/^[A-Za-z0-9_-]{1,64}\.(jpg|jpeg|png|webp)$/i.test(fileName)) return null;
  return { key: `incidents/${incidentId}/${fileName}`, incidentId };
}

async function handleUpload(request, env, key, incidentId) {
  const auth = request.headers.get('authorization') || '';
  const idToken = auth.startsWith('Bearer ') ? auth.slice(7) : null;
  if (!idToken) return json(401, { error: 'Missing bearer token.' });

  // Validate the payload before spending a token lookup on it.
  const contentType = (request.headers.get('content-type') || '').split(';')[0].trim().toLowerCase();
  if (!ALLOWED_TYPES[contentType]) {
    return json(415, { error: 'Only JPEG, PNG, or WebP images are allowed.' });
  }
  const declaredLength = Number(request.headers.get('content-length') || 0);
  if (declaredLength > MAX_BYTES) {
    return json(413, { error: 'Image must be smaller than 5 MB.' });
  }

  const user = await verifyIdToken(idToken, env);
  if (!user) return json(401, { error: 'Invalid or expired session.' });
  if (!user.emailVerified) {
    return json(403, { error: 'Verify your email address before uploading photos.' });
  }

  const { role } = await readRoleAndOwnership(user.uid, null, idToken, env);
  if (role !== 'student') {
    return json(403, { error: 'Only students can attach photos to reports.' });
  }

  // Cap photos per incident so a client cannot flood the bucket.
  const existing = await env.BUCKET.list({ prefix: `incidents/${incidentId}/`, limit: 10 });
  if ((existing.objects || []).length >= MAX_PHOTOS) {
    return json(409, { error: `An incident can have at most ${MAX_PHOTOS} photos.` });
  }

  const body = await request.arrayBuffer();
  if (body.byteLength === 0) return json(400, { error: 'Empty upload.' });
  if (body.byteLength > MAX_BYTES) return json(413, { error: 'Image must be smaller than 5 MB.' });

  await env.BUCKET.put(key, body, {
    httpMetadata: { contentType, cacheControl: 'public, max-age=31536000, immutable' },
    customMetadata: { uploadedBy: user.uid, incidentId },
  });

  return json(200, { key, url: `${env.R2_PUBLIC_URL}/${key}` });
}

async function handleDelete(request, env, key, incidentId) {
  const auth = request.headers.get('authorization') || '';
  const idToken = auth.startsWith('Bearer ') ? auth.slice(7) : null;
  if (!idToken) return json(401, { error: 'Missing bearer token.' });

  const user = await verifyIdToken(idToken, env);
  if (!user) return json(401, { error: 'Invalid or expired session.' });

  const { role, incident } = await readRoleAndOwnership(user.uid, incidentId, idToken, env);
  if (role !== 'student' && role !== 'staff') {
    return json(403, { error: 'Not allowed.' });
  }

  if (role !== 'staff') {
    if (!incident) return json(404, { error: 'Incident not found.' });
    if (incident.reporterId !== user.uid) {
      return json(403, { error: 'You can only delete photos on your own reports.' });
    }
    if (incident.status !== 'submitted') {
      return json(409, { error: 'Photos can only be removed while the report is submitted.' });
    }
  }

  await env.BUCKET.delete(key);
  return json(200, { deleted: key });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === 'GET' && url.pathname === '/health') {
      return json(200, { ok: true });
    }

    const parsed = parseKey(url.pathname);
    if (!parsed) return json(404, { error: 'Invalid object path.' });

    try {
      if (request.method === 'POST' || request.method === 'PUT') {
        return await handleUpload(request, env, parsed.key, parsed.incidentId);
      }
      if (request.method === 'DELETE') {
        return await handleDelete(request, env, parsed.key, parsed.incidentId);
      }
      return json(405, { error: 'Method not allowed.' });
    } catch (err) {
      // Never leak internals to the client; the Firebase/S3 error may include keys.
      console.error('storage worker error', err);
      return json(500, { error: 'Storage service unavailable.' });
    }
  },
};
