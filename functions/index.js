const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

const STUDENT_SUFFIX = '@alustudent.com';
const STAFF_SUFFIX = '@alueducation.com';

admin.initializeApp();

async function sendToTokens(tokens, { title, body, incidentId }) {
  const unique = [...new Set(tokens)].filter(Boolean);
  if (unique.length === 0) {
    return;
  }
  await admin.messaging().sendEachForMulticast({
    tokens: unique,
    notification: { title, body },
    data: { incidentId: String(incidentId) },
  });
}

async function listStaffUsers() {
  const snap = await admin.firestore().collection('users').where('role', '==', 'staff').get();
  return snap.docs;
}

/** School-project password reset without email (ALU domain check only). */
exports.resetSchoolPassword = onCall(async (request) => {
  const email = String(request.data?.email || '').trim().toLowerCase();
  const newPassword = String(request.data?.newPassword || '');
  if (!email.endsWith(STUDENT_SUFFIX) && !email.endsWith(STAFF_SUFFIX)) {
    throw new HttpsError('invalid-argument', 'Use an ALU email address.');
  }
  if (newPassword.length < 6) {
    throw new HttpsError('invalid-argument', 'Password must be at least 6 characters.');
  }
  try {
    const user = await admin.auth().getUserByEmail(email);
    await admin.auth().updateUser(user.uid, { password: newPassword });
    return { ok: true };
  } catch (e) {
    if (e.code === 'auth/user-not-found') {
      throw new HttpsError('not-found', 'No account for this email. Create an account first.');
    }
    throw new HttpsError('internal', 'Could not reset password.');
  }
});

exports.onIncidentCreated = onDocumentCreated('incidents/{incidentId}', async (event) => {
  const snap = event.data;
  if (!snap) {
    return;
  }
  const data = snap.data();
  const incidentId = event.params.incidentId;
  const title = 'New campus report';
  const body = data.title ? String(data.title) : 'A new incident was submitted';

  const staffUsers = await listStaffUsers();
  const batch = admin.firestore().batch();
  const tokens = [];

  for (const doc of staffUsers) {
    const user = doc.data();
    tokens.push(...(user.fcmTokens || []));
    const notificationRef = admin.firestore().collection('notifications').doc();
    batch.set(notificationRef, {
      userId: doc.id,
      type: 'new_incident',
      title,
      body,
      incidentId,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
  await sendToTokens(tokens, { title, body, incidentId });
});

exports.onIncidentUpdated = onDocumentUpdated('incidents/{incidentId}', async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (!before || !after || before.status === after.status) {
    return;
  }

  const incidentId = event.params.incidentId;
  const reporterId = after.reporterId;
  if (!reporterId) {
    return;
  }

  const userDoc = await admin.firestore().collection('users').doc(reporterId).get();
  const tokens = userDoc.exists ? userDoc.data().fcmTokens || [] : [];
  const title = 'Report status updated';
  const body = `Status is now ${after.status}`;

  await admin.firestore().collection('notifications').add({
    userId: reporterId,
    type: 'status_update',
    title,
    body,
    incidentId,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await sendToTokens(tokens, { title, body, incidentId });
});
