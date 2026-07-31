'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');
const admin = require('firebase-admin');

const projectId = process.env.GCLOUD_PROJECT || 'demo-arptc-connect-itsm';
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
const functionsHost = process.env.FUNCTIONS_EMULATOR_HOST || '127.0.0.1:5001';

if (!admin.apps.length) admin.initializeApp({projectId});
const db = admin.firestore();

test.beforeEach(async () => {
  await clearFirestore();
  await clearAuth();
});

test.after(async () => admin.app().delete());

test('SLA configuration callable is MANAGER-only and replay safe', async () => {
  const manager = await createAccount('reporting-manager@example.test');
  const administrator = await createAccount('reporting-admin@example.test');
  await Promise.all([
    seedAgent(manager.localId, manager.email, 'MANAGER'),
    seedAgent(administrator.localId, administrator.email, 'ADMIN'),
  ]);
  const command = {
    idempotencyKey: 'reporting-sla-callable-001',
    payload: {
      definitionId: 'incident-response-sla',
      sourceVersionDocumentId: null,
      draft: {
        name: {en: 'Incident response', fr: 'Reponse aux incidents'},
        workItemType: 'incident',
        priority: 'P2',
        serviceId: null,
        responseTargetMinutes: 60,
        resolutionTargetMinutes: 240,
        fulfilmentTargetMinutes: null,
        timeZone: 'Africa/Kinshasa',
        weeklyWindows: {
          1: [{start: '08:00', end: '17:00'}],
          2: [{start: '08:00', end: '17:00'}],
          3: [{start: '08:00', end: '17:00'}],
          4: [{start: '08:00', end: '17:00'}],
          5: [{start: '08:00', end: '17:00'}],
        },
        holidays: [],
        pauseStates: ['awaiting_user'],
        warningThreshold: 0.8,
        escalationTargets: [],
      },
    },
  };

  const unauthenticated = await invoke('itsmCreateSlaPolicyDraft', command);
  assert.equal(unauthenticated.error.status, 'UNAUTHENTICATED');
  const denied = await invoke(
    'itsmCreateSlaPolicyDraft', command, administrator.idToken,
  );
  assert.equal(denied.error.status, 'PERMISSION_DENIED');

  const created = await invoke(
    'itsmCreateSlaPolicyDraft', command, manager.idToken,
  );
  const replayed = await invoke(
    'itsmCreateSlaPolicyDraft', command, manager.idToken,
  );
  assert.deepEqual(replayed.result, created.result);
  assert.equal(created.result.entityId, 'incident-response-sla');
  assert.equal(created.result.versionId, 'v1');

  const version = await db.collection('slaPolicies')
    .doc('incident-response-sla').collection('versions').doc('v1').get();
  assert.equal(version.data().definition.timeZone, 'Africa/Kinshasa');
  assert.equal((await db.collection('itsmCommandReceipts').get()).size, 1);
  assert.equal((await db.collection('itsmAuditEvents').get()).size, 1);
});

async function invoke(functionName, data, idToken) {
  const response = await fetch(
    `http://${functionsHost}/${projectId}/us-central1/${functionName}`,
    {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        ...(idToken ? {authorization: `Bearer ${idToken}`} : {}),
      },
      body: JSON.stringify({data}),
    },
  );
  const body = await response.json();
  assert.ok(body.result || body.error, JSON.stringify(body));
  return body;
}

async function createAccount(email) {
  const response = await fetch(
    `http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake`,
    {
      method: 'POST',
      headers: {'content-type': 'application/json'},
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

function seedAgent(uid, email, role) {
  return db.collection('agents').doc(uid).set({
    firstName: role,
    name: 'Reporting Callable',
    email,
    emailLower: email,
    isActive: true,
    modulePermissions: {ticketing: role},
  });
}

async function clearFirestore() {
  const response = await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/` +
      `${projectId}/databases/(default)/documents`,
    {method: 'DELETE'},
  );
  assert.equal(response.ok, true, await response.text());
}

async function clearAuth() {
  const response = await fetch(
    `http://${authHost}/emulator/v1/projects/${projectId}/accounts`,
    {method: 'DELETE'},
  );
  assert.equal(response.ok, true, await response.text());
}
