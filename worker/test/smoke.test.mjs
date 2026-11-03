/**
 * Local smoke test for the R2 upload Worker, with Cloudflare and Firebase
 * faked out. Run with: node worker/test/smoke.test.mjs
 */

let putCount = 0;
let failPut = false;

const env = {
  FIREBASE_API_KEY: 'test-key',
  FIREBASE_PROJECT_ID: 'test-project',
  R2_PUBLIC_URL: 'https://pub-test.r2.dev',
  BUCKET: {
    async list() {
      return { objects: Array.from({ length: putCount }, (_, i) => ({ key: `incidents/x/${i}` })) };
    },
    async put(key, body, opts) {
      if (failPut) throw new Error('S3 internal detail: secret-key-abc123');
      putCount += 1;
      saved.set(key, { size: body.byteLength, opts });
    },
    async delete(key) {
      saved.delete(key);
    },
  },
};

const saved = new Map();

// ---- Fake network -------------------------------------------------------
let tokenResponse = null;
let docResponses = {};

globalThis.fetch = async (url, init = {}) => {
  const u = String(url);
  if (u.includes('accounts:lookup')) {
    if (!tokenResponse) return new Response('{}', { status: 401 });
    return Response.json(tokenResponse);
  }
  if (u.includes('firestore.googleapis.com')) {
    const id = decodeURIComponent(u.split('/documents/')[1]);
    const doc = docResponses[id];
    if (doc === undefined) return new Response('', { status: 404 });
    return Response.json(doc);
  }
  throw new Error(`unexpected fetch ${u}`);
};

const { default: worker } = await import('../src/index.js');

// ---- Helpers ------------------------------------------------------------
const student = {
  FIREBASE_API_KEY: 'k',
  users: {
    student: {
      fields: {
        role: { stringValue: 'student' },
        email: { stringValue: 's@alustudent.com' },
      },
    },
    staff: { fields: { role: { stringValue: 'staff' } } },
  },
};

function lookup(user) {
  tokenResponse = {
    users: [{ localId: user.uid, email: user.email, emailVerified: true }],
  };
}

function incident(overrides = {}) {
  return {
    fields: {
      reporterId: { stringValue: 'uid-student' },
      status: { stringValue: 'submitted' },
      ...overrides,
    },
  };
}

async function call(method, path, { token, body = 'imagebytes', contentType = 'image/jpeg' } = {}) {
  const headers = {};
  if (token) headers.authorization = `Bearer ${token}`;
  if (contentType) headers['content-type'] = contentType;
  const req = new Request(`https://worker.test${path}`, {
    method,
    headers,
    body: method === 'GET' ? undefined : body,
  });
  const res = await worker.fetch(req, env);
  const text = await res.text();
  let parsed;
  try {
    parsed = JSON.parse(text);
  } catch {
    parsed = text;
  }
  return { status: res.status, body: parsed };
}

let pass = 0;
let fail = 0;
function check(name, cond, extra) {
  if (cond) {
    pass += 1;
    console.log(`  pass  ${name}`);
  } else {
    fail += 1;
    console.log(`  FAIL  ${name}`, extra ?? '');
  }
}

// ---- Tests --------------------------------------------------------------
console.log('health');
{
  const r = await call('GET', '/health');
  check('health ok', r.status === 200 && r.body.ok === true, r);
}

console.log('auth');
{
  const r = await call('POST', '/incidents/inc1/0_1.jpg');
  check('no token -> 401', r.status === 401, r);
}
{
  tokenResponse = null;
  const r = await call('POST', '/incidents/inc1/0_1.jpg', { token: 'bad' });
  check('invalid token -> 401', r.status === 401, r);
}
{
  lookup({ uid: 'uid-student', email: 's@alustudent.com' });
  env.FIREBASE_API_KEY = 'k';
  docResponses['users/uid-student'] = student.users.student;
  const r = await call('POST', '/incidents/inc1/0_1.jpg', { token: 't', contentType: 'application/pdf' });
  check('bad content type -> 415', r.status === 415, r);
}
{
  const big = 'x'.repeat(5 * 1024 * 1024 + 1);
  const r = await call('POST', '/incidents/inc1/0_1.jpg', { token: 't', body: big });
  check('oversized body -> 413', r.status === 413, r);
}

