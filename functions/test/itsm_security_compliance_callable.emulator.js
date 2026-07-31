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

test('finding callable enforces authentication and role, then replays safely', async () => {
  const manager = await createAccount('security-manager@example.test');
  const user = await createAccount('security-user@example.test');
  const administrator = await createAccount('security-admin@example.test');
  await Promise.all([
    seedAgent(manager.localId, manager.email, 'MANAGER'),
    seedAgent(user.localId, user.email, 'USER'),
    seedAgent(administrator.localId, administrator.email, 'ADMIN'),
  ]);

  const command = {
    command: 'security.finding.create',
    idempotencyKey: 'callable-security-finding-001',
    payload: {
      findingId: 'callable-finding-1',
      title: 'Unsupported endpoint operating system',
      description: 'An assigned endpoint is outside its support lifecycle.',
      source: 'Callable emulator assessment',
      severity: 'high',
      risk: 'high',
      confidentiality: 'restricted',
      affectedAssetIds: ['asset-callable-1'],
      affectedCiIds: [],
      affectedServiceIds: ['endpoint-management'],
      dueAt: '2026-08-31T17:00:00Z',
    },
  };

  const unauthenticated = await invokeCallable(
    'itsmCreateSecurityFinding',
    command,
  );
  assert.equal(unauthenticated.error.status, 'UNAUTHENTICATED');

  for (const account of [user, administrator]) {
    const denied = await invokeCallable(
      'itsmCreateSecurityFinding',
      command,
      account.idToken,
    );
    assert.equal(denied.error.status, 'PERMISSION_DENIED');
  }

  const created = await invokeCallable(
    'itsmCreateSecurityFinding',
    command,
    manager.idToken,
  );
  assert.equal(created.result.findingId, 'callable-finding-1');
  assert.equal(created.result.status, 'detected');
  assert.equal(created.result.revision, 0);

  const replayed = await invokeCallable(
    'itsmCreateSecurityFinding',
    command,
    manager.idToken,
  );
  assert.deepEqual(replayed.result, created.result);

  const [finding, receipts, auditEvents] = await Promise.all([
    db.collection('securityFindings').doc('callable-finding-1').get(),
    db.collection('itsmCommandReceipts').get(),
    db.collection('itsmAuditEvents').get(),
  ]);
  assert.equal(finding.exists, true);
  assert.equal(finding.data().createdByUserId, manager.localId);
  assert.equal(finding.data().confidentiality, 'restricted');
  assert.equal(receipts.size, 1);
  assert.equal(auditEvents.size, 1);
});

test('USER and ADMIN can submit owned exceptions while self-approval is denied', async () => {
  const user = await createAccount('exception-user@example.test');
  const administrator = await createAccount('exception-admin@example.test');
  const manager = await createAccount('exception-manager@example.test');
  await Promise.all([
    seedAgent(user.localId, user.email, 'USER'),
    seedAgent(administrator.localId, administrator.email, 'ADMIN'),
    seedAgent(manager.localId, manager.email, 'MANAGER'),
  ]);

  for (const [account, exceptionId] of [
    [user, 'callable-user-exception'],
    [administrator, 'callable-admin-exception'],
  ]) {
    const created = await invokeCallable(
      'itsmCreateSecurityException',
      exceptionCommand(exceptionId, `create-${exceptionId}`),
      account.idToken,
    );
    assert.equal(created.result.status, 'draft');

    const submitted = await invokeCallable(
      'itsmSubmitSecurityException',
      {
        command: 'security.exception.submit',
        idempotencyKey: `submit-${exceptionId}`,
        payload: { exceptionId, expectedRevision: 0 },
      },
      account.idToken,
    );
    assert.equal(submitted.result.status, 'submitted');

    const document = await db.collection('securityExceptions').doc(exceptionId).get();
    assert.equal(document.data().requesterId, account.localId);
    assert.equal(document.data().requester.userId, account.localId);
    assert.equal(document.data().selfServiceVisible, true);
    assert.equal(document.data().revision, 1);
  }

  await invokeCallable(
    'itsmCreateSecurityException',
    exceptionCommand('callable-manager-exception', 'create-manager-exception'),
    manager.idToken,
  );
  await invokeCallable(
    'itsmSubmitSecurityException',
    {
      command: 'security.exception.submit',
      idempotencyKey: 'submit-manager-exception',
      payload: {
        exceptionId: 'callable-manager-exception',
        expectedRevision: 0,
      },
    },
    manager.idToken,
  );

  const selfApproval = await invokeCallable(
    'itsmRequestSecurityExceptionApproval',
    {
      command: 'security.exception.approval.request',
      idempotencyKey: 'request-manager-self-approval',
      payload: {
        exceptionId: 'callable-manager-exception',
        expectedRevision: 1,
        approvalId: 'callable-self-approval',
        approverUserIds: [manager.localId],
      },
    },
    manager.idToken,
  );
  assert.equal(selfApproval.error.status, 'FAILED_PRECONDITION');
  assert.match(selfApproval.error.message, /requester/i);

  const managerException = await db
    .collection('securityExceptions')
    .doc('callable-manager-exception')
    .get();
  assert.equal(managerException.data().status, 'submitted');
  assert.equal(managerException.data().revision, 1);
  assert.equal(
    (await managerException.ref.collection('approvals').get()).size,
    0,
  );
});

