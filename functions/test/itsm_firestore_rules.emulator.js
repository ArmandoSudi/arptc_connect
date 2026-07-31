const fs = require('node:fs');
const path = require('node:path');
const { after, before, beforeEach, test } = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  Timestamp,
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} = require('firebase/firestore');

const projectId = 'demo-arptc-connect-itsm-security';
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
      setDoc(
        doc(firestore, 'agents/user-1'),
        agent('USER', { support: 'MANAGER' }),
      ),
      setDoc(doc(firestore, 'agents/user-2'), agent('USER')),
      setDoc(doc(firestore, 'agents/manager-1'), agent('MANAGER')),
      setDoc(
        doc(firestore, 'agents/manager-alias'),
        aliasAgent('support', 'MANAGER'),
      ),
      setDoc(doc(firestore, 'agents/admin-1'), agent('ADMIN')),
      setDoc(doc(firestore, 'agents/none-1'), agent('NONE')),
      setDoc(
        doc(firestore, 'itsmWorkItemIndex/own-summary'),
        workItem({ requesterId: 'user-1' }),
      ),
      setDoc(
        doc(firestore, 'itsmWorkItemIndex/other-summary'),
        workItem({ requesterId: 'user-2' }),
      ),
      setDoc(
        doc(firestore, 'itsmWorkItemIndex/restricted-summary'),
        workItem({
          requesterId: 'user-2',
          confidentiality: 'RESTRICTED',
          authorizedUserIds: ['manager-1'],
        }),
      ),
      setDoc(
        doc(firestore, 'itsmWorkItemIndex/admin-own-summary'),
        workItem({ requesterId: 'admin-1' }),
      ),
      setDoc(
        doc(firestore, 'serviceRequests/request-1'),
        workItem({ requesterId: 'user-1' }),
      ),
      setDoc(
        doc(firestore, 'serviceRequests/request-2'),
        workItem({ requesterId: 'user-2' }),
      ),
      setDoc(
        doc(firestore, 'serviceRequests/restricted-request'),
        workItem({
          requesterId: 'user-2',
          confidentiality: 'RESTRICTED',
          authorizedUserIds: ['manager-1'],
        }),
      ),
      setDoc(
        doc(firestore, 'serviceRequests/admin-request'),
        workItem({ requesterId: 'admin-1' }),
      ),
      setDoc(
        doc(firestore, 'serviceRequests/request-1/comments/public'),
        comment(false),
      ),
      setDoc(
        doc(firestore, 'serviceRequests/request-1/comments/internal'),
        comment(true),
      ),
      setDoc(
        doc(firestore, 'serviceRequests/request-1/attachments/public'),
        attachment(false),
      ),
      setDoc(
        doc(firestore, 'serviceRequests/request-1/attachments/internal'),
        attachment(true),
      ),
      setDoc(
        doc(firestore, 'serviceRequests/request-1/approvals/approval-1'),
        approval(),
      ),
      setDoc(
        doc(firestore, 'serviceRequests/request-1/auditLogs/audit-1'),
        auditEvent(false),
      ),
      setDoc(
        doc(firestore, 'serviceCatalogItems/published-item'),
        configuration('published'),
      ),
      setDoc(
        doc(firestore, 'serviceCatalogItems/draft-item'),
        configuration('draft'),
      ),
      setDoc(
        doc(firestore, 'workflowDefinitions/published-workflow'),
        configuration('published'),
      ),
      setDoc(
        doc(
          firestore,
          'workflowDefinitions/published-workflow/versions/v1',
        ),
        configuration('published'),
      ),
      setDoc(
        doc(firestore, 'slaPolicies/published-sla'),
        configuration('published'),
      ),
      setDoc(
        doc(firestore, 'itsmReportSnapshots/manager-snapshot'),
        reportSnapshot('MANAGER'),
      ),
      setDoc(
        doc(firestore, 'itsmReportSnapshots/admin-snapshot'),
        reportSnapshot('ADMIN'),
      ),
      setDoc(
        doc(firestore, 'itsmAuditEvents/normal-event'),
        auditEvent(false),
      ),
      setDoc(
        doc(firestore, 'itsmAuditEvents/restricted-event'),
        auditEvent(true, ['manager-1']),
      ),
      setDoc(
        doc(firestore, 'securityFindings/restricted-finding'),
        workItem({
          requesterId: 'user-1',
          confidentiality: 'RESTRICTED',
          authorizedUserIds: ['manager-1'],
        }),
      ),
      setDoc(
        doc(
          firestore,
          'securityFindings/restricted-finding/attachments/evidence',
        ),
        restrictedAttachment(),
      ),
      setDoc(doc(firestore, 'unknownItsmCollection/unknown'), {
        value: 'must remain private',
      }),
    ]);
  });
});

