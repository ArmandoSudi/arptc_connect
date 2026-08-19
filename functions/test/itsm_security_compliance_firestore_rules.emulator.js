'use strict';

const fs = require('node:fs');
const path = require('node:path');
const { after, before, beforeEach, test } = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  collection,
  collectionGroup,
  deleteDoc,
  doc,
  documentId,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  setDoc,
  updateDoc,
  where,
} = require('firebase/firestore');

const projectId = 'demo-arptc-connect-itsm';
const rules = fs.readFileSync(
  path.resolve(__dirname, '../../firestore.rules'),
  'utf8',
);

let environment;

before(async () => {
  environment = await initializeTestEnvironment({
    projectId,
    firestore: { rules },
  });
});

beforeEach(async () => {
  await environment.clearFirestore();
  await environment.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    await Promise.all([
      setDoc(doc(firestore, 'agents/user-1'), agent('USER')),
      setDoc(doc(firestore, 'agents/user-2'), agent('USER')),
      setDoc(doc(firestore, 'agents/manager-1'), agent('MANAGER')),
      setDoc(doc(firestore, 'agents/manager-2'), agent('MANAGER')),
      setDoc(doc(firestore, 'agents/admin-1'), agent('ADMIN')),
      setDoc(doc(firestore, 'securityFindings/internal'), finding('internal')),
      setDoc(
        doc(firestore, 'securityFindings/restricted-authorized'),
        finding('restricted', ['manager-1']),
      ),
      setDoc(
        doc(firestore, 'securityFindings/restricted-other'),
        finding('restricted', ['manager-2']),
      ),
      setDoc(
        doc(firestore, 'securityExceptions/own'),
        securityException('user-1'),
      ),
      setDoc(
        doc(firestore, 'securityExceptions/other'),
        securityException('user-2'),
      ),
      setDoc(
        doc(firestore, 'securityExceptions/admin-own'),
        securityException('admin-1'),
      ),
      setDoc(
        doc(firestore, 'securityExceptions/own-restricted'),
        securityException('user-1', 'restricted', {
          authorizedManagerIds: ['manager-1'],
        }),
      ),
      setDoc(
        doc(firestore, 'assetComplianceAssessments/assessment-1'),
        assessment('user-1'),
      ),
      setDoc(
        doc(firestore, 'assetComplianceSelfService/user-device'),
        complianceProjection('user-1'),
      ),
      setDoc(
        doc(firestore, 'assetComplianceSelfService/other-device'),
        complianceProjection('user-2'),
      ),
      setDoc(
        doc(firestore, 'assetComplianceSelfService/admin-device'),
        complianceProjection('admin-1'),
      ),
      setDoc(
        doc(firestore, 'accessReviewCampaigns/campaign-1'),
        campaign(),
      ),
      setDoc(
        doc(firestore, 'accessReviewItems/own'),
        accessItem('user-1'),
      ),
      setDoc(
        doc(firestore, 'accessReviewItems/other'),
        accessItem('user-2'),
      ),
      setDoc(
        doc(firestore, 'accessReviewItems/admin-own'),
        accessItem('admin-1'),
      ),
      setDoc(
        doc(firestore, 'securityFindings/internal/attachments/internal-evidence'),
        evidence('internal'),
      ),
      setDoc(
        doc(
          firestore,
          'securityFindings/restricted-authorized/attachments/authorized',
        ),
        evidence('restricted', ['manager-1']),
      ),
      setDoc(
        doc(
          firestore,
          'securityFindings/restricted-authorized/attachments/other',
        ),
        evidence('restricted', ['manager-2']),
      ),
      setDoc(
        doc(firestore, 'securityFindings/internal/auditLogs/audit-1'),
        audit(),
      ),
      setDoc(
        doc(firestore, 'securityExceptions/own/attachments/internal-evidence'),
        evidence('internal'),
      ),
      setDoc(
        doc(
          firestore,
          'securityExceptions/own-restricted/comments/requester-visible',
        ),
        requesterVisibleChild(),
      ),
      setDoc(
        doc(firestore, 'securityExceptions/own-restricted/comments/internal'),
        internalChild(),
      ),
      setDoc(
        doc(
          firestore,
          'securityExceptions/own-restricted/attachments/requester-visible',
        ),
        requesterVisibleChild(),
      ),
      setDoc(
        doc(
          firestore,
          'securityExceptions/own-restricted/attachments/restricted',
        ),
        restrictedChild(['manager-1']),
      ),
      setDoc(
        doc(
          firestore,
          'securityExceptions/own-restricted/auditLogs/requester-visible',
        ),
        requesterVisibleChild(),
      ),
      setDoc(
        doc(firestore, 'securityExceptions/own/approvals/approval-1'),
        { status: 'pending', requestedAt: date(2) },
      ),
      setDoc(
        doc(
          firestore,
          'securityExceptions/own/approvals/approval-1/history/history-1',
        ),
        { decision: 'approved', occurredAt: date(3) },
      ),
      setDoc(
        doc(firestore, 'assetComplianceAssessments/assessment-1/attachments/e-1'),
        evidence('restricted', ['manager-1']),
      ),
      setDoc(
        doc(firestore, 'accessReviewItems/own/attachments/e-1'),
        evidence('restricted', ['manager-1']),
      ),
      setDoc(
        doc(firestore, 'accessReviewItems/own/correctionRequests/request-1'),
        correctionRequest('user-1'),
      ),
      setDoc(
        doc(firestore, 'accessReviewItems/own/correctionRequests/request-2'),
        correctionRequest('user-2'),
      ),
      setDoc(
        doc(firestore, 'accessReviewItems/own/revocationTasks/task-1'),
        { status: 'pending', assignedToUserId: 'manager-1' },
      ),
    ]);
  });
});