test('access correction callable permits only the access subject', async () => {
  const subject = await createAccount('review-subject@example.test');
  const otherUser = await createAccount('review-other@example.test');
  const administrator = await createAccount('review-admin@example.test');
  await Promise.all([
    seedAgent(subject.localId, subject.email, 'USER'),
    seedAgent(otherUser.localId, otherUser.email, 'USER'),
    seedAgent(administrator.localId, administrator.email, 'ADMIN'),
  ]);
  await seedAccessReview(subject);

  const command = {
    command: 'security.access_review.correction.request',
    idempotencyKey: 'callable-access-correction-001',
    payload: {
      itemId: 'callable-review-item',
      type: 'revocation',
      reason: 'This access is no longer required for my responsibilities.',
    },
  };

  for (const account of [otherUser, administrator]) {
    const denied = await invokeCallable(
      'itsmRequestAccessCorrection',
      command,
      account.idToken,
    );
    assert.equal(denied.error.status, 'PERMISSION_DENIED');
  }

  const submitted = await invokeCallable(
    'itsmRequestAccessCorrection',
    command,
    subject.idToken,
  );
  assert.equal(submitted.result.itemId, 'callable-review-item');
  assert.equal(submitted.result.status, 'submitted');

  const requests = await db
    .collection('accessReviewItems')
    .doc('callable-review-item')
    .collection('correctionRequests')
    .get();
  assert.equal(requests.size, 1);
  assert.equal(requests.docs[0].data().requestedBy, subject.localId);
  assert.equal(requests.docs[0].data().requesterId, subject.localId);
  assert.equal(requests.docs[0].data().subjectUser.userId, subject.localId);
  assert.equal(requests.docs[0].data().selfServiceVisible, true);
});

function exceptionCommand(exceptionId, idempotencyKey) {
  return {
    command: 'security.exception.create',
    idempotencyKey,
    payload: {
      exceptionId,
      title: 'Temporary security control exception',
      requirementOrControl: 'Multi-factor authentication requirement',
      businessJustification: 'A legacy integration requires a controlled transition.',
      scope: 'Legacy reporting integration',
      riskDescription: 'Authentication assurance is temporarily reduced.',
      compensatingControls: [
        {
          id: 'control-monitoring',
          description: 'Review authentication logs every business day.',
          effective: true,
        },
      ],
      requestedStartAt: '2026-08-05T08:00:00Z',
      requestedEndAt: '2026-09-05T17:00:00Z',
      reviewAt: '2026-08-20T12:00:00Z',
      confidentiality: 'confidential',
    },
  };
}

async function seedAccessReview(subject) {
  await Promise.all([
    db.collection('accessReviewCampaigns').doc('callable-review-campaign').set({
      id: 'callable-review-campaign',
      status: 'active',
      allowSelfServiceCorrection: true,
      revision: 1,
    }),
    db.collection('accessReviewItems').doc('callable-review-item').set({
      id: 'callable-review-item',
      campaignId: 'callable-review-campaign',
      subjectUserId: subject.localId,
      subjectUser: {
        userId: subject.localId,
        name: 'Review Subject',
        email: subject.email,
      },
      selfServiceVisible: true,
      status: 'pending',
      lifecycleState: 'active',
      revision: 0,
    }),
  ]);
}

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
    firstName: role === 'MANAGER' ? 'Manager' : 'Agent',
    name: 'Security Callable',
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