console.log('role checks');
{
  lookup({ uid: 'uid-staff', email: 't@alueducation.com' });
  docResponses['users/uid-staff'] = student.users.staff;
  const r = await call('POST', '/incidents/inc1/0_1.jpg', { token: 't' });
  check('staff cannot upload -> 403', r.status === 403, r);
}
{
  tokenResponse = { users: [{ localId: 'uid-s', email: 's@alustudent.com', emailVerified: false }] };
  docResponses['users/uid-s'] = student.users.student;
  const r = await call('POST', '/incidents/inc1/0_1.jpg', { token: 't' });
  check('unverified email -> 403', r.status === 403, r);
}

console.log('happy path + limits');
{
  putCount = 0;
  saved.clear();
  lookup({ uid: 'uid-student', email: 's@alustudent.com' });
  docResponses['users/uid-student'] = student.users.student;
  const r = await call('POST', '/incidents/inc1/0_1.jpg', { token: 't' });
  check('student upload -> 200', r.status === 200, r);
  check('returns public url', r.body.url === 'https://pub-test.r2.dev/incidents/inc1/0_1.jpg', r.body);
  check('object stored', saved.has('incidents/inc1/0_1.jpg'));
}
{
  putCount = 3;
  const r = await call('POST', '/incidents/inc1/3_4.jpg', { token: 't' });
  check('4th photo -> 409', r.status === 409, r);
}
{
  putCount = 0;
  const r = await call('POST', '/incidents/inc1/0_1.jpg', { token: 't', body: '' });
  check('empty body -> 400', r.status === 400, r);
}

console.log('delete rules');
{
  lookup({ uid: 'uid-student', email: 's@alustudent.com' });
  docResponses['users/uid-student'] = student.users.student;
  docResponses['incidents/inc1'] = incident();
  putCount = 1;
  const r = await call('DELETE', '/incidents/inc1/0_1.jpg', { token: 't' });
  check('reporter deletes while submitted -> 200', r.status === 200, r);
}
{
  docResponses['incidents/inc1'] = incident({ status: { stringValue: 'in_progress' } });
  const r = await call('DELETE', '/incidents/inc1/0_1.jpg', { token: 't' });
  check('reporter blocked after submitted -> 409', r.status === 409, r);
}
{
  docResponses['incidents/inc1'] = incident({ reporterId: { stringValue: 'someone-else' } });
  const r = await call('DELETE', '/incidents/inc1/0_1.jpg', { token: 't' });
  check('non-reporter blocked -> 403', r.status === 403, r);
}
{
  lookup({ uid: 'uid-staff', email: 't@alueducation.com' });
  docResponses['users/uid-staff'] = student.users.staff;
  docResponses['incidents/inc1'] = incident({ status: { stringValue: 'resolved' } });
  const r = await call('DELETE', '/incidents/inc1/0_1.jpg', { token: 't' });
  check('staff deletes any status -> 200', r.status === 200, r);
}

console.log('misc');
{
  putCount = 0;
  lookup({ uid: 'uid-student', email: 's@alustudent.com' });
  docResponses['users/uid-student'] = student.users.student;
  failPut = true;
  const r = await call('POST', '/incidents/inc1/0_1.jpg', { token: 't' });
  check('internal error -> 500', r.status === 500, r);
  check('does not leak internals', !JSON.stringify(r.body).includes('secret-key'), r.body);
  failPut = false;
}
{
  const r = await call('POST', '/incidents/../etc/0_1.jpg', { token: 't' });
  check('traversal rejected -> 404', r.status === 404, r);
}
{
  const r = await call('PATCH', '/incidents/inc1/0_1.jpg', { token: 't' });
  check('unsupported method -> 405', r.status === 405, r);
}

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail === 0 ? 0 : 1);