after(async () => {
  await environment.cleanup();
});

test('ticketing is canonical while supported aliases still resolve', async () => {
  const canonicalUser = userFirestore('user-1');
  await assertFails(
    getDoc(doc(canonicalUser, 'itsmWorkItemIndex/other-summary')),
  );

  const aliasManager = userFirestore('manager-alias');
  await assertSucceeds(
    getDoc(doc(aliasManager, 'itsmWorkItemIndex/other-summary')),
  );
});

test('USER reads only owned, non-restricted self-service projections', async () => {
  const firestore = userFirestore('user-1');

  await assertSucceeds(
    getDoc(doc(firestore, 'itsmWorkItemIndex/own-summary')),
  );
  await assertFails(
    getDoc(doc(firestore, 'itsmWorkItemIndex/other-summary')),
  );
  await assertFails(
    getDoc(doc(firestore, 'itsmWorkItemIndex/restricted-summary')),
  );

  const ownQuery = query(
    collection(firestore, 'itsmWorkItemIndex'),
    where('requesterId', '==', 'user-1'),
    where('selfServiceVisible', '==', true),
    where('confidentiality', '==', 'INTERNAL'),
  );
  const result = await assertSucceeds(getDocs(ownQuery));
  if (result.size !== 1 || result.docs[0].id !== 'own-summary') {
    throw new Error('The self-service query escaped its owner boundary.');
  }
  await assertFails(getDocs(collection(firestore, 'itsmWorkItemIndex')));
});

