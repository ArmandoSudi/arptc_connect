'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');
const admin = require('firebase-admin');

const projectId = process.env.GCLOUD_PROJECT || 'demo-arptc-connect-itsm';
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
const functionsHost = process.env.FUNCTIONS_EMULATOR_HOST || '127.0.0.1:5001';

if (!admin.apps.length) {
  admin.initializeApp({ projectId });
}
const db = admin.firestore();

test.beforeEach(async () => {
  await clearFirestore();
  await clearAuth();
});

test.after(async () => {
  await admin.app().delete();
});

test('exported change callable pins workflow, persists, and replays safely', async () => {
  const user = await createAccount('change-user@example.test');
  await seedAgent(user.localId, user.email, 'USER');
  await seedPublishedWorkflow();

  const command = {
    command: 'change.initialize_draft',
    idempotencyKey: 'callable-change-draft-001',
    payload: {
      changeId: 'callable-change-1',
      workflowDefinitionId: 'change-normal',
      changeType: 'normal',
      title: 'Upgrade the office network',
      description: 'Replace the distribution switch with tested hardware.',
      justification: 'Improve network reliability and capacity.',
    },
  };

  const unauthenticated = await invokeCallable(
    'itsmInitializeChangeDraft',
    command,
  );
  assert.equal(unauthenticated.error.status, 'UNAUTHENTICATED');

  const created = await invokeCallable(
    'itsmInitializeChangeDraft',
    command,
    user.idToken,
  );
  assert.equal(created.result.changeId, 'callable-change-1');
  assert.equal(created.result.status, 'draft');
  assert.equal(created.result.revision, 0);

  const replayed = await invokeCallable(
    'itsmInitializeChangeDraft',
    command,
    user.idToken,
  );
  assert.deepEqual(replayed.result, created.result);

  const [change, summary, receipts] = await Promise.all([
    db.collection('changeRequests').doc('callable-change-1').get(),
    db.collection('itsmWorkItemIndex')
      .doc('change_request:callable-change-1')
      .get(),
    db.collection('itsmCommandReceipts').get(),
  ]);
  assert.equal(change.exists, true);
  assert.equal(change.data().requesterId, user.localId);
  assert.equal(change.data().workflowVersion, 1);
  assert.equal(change.data().workflowVersionDocumentId, 'version_1');
  assert.equal(summary.data().requesterId, user.localId);
  assert.equal(receipts.size, 1);
});

test('exported operational change callable rejects ADMIN', async () => {
  const adminUser = await createAccount('change-admin@example.test');
  await seedAgent(adminUser.localId, adminUser.email, 'ADMIN');

  const denied = await invokeCallable(
    'itsmAssessChange',
    {
      command: 'change.assess',
      idempotencyKey: 'callable-change-assess-001',
      payload: {
        changeId: 'change-not-read',
        expectedRevision: 1,
        ownerUserId: 'manager-1',
        affectedServiceIds: ['network'],
        impact: 'medium',
        urgency: 'medium',
        complexity: 'medium',
        expectedDowntimeMinutes: 30,
        implementationPlan: 'Deploy the tested replacement.',
        testPlan: 'Validate connectivity and throughput.',
        communicationPlan: 'Notify affected teams before and after.',
        rollbackPlan: 'Restore the previous switch configuration.',
      },
    },
    adminUser.idToken,
  );

  assert.equal(denied.error.status, 'PERMISSION_DENIED');
  assert.equal((await db.collection('itsmCommandReceipts').get()).size, 0);
});

async function invokeCallable(functionName, data, idToken) {
  const response = await fetch(
    `http://${functionsHost}/${projectId}/us-central1/${functionName}`,
    {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        ...(idToken ? { authorization: `Bearer ${idToken}` } : {}),
      },
      body: JSON.stringify({ data }),
    },
  );
  const body = await response.json();
  assert.ok(
    body.result || body.error,
    `Unexpected callable response (${response.status}): ${JSON.stringify(body)}`,
  );
  return body;
}

async function createAccount(email) {
  const response = await fetch(
    `http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`,
    {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        email,
        password: 'Arptc@1234',
        returnSecureToken: true,
      }),
    },
  );
  const body = await response.json();
  assert.equal(response.ok, true, JSON.stringify(body));
  return body;
}

async function seedAgent(uid, email, role) {
  await db.collection('agents').doc(uid).set({
    firstName: role === 'ADMIN' ? 'Admin' : 'User',
    name: 'Change Callable',
    email,
    emailLower: email,
    isActive: true,
    modulePermissions: { ticketing: role },
  });
}

async function seedPublishedWorkflow() {
  const workflow = db.collection('workflowDefinitions').doc('change-normal');
  await Promise.all([
    workflow.set({
      name: 'Normal change workflow',
      status: 'published',
      publishedVersion: 1,
      supportedChangeTypes: ['normal'],
    }),
    workflow.collection('versions').doc('version_1').set({
      version: 1,
      status: 'published',
      supportedChangeTypes: ['normal'],
      standardPreAuthorized: false,
    }),
  ]);
}

async function clearFirestore() {
  const response = await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/`
      + `${projectId}/databases/(default)/documents`,
    { method: 'DELETE' },
  );
  assert.equal(response.ok, true, await response.text());
}

async function clearAuth() {
  const response = await fetch(
    `http://${authHost}/emulator/v1/projects/${projectId}/accounts`,
    { method: 'DELETE' },
  );
  assert.equal(response.ok, true, await response.text());
}
