// Creates (or updates) a pre-verified staff account: Auth user + users/{uid} profile.
//
//   SERVICE_ACCOUNT=./service-account.json \
//   SEED_EMAIL=staff@alueducation.com SEED_NAME="ALU Staff" SEED_PASSWORD='...' \
//   node scripts/seed-staff.js
//
// Run with the firebase-admin copy installed in functions/ (npm install there first).
const path = require('path');
const admin = require(path.join(__dirname, '..', 'functions', 'node_modules', 'firebase-admin'));

const { SERVICE_ACCOUNT, SEED_EMAIL, SEED_NAME, SEED_PASSWORD } = process.env;
if (!SERVICE_ACCOUNT || !SEED_EMAIL || !SEED_NAME || !SEED_PASSWORD) {
  console.error('Set SERVICE_ACCOUNT, SEED_EMAIL, SEED_NAME and SEED_PASSWORD.');
  process.exit(1);
}
if (!SEED_EMAIL.toLowerCase().endsWith('@alueducation.com')) {
  console.error('Staff email must end with @alueducation.com');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(path.resolve(SERVICE_ACCOUNT))),
});

(async () => {
  const email = SEED_EMAIL.trim().toLowerCase();
  let user;
  try {
    user = await admin.auth().getUserByEmail(email);
    user = await admin.auth().updateUser(user.uid, {
      password: SEED_PASSWORD,
      displayName: SEED_NAME,
      emailVerified: true,
    });
    console.log('Updated existing auth user', user.uid);
  } catch (e) {
    if (e.code !== 'auth/user-not-found') throw e;
    user = await admin.auth().createUser({
      email,
      password: SEED_PASSWORD,
      displayName: SEED_NAME,
      emailVerified: true,
    });
    console.log('Created auth user', user.uid);
  }

  await admin.firestore().collection('users').doc(user.uid).set(
    { email, fullName: SEED_NAME, role: 'staff', fcmTokens: [] },
    { merge: true },
  );
  console.log(`Seeded ${email} as verified staff.`);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
