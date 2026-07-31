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

test('exported callable authenticates, authorizes, persists, and replays safely', async () => {
  const manager = await createAccount('manager@example.test');
  const user = await createAccount('user@example.test');
  await Promise.all([
    seedAgent(manager.localId, manager.email, 'MANAGER'),
    seedAgent(user.localId, user.email, 'USER'),
  ]);

  const command = {
    command: 'asset.register',
    idempotencyKey: 'callable-register-asset-001',
    payload: {
      assetId: 'callable-asset-1',
      assetTag: 'ARPTC-CALLABLE-001',
      categoryId: 'computer',
      categoryName: 'Computer',
      type: 'laptop',
      status: 'planned',
    },
  };

  const unauthenticated = await invokeCallable('itsmRegisterAsset', command);
  assert.equal(unauthenticated.error.status, 'UNAUTHENTICATED');

  const denied = await invokeCallable(
    'itsmRegisterAsset',
    command,
    user.idToken,
  );
  assert.equal(denied.error.status, 'PERMISSION_DENIED');

  const created = await invokeCallable(
    'itsmRegisterAsset',
    command,
    manager.idToken,
  );
  assert.equal(created.result.assetId, 'callable-asset-1');

  const replayed = await invokeCallable(
    'itsmRegisterAsset',
    command,
    manager.idToken,
  );
  assert.deepEqual(replayed.result, created.result);

  const asset = await db.collection('assets').doc('callable-asset-1').get();
  assert.equal(asset.exists, true);
  assert.equal(asset.data().assetTag, 'ARPTC-CALLABLE-001');
  assert.equal(asset.data().createdBy, manager.localId);
  const receipts = await db.collection('itsmCommandReceipts').get();
  assert.equal(receipts.size, 1);
});

test('exported stock configuration callables persist canonical records', async () => {
  const manager = await createAccount('stock-manager@example.test');
  await seedAgent(manager.localId, manager.email, 'MANAGER');

  const location = await invokeCallable(
    'itsmSaveStockLocation',
    {
      command: 'stock.location.save',
      idempotencyKey: 'callable-stock-location-001',
      payload: {
        id: 'callable-main-store',
        name: 'Main store',
        siteId: 'kinshasa-hq',
        siteName: 'Kinshasa HQ',
        isActive: true,
      },
    },
    manager.idToken,
  );
  assert.equal(location.result.id, 'callable-main-store');

  const item = await invokeCallable(
    'itsmSaveStockItem',
    {
      command: 'stock.item.save',
      idempotencyKey: 'callable-stock-item-001',
      payload: {
        id: 'callable-network-cable',
        sku: 'CAB-CALLABLE-001',
        name: 'Network cable',
        kind: 'consumable',
        barcode: '620000000001',
        unitOfMeasure: 'piece',
        minimumQuantity: 5,
        isActive: true,
      },
    },
    manager.idToken,
  );
  assert.equal(item.result.id, 'callable-network-cable');

  const [locationDocument, itemDocument, receipts] = await Promise.all([
    db.collection('stockLocations').doc('callable-main-store').get(),
    db.collection('stockItems').doc('callable-network-cable').get(),
    db.collection('itsmCommandReceipts').get(),
  ]);
  assert.equal(locationDocument.data().name, 'Main store');
  assert.equal(itemDocument.data().barcode, '620000000001');
  assert.equal(itemDocument.data().availableQuantity, 0);
  assert.equal(receipts.size, 2);
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
    firstName: role === 'MANAGER' ? 'Manager' : 'User',
    name: 'Callable',
    email,
    emailLower: email,
    isActive: true,
    modulePermissions: { ticketing: role },
  });
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