after(async () => {
  await environment.cleanup();
});

test('findings are MANAGER-only and restricted evidence needs an explicit grant', async () => {
  for (const uid of ['user-1', 'admin-1']) {
    const firestore = firestoreFor(uid);
    await assertFails(getDoc(doc(firestore, 'securityFindings/internal')));
    await assertFails(getDoc(
      doc(firestore, 'securityFindings/restricted-authorized'),
    ));
  }

  const authorized = firestoreFor('manager-1');
  await assertSucceeds(getDoc(doc(authorized, 'securityFindings/internal')));
  await assertSucceeds(getDoc(
    doc(authorized, 'securityFindings/restricted-authorized'),
  ));
  await assertSucceeds(getDoc(
    doc(authorized, 'securityFindings/restricted-other'),
  ));

  const otherManager = firestoreFor('manager-2');
  await assertSucceeds(getDoc(
    doc(otherManager, 'securityFindings/restricted-authorized'),
  ));
});

test('finding queries are bounded and prove confidentiality or authorization', async () => {
  const manager = firestoreFor('manager-1');
  const status = await assertSucceeds(getDocs(query(
    collection(manager, 'securityFindings'),
    where('status', '==', 'triaged'),
    orderBy('updatedAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(25),
  )));
  if (status.size !== 3) {
    throw new Error('Status-filtered finding query is incomplete.');
  }

  const severity = await assertSucceeds(getDocs(query(
    collection(manager, 'securityFindings'),
    where('severity', '==', 'high'),
    orderBy('updatedAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(25),
  )));
  if (severity.size !== 3) {
    throw new Error('Severity-filtered finding query is incomplete.');
  }

  await assertSucceeds(getDocs(query(
    collection(manager, 'securityFindings'),
    orderBy('updatedAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(101),
  )));
  await assertFails(getDocs(query(
    collection(manager, 'securityFindings'),
    orderBy('updatedAt', 'desc'),
    orderBy(documentId(), 'desc'),
  )));
  await assertFails(getDocs(query(
    collection(manager, 'securityFindings'),
    orderBy('updatedAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(102),
  )));
});

test('exceptions are requester-scoped for USER and ADMIN, operational for MANAGER', async () => {
  const user = firestoreFor('user-1');
  await assertSucceeds(getDoc(doc(user, 'securityExceptions/own')));
  await assertFails(getDoc(doc(user, 'securityExceptions/other')));
  await assertSucceeds(getDoc(
    doc(user, 'securityExceptions/own-restricted'),
  ));

  const admin = firestoreFor('admin-1');
  await assertSucceeds(getDoc(doc(admin, 'securityExceptions/admin-own')));
  await assertFails(getDoc(doc(admin, 'securityExceptions/own')));

  const own = await assertSucceeds(getDocs(query(
    collection(user, 'securityExceptions'),
    where('requester.userId', '==', 'user-1'),
    where('selfServiceVisible', '==', true),
    orderBy('updatedAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(25),
  )));
  if (own.size !== 2) {
    throw new Error('Exception query escaped requester isolation.');
  }
  await assertFails(getDocs(query(
    collection(user, 'securityExceptions'),
    where('requester.userId', '==', 'user-1'),
    where('selfServiceVisible', '==', true),
    orderBy('updatedAt', 'desc'),
    orderBy(documentId(), 'desc'),
  )));

  const manager = firestoreFor('manager-1');
  const all = await assertSucceeds(getDocs(query(
    collection(manager, 'securityExceptions'),
    limit(25),
  )));
  if (all.size !== 4) throw new Error('MANAGER exception queue is incomplete.');
});

test('exception comments and attachments preserve requester visibility', async () => {
  const user = firestoreFor('user-1');
  await assertSucceeds(getDoc(doc(
    user,
    'securityExceptions/own-restricted/comments/requester-visible',
  )));
  await assertFails(getDoc(doc(
    user,
    'securityExceptions/own-restricted/comments/internal',
  )));
  await assertSucceeds(getDoc(doc(
    user,
    'securityExceptions/own-restricted/attachments/requester-visible',
  )));
  await assertFails(getDoc(doc(
    user,
    'securityExceptions/own-restricted/attachments/restricted',
  )));
  await assertSucceeds(getDoc(doc(
    user,
    'securityExceptions/own-restricted/auditLogs/requester-visible',
  )));
  await assertFails(getDoc(doc(
    firestoreFor('user-2'),
    'securityExceptions/own-restricted/comments/requester-visible',
  )));

  const manager = firestoreFor('manager-1');
  await assertSucceeds(getDoc(doc(
    manager,
    'securityExceptions/own-restricted/comments/internal',
  )));
  await assertSucceeds(getDoc(doc(
    manager,
    'securityExceptions/own-restricted/attachments/restricted',
  )));
  await assertFails(updateDoc(
    doc(
      manager,
      'securityExceptions/own-restricted/attachments/requester-visible',
    ),
    { requesterVisible: false },
  ));
});

test('all governed parent records are trusted-write only', async () => {
  const creates = [
    ['securityFindings/forged', finding('internal')],
    ['securityExceptions/forged', securityException('user-1')],
    ['assetComplianceAssessments/forged', assessment('user-1')],
    ['assetComplianceSelfService/forged', complianceProjection('user-1')],
    ['accessReviewCampaigns/forged', campaign()],
    ['accessReviewItems/forged', accessItem('user-1')],
  ];
  for (const uid of ['user-1', 'manager-1', 'admin-1']) {
    const firestore = firestoreFor(uid);
    for (const [documentPath, data] of creates) {
      await assertFails(setDoc(doc(firestore, documentPath), data));
    }
    await assertFails(updateDoc(
      doc(firestore, 'securityExceptions/own'),
      { status: 'approved' },
    ));
    await assertFails(deleteDoc(doc(firestore, 'accessReviewItems/own')));
  }
});

test('evidence, approvals, audit and unknown subpaths are immutable and confidential', async () => {
  const user = firestoreFor('user-1');
  await assertFails(getDoc(
    doc(user, 'securityFindings/internal/attachments/internal-evidence'),
  ));
  await assertFails(getDoc(
    doc(user, 'securityExceptions/own/attachments/internal-evidence'),
  ));
  await assertFails(getDoc(
    doc(user, 'securityExceptions/own/approvals/approval-1'),
  ));

  const manager = firestoreFor('manager-1');
  await assertSucceeds(getDoc(
    doc(manager, 'securityFindings/internal/attachments/internal-evidence'),
  ));
  await assertSucceeds(getDoc(
    doc(
      manager,
      'securityFindings/restricted-authorized/attachments/authorized',
    ),
  ));
  await assertFails(getDoc(
    doc(manager, 'securityFindings/restricted-authorized/attachments/other'),
  ));
  await assertSucceeds(getDoc(
    doc(manager, 'securityFindings/internal/auditLogs/audit-1'),
  ));
  await assertSucceeds(getDoc(
    doc(manager, 'securityExceptions/own/approvals/approval-1'),
  ));
  await assertSucceeds(getDoc(doc(
    manager,
    'securityExceptions/own/approvals/approval-1/history/history-1',
  )));

  await assertFails(updateDoc(
    doc(manager, 'securityFindings/internal/auditLogs/audit-1'),
    { action: 'tampered' },
  ));
  await assertFails(setDoc(
    doc(manager, 'securityExceptions/own/approvals/forged'),
    { status: 'approved' },
  ));
  await assertFails(getDoc(
    doc(manager, 'securityFindings/internal/privateNotes/note-1'),
  ));
});

test('raw compliance is MANAGER-only and safe projections are USER-owner scoped', async () => {
  const user = firestoreFor('user-1');
  await assertFails(getDoc(
    doc(user, 'assetComplianceAssessments/assessment-1'),
  ));
  await assertSucceeds(getDoc(
    doc(user, 'assetComplianceSelfService/user-device'),
  ));
  await assertFails(getDoc(
    doc(user, 'assetComplianceSelfService/other-device'),
  ));

  const projection = await assertSucceeds(getDocs(query(
    collection(user, 'assetComplianceSelfService'),
    where('assignedUserId', '==', 'user-1'),
    orderBy('updatedAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(25),
  )));
  if (projection.size !== 1 || projection.docs[0].id !== 'user-device') {
    throw new Error('Compliance projection escaped assigned-user isolation.');
  }

  const admin = firestoreFor('admin-1');
  await assertFails(getDoc(
    doc(admin, 'assetComplianceSelfService/admin-device'),
  ));

  const manager = firestoreFor('manager-1');
  await assertSucceeds(getDoc(
    doc(manager, 'assetComplianceAssessments/assessment-1'),
  ));
  await assertSucceeds(getDoc(
    doc(manager, 'assetComplianceSelfService/other-device'),
  ));
  await assertSucceeds(getDoc(
    doc(manager, 'assetComplianceAssessments/assessment-1/attachments/e-1'),
  ));
  await assertFails(getDocs(collection(manager, 'assetComplianceAssessments')));
});

test('access reviews isolate subjects while campaigns and operations remain MANAGER-only', async () => {
  const user = firestoreFor('user-1');
  await assertFails(getDoc(doc(user, 'accessReviewCampaigns/campaign-1')));
  await assertSucceeds(getDoc(doc(user, 'accessReviewItems/own')));
  await assertFails(getDoc(doc(user, 'accessReviewItems/other')));

  const own = await assertSucceeds(getDocs(query(
    collection(user, 'accessReviewItems'),
    where('subjectUser.userId', '==', 'user-1'),
    where('selfServiceVisible', '==', true),
    orderBy('updatedAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(25),
  )));
  if (own.size !== 1 || own.docs[0].id !== 'own') {
    throw new Error('Access-review query escaped subject isolation.');
  }

  const admin = firestoreFor('admin-1');
  await assertSucceeds(getDoc(doc(admin, 'accessReviewItems/admin-own')));
  await assertFails(getDoc(doc(admin, 'accessReviewItems/own')));

  const manager = firestoreFor('manager-1');
  await assertSucceeds(getDoc(doc(manager, 'accessReviewCampaigns/campaign-1')));
  await assertSucceeds(getDoc(doc(manager, 'accessReviewItems/other')));
  await assertFails(getDocs(collection(manager, 'accessReviewItems')));
});

test('access evidence is restricted and correction requests are requester-readable only', async () => {
  const user = firestoreFor('user-1');
  await assertFails(getDoc(
    doc(user, 'accessReviewItems/own/attachments/e-1'),
  ));
  await assertSucceeds(getDoc(
    doc(user, 'accessReviewItems/own/correctionRequests/request-1'),
  ));
  await assertFails(getDoc(
    doc(user, 'accessReviewItems/own/correctionRequests/request-2'),
  ));
  await assertFails(getDoc(
    doc(user, 'accessReviewItems/own/revocationTasks/task-1'),
  ));

  const manager = firestoreFor('manager-1');
  await assertSucceeds(getDoc(
    doc(manager, 'accessReviewItems/own/attachments/e-1'),
  ));
  await assertSucceeds(getDoc(
    doc(manager, 'accessReviewItems/own/correctionRequests/request-2'),
  ));
  await assertSucceeds(getDoc(
    doc(manager, 'accessReviewItems/own/revocationTasks/task-1'),
  ));
  await assertFails(setDoc(
    doc(manager, 'accessReviewItems/own/revocationTasks/forged'),
    { status: 'completed' },
  ));
});

test('all repository filter shapes use updatedAt pagination and remain authorized', async () => {
  const manager = firestoreFor('manager-1');
  const managerShapes = [
    query(
      collection(manager, 'securityExceptions'),
      where('status', '==', 'submitted'),
      orderBy('updatedAt', 'desc'),
      orderBy(documentId(), 'desc'),
      limit(25),
    ),
    query(
      collection(manager, 'securityExceptions'),
      where('affectedServiceId', '==', 'service-1'),
      orderBy('updatedAt', 'desc'),
      orderBy(documentId(), 'desc'),
      limit(25),
    ),
    query(
      collection(manager, 'assetComplianceAssessments'),
      where('result', '==', 'action_required'),
      orderBy('updatedAt', 'desc'),
      orderBy(documentId(), 'desc'),
      limit(25),
    ),
    query(
      collection(manager, 'assetComplianceAssessments'),
      where('assignedUserId', '==', 'user-1'),
      orderBy('updatedAt', 'desc'),
      orderBy(documentId(), 'desc'),
      limit(25),
    ),
    query(
      collection(manager, 'accessReviewCampaigns'),
      where('status', '==', 'active'),
      orderBy('updatedAt', 'desc'),
      orderBy(documentId(), 'desc'),
      limit(25),
    ),
    query(
      collection(manager, 'accessReviewItems'),
      where('completionStatus', '==', 'pending'),
      orderBy('updatedAt', 'desc'),
      orderBy(documentId(), 'desc'),
      limit(25),
    ),
    query(
      collection(manager, 'accessReviewItems'),
      where('campaignId', '==', 'campaign-1'),
      orderBy('updatedAt', 'desc'),
      orderBy(documentId(), 'desc'),
      limit(25),
    ),
  ];
  for (const repositoryQuery of managerShapes) {
    await assertSucceeds(getDocs(repositoryQuery));
  }

  const user = firestoreFor('user-1');
  const selfServiceShapes = [
    query(
      collection(user, 'securityExceptions'),
      where('requester.userId', '==', 'user-1'),
      where('selfServiceVisible', '==', true),
      where('status', '==', 'submitted'),
      orderBy('updatedAt', 'desc'),
      orderBy(documentId(), 'desc'),
      limit(25),
    ),
    query(
      collection(user, 'securityExceptions'),
      where('requester.userId', '==', 'user-1'),
      where('selfServiceVisible', '==', true),
      where('affectedServiceId', '==', 'service-1'),
      orderBy('updatedAt', 'desc'),
      orderBy(documentId(), 'desc'),
      limit(25),
    ),
    query(
      collection(user, 'accessReviewItems'),
      where('subjectUser.userId', '==', 'user-1'),
      where('selfServiceVisible', '==', true),
      where('completionStatus', '==', 'pending'),
      orderBy('updatedAt', 'desc'),
      orderBy(documentId(), 'desc'),
      limit(25),
    ),
    query(
      collection(user, 'accessReviewItems'),
      where('subjectUser.userId', '==', 'user-1'),
      where('selfServiceVisible', '==', true),
      where('campaignId', '==', 'campaign-1'),
      orderBy('updatedAt', 'desc'),
      orderBy(documentId(), 'desc'),
      limit(25),
    ),
  ];
  for (const repositoryQuery of selfServiceShapes) {
    await assertSucceeds(getDocs(repositoryQuery));
  }

  const corrections = await assertSucceeds(getDocs(query(
    collectionGroup(user, 'correctionRequests'),
    where('requestedBy', '==', 'user-1'),
    orderBy('createdAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(25),
  )));
  if (corrections.size !== 1) {
    throw new Error('Correction request collection-group escaped ownership.');
  }
});

function firestoreFor(uid) {
  return environment
    .authenticatedContext(uid, {
      email: `${uid}@arptc.cd`,
      email_verified: true,
    })
    .firestore();
}

function agent(role) {
  return {
    email: `${role.toLowerCase()}@arptc.cd`,
    isActive: true,
    modulePermissions: { ticketing: role },
  };
}

function finding(confidentiality, authorizedManagerIds = []) {
  return {
    reference: 'SEC-1',
    title: 'Finding',
    confidentiality,
    authorizedManagerIds,
    status: 'triaged',
    severity: 'high',
    updatedAt: date(5),
  };
}

function securityException(
  requesterId,
  confidentiality = 'internal',
  overrides = {},
) {
  return {
    reference: 'EXC-1',
    title: 'Exception',
    requester: actor(requesterId),
    status: 'submitted',
    affectedServiceId: 'service-1',
    selfServiceVisible: true,
    confidentiality,
    reviewAt: date(20),
    updatedAt: date(5),
    ...overrides,
  };
}

function assessment(assignedUserId) {
  return {
    assetId: 'asset-1',
    assignedUserId,
    result: 'action_required',
    updatedAt: date(5),
  };
}

function complianceProjection(assignedUserId) {
  return {
    assetId: `asset-${assignedUserId}`,
    assetTag: `TAG-${assignedUserId}`,
    assetName: 'Laptop',
    assignedUserId,
    status: 'action_required',
    assessedAt: date(4),
    updatedAt: date(5),
  };
}

function campaign() {
  return {
    reference: 'AR-1',
    title: 'Quarterly review',
    status: 'active',
    dueAt: date(20),
    updatedAt: date(5),
  };
}

function accessItem(subjectUserId) {
  return {
    campaignId: 'campaign-1',
    subjectUser: actor(subjectUserId),
    reviewer: actor('manager-1'),
    selfServiceVisible: true,
    completionStatus: 'pending',
    dueAt: date(20),
    updatedAt: date(5),
  };
}

function evidence(confidentiality, authorizedManagerIds = []) {
  return {
    confidentiality,
    authorizedManagerIds,
    createdAt: date(3),
    createdBy: 'manager-1',
  };
}

function correctionRequest(requestedBy) {
  return {
    accessReviewItemId: 'own',
    requestedBy,
    type: 'correction',
    reason: 'Incorrect access',
    status: 'submitted',
    createdAt: date(6),
  };
}

function audit() {
  return { action: 'created', actorUserId: 'manager-1', occurredAt: date(1) };
}

function requesterVisibleChild() {
  return {
    confidentiality: 'internal',
    requesterVisible: true,
    isInternal: false,
    createdAt: date(3),
  };
}

function internalChild() {
  return {
    confidentiality: 'internal',
    requesterVisible: false,
    isInternal: true,
    createdAt: date(3),
  };
}

function restrictedChild(authorizedManagerIds) {
  return {
    confidentiality: 'restricted',
    authorizedManagerIds,
    requesterVisible: false,
    isInternal: true,
    createdAt: date(3),
  };
}

function actor(userId) {
  return { userId, displayName: userId, email: `${userId}@arptc.cd` };
}

function date(day) {
  return new Date(Date.UTC(2026, 6, day, 8));
}