test('ADMIN has owner-scoped self-service reads and read-only reporting', async () => {
  const firestore = userFirestore('admin-1');

  await assertSucceeds(
    getDoc(doc(firestore, 'itsmWorkItemIndex/admin-own-summary')),
  );
  await assertFails(
    getDoc(doc(firestore, 'itsmWorkItemIndex/other-summary')),
  );
  await assertSucceeds(
    getDoc(doc(firestore, 'itsmReportSnapshots/admin-snapshot')),
  );
  await assertFails(
    getDoc(doc(firestore, 'itsmReportSnapshots/manager-snapshot')),
  );
  await assertFails(
    updateDoc(doc(firestore, 'itsmReportSnapshots/admin-snapshot'), {
      total: 999,
    }),
  );
  await assertFails(
    setDoc(doc(firestore, 'serviceCatalogItems/admin-item'), {
      ...configuration('draft'),
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
});

test('MANAGER reads operational records but restricted data needs authorization', async () => {
  const authorized = userFirestore('manager-1');
  await assertSucceeds(
    getDoc(doc(authorized, 'serviceRequests/request-2')),
  );
  await assertSucceeds(
    getDoc(doc(authorized, 'serviceRequests/restricted-request')),
  );
  await assertSucceeds(
    getDoc(doc(authorized, 'securityFindings/restricted-finding')),
  );
  await assertSucceeds(
    getDoc(
      doc(
        authorized,
        'securityFindings/restricted-finding/attachments/evidence',
      ),
    ),
  );
  await assertSucceeds(
    addDoc(
      collection(
        authorized,
        'securityFindings/restricted-finding/attachments',
      ),
      {
        workItemCollection: 'securityFindings',
        workItemId: 'restricted-finding',
        uploadedByUserId: 'manager-1',
        storagePath:
          'itsm/securityFindings/restricted-finding/attachments/new/file.pdf',
        isInternal: true,
        createdAt: serverTimestamp(),
      },
    ),
  );

  const unauthorized = userFirestore('manager-alias');
  await assertFails(
    getDoc(doc(unauthorized, 'serviceRequests/restricted-request')),
  );
  await assertFails(
    getDoc(doc(unauthorized, 'securityFindings/restricted-finding')),
  );
  await assertFails(
    getDoc(
      doc(
        unauthorized,
        'securityFindings/restricted-finding/attachments/evidence',
      ),
    ),
  );
});

test('self-service requests allow safe creates but deny protected fields', async () => {
  const firestore = userFirestore('user-1');

  await assertSucceeds(
    setDoc(doc(firestore, 'serviceRequests/new-request'), {
      requesterId: 'user-1',
      title: 'Access request',
      status: 'submitted',
      confidentiality: 'INTERNAL',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
  await assertFails(
    setDoc(doc(firestore, 'serviceRequests/cross-user-request'), {
      requesterId: 'user-2',
      title: 'Forged request',
      status: 'submitted',
      confidentiality: 'INTERNAL',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
  await assertFails(
    setDoc(doc(firestore, 'serviceRequests/assigned-request'), {
      requesterId: 'user-1',
      assignedUserId: 'manager-1',
      title: 'Forged assignment',
      status: 'submitted',
      confidentiality: 'INTERNAL',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
  await assertFails(
    updateDoc(doc(firestore, 'serviceRequests/request-1'), {
      assignedUserId: 'user-1',
    }),
  );
});

test('MANAGER manages drafts but cannot publish immutable configuration', async () => {
  const firestore = userFirestore('manager-1');
  const draft = doc(firestore, 'serviceCatalogItems/new-draft');

  await assertSucceeds(
    setDoc(draft, {
      name: 'New laptop',
      status: 'draft',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
  await assertSucceeds(
    updateDoc(draft, {
      name: 'Standard laptop',
      updatedAt: serverTimestamp(),
    }),
  );
  await assertFails(
    updateDoc(draft, {
      status: 'published',
      updatedAt: serverTimestamp(),
    }),
  );
  await assertFails(
    updateDoc(doc(firestore, 'serviceCatalogItems/published-item'), {
      name: 'Mutated published item',
      updatedAt: serverTimestamp(),
    }),
  );
});

test('USER reads only published configuration while ADMIN is read-only', async () => {
  const userDb = userFirestore('user-1');
  await assertSucceeds(
    getDoc(doc(userDb, 'serviceCatalogItems/published-item')),
  );
  await assertFails(getDoc(doc(userDb, 'serviceCatalogItems/draft-item')));
  await assertSucceeds(
    getDoc(
      doc(
        userDb,
        'workflowDefinitions/published-workflow/versions/v1',
      ),
    ),
  );
  await assertSucceeds(
    getDoc(doc(userDb, 'slaPolicies/published-sla')),
  );

  const adminDb = userFirestore('admin-1');
  await assertSucceeds(
    getDoc(doc(adminDb, 'serviceCatalogItems/draft-item')),
  );
  await assertFails(
    updateDoc(doc(adminDb, 'serviceCatalogItems/draft-item'), {
      name: 'Admin mutation',
      updatedAt: serverTimestamp(),
    }),
  );
});

test('comments and attachment metadata inherit parent access', async () => {
  const userDb = userFirestore('user-1');
  await assertSucceeds(
    getDoc(doc(userDb, 'serviceRequests/request-1/comments/public')),
  );
  await assertFails(
    getDoc(doc(userDb, 'serviceRequests/request-1/comments/internal')),
  );
  await assertFails(
    getDoc(doc(userDb, 'serviceRequests/request-2/comments/missing')),
  );
  await assertSucceeds(
    getDoc(doc(userDb, 'serviceRequests/request-1/attachments/public')),
  );
  await assertFails(
    getDoc(doc(userDb, 'serviceRequests/request-1/attachments/internal')),
  );

  await assertSucceeds(
    addDoc(collection(userDb, 'serviceRequests/request-1/attachments'), {
      workItemCollection: 'serviceRequests',
      workItemId: 'request-1',
      uploadedByUserId: 'user-1',
      storagePath: 'itsm/serviceRequests/request-1/attachments/new/file.pdf',
      isInternal: false,
      createdAt: serverTimestamp(),
    }),
  );
  await assertFails(
    addDoc(collection(userDb, 'serviceRequests/request-1/attachments'), {
      workItemCollection: 'serviceRequests',
      workItemId: 'request-1',
      uploadedByUserId: 'user-1',
      storagePath:
        'itsm/serviceRequests/request-1/attachments/internal/file.pdf',
      isInternal: true,
      createdAt: serverTimestamp(),
    }),
  );

  const managerDb = userFirestore('manager-1');
  await assertSucceeds(
    getDoc(doc(managerDb, 'serviceRequests/request-1/comments/internal')),
  );
  await assertSucceeds(
    getDoc(doc(managerDb, 'serviceRequests/request-1/attachments/internal')),
  );
});

test('approvals and audit records are readable but server-write-only', async () => {
  const userDb = userFirestore('user-1');
  await assertSucceeds(
    getDoc(doc(userDb, 'serviceRequests/request-1/approvals/approval-1')),
  );
  await assertFails(
    updateDoc(
      doc(userDb, 'serviceRequests/request-1/approvals/approval-1'),
      { decision: 'approved' },
    ),
  );
  await assertFails(
    addDoc(collection(userDb, 'serviceRequests/request-1/auditLogs'), {
      action: 'forged',
      createdAt: serverTimestamp(),
    }),
  );

  const managerDb = userFirestore('manager-1');
  await assertSucceeds(
    getDoc(doc(managerDb, 'itsmAuditEvents/normal-event')),
  );
  await assertSucceeds(
    getDoc(doc(managerDb, 'itsmAuditEvents/restricted-event')),
  );
  await assertFails(
    setDoc(doc(managerDb, 'itsmAuditEvents/forged-event'), {
      action: 'forged',
      createdAt: serverTimestamp(),
    }),
  );
  await assertFails(
    updateDoc(doc(managerDb, 'itsmAuditEvents/normal-event'), {
      action: 'rewritten',
    }),
  );
  await assertFails(
    deleteDoc(doc(managerDb, 'itsmAuditEvents/normal-event')),
  );

  const adminDb = userFirestore('admin-1');
  await assertSucceeds(
    getDoc(doc(adminDb, 'itsmAuditEvents/normal-event')),
  );
  await assertFails(
    getDoc(doc(adminDb, 'itsmAuditEvents/restricted-event')),
  );
});

test('unknown collections and unauthenticated reads remain denied', async () => {
  const authenticated = userFirestore('manager-1');
  await assertFails(
    getDoc(doc(authenticated, 'unknownItsmCollection/unknown')),
  );

  const anonymous = environment.unauthenticatedContext().firestore();
  await assertFails(
    getDoc(doc(anonymous, 'serviceCatalogItems/published-item')),
  );
});

function userFirestore(uid) {
  return environment
    .authenticatedContext(uid, { email: `${uid}@arptc.cd` })
    .firestore();
}

function agent(role, aliases = {}) {
  return {
    email: `${role.toLowerCase()}@arptc.cd`,
    modulePermissions: { ticketing: role, ...aliases },
  };
}

function aliasAgent(key, role) {
  return {
    email: `${key}-${role.toLowerCase()}@arptc.cd`,
    modulePermissions: { [key]: role },
  };
}

function workItem({
  requesterId,
  confidentiality = 'INTERNAL',
  authorizedUserIds = [],
}) {
  const timestamp = Timestamp.fromDate(new Date('2026-07-01T08:00:00Z'));
  return {
    requesterId,
    requesterEmail: `${requesterId}@arptc.cd`,
    type: 'service_request',
    title: 'ITSM work item',
    status: 'open',
    lifecycleState: 'active',
    confidentiality,
    authorizedUserIds,
    selfServiceVisible: true,
    createdAt: timestamp,
    updatedAt: timestamp,
  };
}

function configuration(status) {
  const timestamp = Timestamp.fromDate(new Date('2026-07-01T08:00:00Z'));
  return {
    name: 'Configuration',
    status,
    createdAt: timestamp,
    updatedAt: timestamp,
  };
}

function reportSnapshot(audience) {
  return {
    audience,
    confidentiality: 'INTERNAL',
    periodStart: Timestamp.fromDate(new Date('2026-07-01T00:00:00Z')),
    total: 3,
  };
}

function comment(isInternal) {
  return {
    body: isInternal ? 'Internal note' : 'Public update',
    createdByUserId: 'manager-1',
    isInternal,
    createdAt: Timestamp.fromDate(new Date('2026-07-01T09:00:00Z')),
  };
}

function attachment(isInternal) {
  return {
    workItemCollection: 'serviceRequests',
    workItemId: 'request-1',
    uploadedByUserId: 'manager-1',
    storagePath:
      `itsm/serviceRequests/request-1/attachments/${isInternal}/file.pdf`,
    isInternal,
    createdAt: Timestamp.fromDate(new Date('2026-07-01T09:00:00Z')),
  };
}

function restrictedAttachment() {
  return {
    workItemCollection: 'securityFindings',
    workItemId: 'restricted-finding',
    uploadedByUserId: 'manager-1',
    storagePath:
      'itsm/securityFindings/restricted-finding/attachments/evidence/file.pdf',
    isInternal: true,
    createdAt: Timestamp.fromDate(new Date('2026-07-01T09:00:00Z')),
  };
}

function approval() {
  return {
    step: 1,
    status: 'pending',
    requestedAt: Timestamp.fromDate(new Date('2026-07-01T09:00:00Z')),
  };
}

function auditEvent(isRestricted, authorizedUserIds = []) {
  return {
    action: 'created',
    module: 'support',
    confidentiality: isRestricted ? 'RESTRICTED' : 'INTERNAL',
    authorizedUserIds,
    isInternal: false,
    createdAt: Timestamp.fromDate(new Date('2026-07-01T08:00:00Z')),
  };
}
