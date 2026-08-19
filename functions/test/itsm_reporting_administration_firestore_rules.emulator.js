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
  Timestamp,
  collection,
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

const baseTime = Timestamp.fromDate(new Date('2026-07-01T08:00:00Z'));
const futureTime = Timestamp.fromDate(new Date('2030-07-01T08:00:00Z'));
const expiredTime = Timestamp.fromDate(new Date('2020-07-01T08:00:00Z'));
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
      setDoc(doc(firestore, 'agents/admin-2'), agent('ADMIN')),
      setDoc(
        doc(firestore, 'itsmReportSnapshots/manager-operational'),
        snapshot('MANAGER', 'operational'),
      ),
      setDoc(
        doc(firestore, 'itsmReportSnapshots/admin-executive'),
        snapshot('ADMIN', 'executive'),
      ),
      setDoc(
        doc(
          firestore,
          'itsmReportSnapshots/manager-operational/shards/shard-1',
        ),
        { metrics: { open: 2 } },
      ),
      setDoc(doc(firestore, 'itsmReportContributions/source-1'), {
        sourcePath: 'incidentTickets/incident-1',
        fingerprint: 'trusted-only',
      }),
      ...configurationSeeds(firestore),
      setDoc(
        doc(firestore, 'itsmSlaStates/user-state'),
        slaState('user-1'),
      ),
      setDoc(
        doc(firestore, 'itsmSlaStates/admin-state'),
        slaState('admin-1'),
      ),
      setDoc(
        doc(firestore, 'itsmSlaStates/other-state'),
        slaState('user-2'),
      ),
      setDoc(
        doc(firestore, 'itsmSlaStates/restricted-manager-1'),
        slaState('user-2', 'RESTRICTED', ['manager-1']),
      ),
      setDoc(
        doc(firestore, 'itsmReferenceData/published-calendar'),
        configuration('published', { type: 'business_calendar' }),
      ),
      setDoc(
        doc(firestore, 'itsmReferenceData/draft-group'),
        configuration('draft', { type: 'assignment_group' }),
      ),
      setDoc(
        doc(firestore, 'itsmReferenceData/restricted-calendar'),
        configuration('published', {
          type: 'business_calendar',
          confidentiality: 'RESTRICTED',
        }),
      ),
      setDoc(
        doc(firestore, 'itsmAuditEvents/non-restricted'),
        auditEvent(false),
      ),
      setDoc(
        doc(firestore, 'itsmAuditEvents/restricted-manager-1'),
        auditEvent(true, ['manager-1']),
      ),
      setDoc(
        doc(firestore, 'itsmAuditEvents/restricted-manager-2'),
        auditEvent(true, ['manager-2']),
      ),
      setDoc(
        doc(firestore, 'itsmAuditExports/manager-completed'),
        auditExport('manager-1', 'completed', futureTime),
      ),
      setDoc(
        doc(firestore, 'itsmAuditExports/admin-completed'),
        auditExport('admin-1', 'completed', futureTime),
      ),
      setDoc(
        doc(firestore, 'itsmAuditExports/manager-pending'),
        auditExport('manager-1', 'pending', futureTime),
      ),
      setDoc(
        doc(firestore, 'itsmAuditExports/manager-expired'),
        auditExport('manager-1', 'completed', expiredTime),
      ),
    ]);
  });
});

after(async () => {
  await environment.cleanup();
});

test('report snapshots are audience-scoped, bounded, and hide internals', async () => {
  const manager = firestoreFor('manager-1');
  const admin = firestoreFor('admin-1');
  const user = firestoreFor('user-1');

  await assertSucceeds(getDoc(doc(
    manager,
    'itsmReportSnapshots/manager-operational',
  )));
  await assertFails(getDoc(doc(
    manager,
    'itsmReportSnapshots/admin-executive',
  )));
  await assertSucceeds(getDoc(doc(
    admin,
    'itsmReportSnapshots/admin-executive',
  )));
  await assertFails(getDoc(doc(
    admin,
    'itsmReportSnapshots/manager-operational',
  )));
  await assertFails(getDoc(doc(
    user,
    'itsmReportSnapshots/manager-operational',
  )));

  const bounded = query(
    collection(manager, 'itsmReportSnapshots'),
    where('audience', '==', 'MANAGER'),
    where('snapshotType', '==', 'operational'),
    orderBy('periodStart', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(101),
  );
  await assertSucceeds(getDocs(bounded));
  await assertFails(getDocs(query(
    collection(manager, 'itsmReportSnapshots'),
    where('audience', '==', 'MANAGER'),
    where('snapshotType', '==', 'operational'),
    orderBy('periodStart', 'desc'),
    orderBy(documentId(), 'desc'),
  )));
  await assertFails(getDocs(query(
    collection(manager, 'itsmReportSnapshots'),
    orderBy('periodStart', 'desc'),
    limit(101),
  )));

  for (const firestore of [manager, admin]) {
    await assertFails(getDoc(doc(
      firestore,
      'itsmReportSnapshots/manager-operational/shards/shard-1',
    )));
    await assertFails(getDoc(doc(
      firestore,
      'itsmReportContributions/source-1',
    )));
  }
});

test('configuration visibility follows role and immutable lifecycle state', async () => {
  const manager = firestoreFor('manager-1');
  const admin = firestoreFor('admin-1');
  const user = firestoreFor('user-1');

  for (const root of [
    'serviceCatalogItems',
    'workflowDefinitions',
    'slaPolicies',
  ]) {
    await assertSucceeds(getDoc(doc(manager, `${root}/draft`)));
    await assertSucceeds(getDoc(doc(manager, `${root}/draft/versions/v2`)));
    await assertSucceeds(getDoc(doc(admin, `${root}/published`)));
    await assertSucceeds(getDoc(
      doc(admin, `${root}/published/versions/v1`),
    ));
    await assertFails(getDoc(doc(admin, `${root}/draft`)));
    await assertFails(getDoc(doc(admin, `${root}/draft/versions/v2`)));
    await assertSucceeds(getDoc(doc(user, `${root}/published`)));
    await assertFails(getDoc(doc(user, `${root}/retired/versions/v1`)));
  }

  await assertFails(getDoc(doc(
    admin,
    'serviceCatalogItems/retired',
  )));
  await assertSucceeds(getDoc(doc(
    admin,
    'serviceCatalogItems/retired/versions/v1',
  )));
  for (const root of ['workflowDefinitions', 'slaPolicies']) {
    await assertSucceeds(getDoc(doc(admin, `${root}/retired`)));
    await assertSucceeds(getDoc(
      doc(admin, `${root}/retired/versions/v1`),
    ));
  }

  await assertSucceeds(getDocs(query(
    collection(manager, 'workflowDefinitions'),
    orderBy('updatedAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(101),
  )));
  await assertFails(getDocs(query(
    collection(manager, 'workflowDefinitions'),
    orderBy('updatedAt', 'desc'),
    orderBy(documentId(), 'desc'),
  )));
});

test('all reporting and configuration mutation remains trusted-only', async () => {
  const guardedPaths = [
    'itsmReportSnapshots/manager-operational',
    'itsmReportContributions/source-1',
    'itsmAuditEvents/non-restricted',
    'itsmAuditExports/manager-completed',
    'serviceCatalogItems/draft',
    'serviceCatalogItems/draft/versions/v2',
    'workflowDefinitions/draft',
    'workflowDefinitions/draft/versions/v2',
    'slaPolicies/draft',
    'slaPolicies/draft/versions/v2',
    'itsmSlaStates/user-state',
    'itsmReferenceData/draft-group',
  ];

  for (const uid of ['user-1', 'manager-1', 'admin-1']) {
    const firestore = firestoreFor(uid);
    for (const guardedPath of guardedPaths) {
      await assertFails(updateDoc(doc(firestore, guardedPath), {
        forgedBy: uid,
      }));
      await assertFails(deleteDoc(doc(firestore, guardedPath)));
    }
    await assertFails(setDoc(
      doc(firestore, `workflowDefinitions/forged-${uid}`),
      configuration('draft'),
    ));
  }
});

test('SLA state is operational for MANAGER and owner-scoped for self-service', async () => {
  const user = firestoreFor('user-1');
  const admin = firestoreFor('admin-1');
  const manager = firestoreFor('manager-1');
  const otherManager = firestoreFor('manager-2');

  await assertSucceeds(getDoc(doc(user, 'itsmSlaStates/user-state')));
  await assertFails(getDoc(doc(user, 'itsmSlaStates/other-state')));
  await assertSucceeds(getDoc(doc(admin, 'itsmSlaStates/admin-state')));
  await assertFails(getDoc(doc(admin, 'itsmSlaStates/other-state')));
  await assertSucceeds(getDoc(
    doc(manager, 'itsmSlaStates/restricted-manager-1'),
  ));
  await assertFails(getDoc(
    doc(otherManager, 'itsmSlaStates/restricted-manager-1'),
  ));

  await assertSucceeds(getDocs(query(
    collection(user, 'itsmSlaStates'),
    where('requesterId', '==', 'user-1'),
    orderBy('updatedAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(101),
  )));
  await assertFails(getDocs(query(
    collection(user, 'itsmSlaStates'),
    where('requesterId', '==', 'user-1'),
    orderBy('updatedAt', 'desc'),
    orderBy(documentId(), 'desc'),
  )));
});

test('global audit is bounded, append-only, and confidentiality-aware', async () => {
  const manager = firestoreFor('manager-1');
  const otherManager = firestoreFor('manager-2');
  const admin = firestoreFor('admin-1');
  const user = firestoreFor('user-1');

  await assertSucceeds(getDoc(
    doc(manager, 'itsmAuditEvents/non-restricted'),
  ));
  await assertSucceeds(getDoc(
    doc(manager, 'itsmAuditEvents/restricted-manager-1'),
  ));
  await assertFails(getDoc(
    doc(otherManager, 'itsmAuditEvents/restricted-manager-1'),
  ));
  await assertSucceeds(getDoc(
    doc(admin, 'itsmAuditEvents/non-restricted'),
  ));
  await assertFails(getDoc(
    doc(admin, 'itsmAuditEvents/restricted-manager-1'),
  ));
  await assertFails(getDoc(
    doc(user, 'itsmAuditEvents/non-restricted'),
  ));

  await assertSucceedsWithLabel('MANAGER non-restricted audit page', getDocs(query(
    collection(manager, 'itsmAuditEvents'),
    where('isRestricted', '==', false),
    orderBy('createdAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(101),
  )));
  await assertSucceedsWithLabel('MANAGER restricted audit page', getDocs(query(
    collection(manager, 'itsmAuditEvents'),
    where('isRestricted', '==', true),
    where('authorizedManagerIds', 'array-contains', 'manager-1'),
    orderBy('createdAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(101),
  )));
  await assertSucceedsWithLabel('ADMIN non-restricted audit page', getDocs(query(
    collection(admin, 'itsmAuditEvents'),
    where('isRestricted', '==', false),
    orderBy('createdAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(101),
  )));
  await assertFails(getDocs(query(
    collection(admin, 'itsmAuditEvents'),
    orderBy('createdAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(101),
  )));
  await assertFails(getDocs(query(
    collection(manager, 'itsmAuditEvents'),
    where('isRestricted', '==', false),
    orderBy('createdAt', 'desc'),
    orderBy(documentId(), 'desc'),
  )));
});

test('audit export metadata is owner-only, completed, unexpired, and immutable', async () => {
  const manager = firestoreFor('manager-1');
  const otherManager = firestoreFor('manager-2');
  const admin = firestoreFor('admin-1');
  const user = firestoreFor('user-1');

  await assertSucceeds(getDoc(
    doc(manager, 'itsmAuditExports/manager-completed'),
  ));
  await assertFails(getDoc(
    doc(otherManager, 'itsmAuditExports/manager-completed'),
  ));
  await assertFails(getDoc(
    doc(manager, 'itsmAuditExports/manager-pending'),
  ));
  await assertFails(getDoc(
    doc(manager, 'itsmAuditExports/manager-expired'),
  ));
  await assertSucceeds(getDoc(
    doc(admin, 'itsmAuditExports/admin-completed'),
  ));
  await assertFails(getDoc(
    doc(user, 'itsmAuditExports/manager-completed'),
  ));

  await assertFails(getDocs(query(
    collection(manager, 'itsmAuditExports'),
    where('requesterUserId', '==', 'manager-1'),
    where('status', '==', 'completed'),
    where(
      'expiresAt',
      '>',
      Timestamp.fromDate(new Date('2029-01-01T00:00:00Z')),
    ),
    orderBy('expiresAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(101),
  )));
});

test('reference data exposes only published safe values outside MANAGER', async () => {
  const manager = firestoreFor('manager-1');
  const admin = firestoreFor('admin-1');
  const user = firestoreFor('user-1');

  await assertSucceeds(getDoc(
    doc(manager, 'itsmReferenceData/draft-group'),
  ));
  await assertSucceeds(getDoc(
    doc(user, 'itsmReferenceData/published-calendar'),
  ));
  await assertSucceeds(getDoc(
    doc(admin, 'itsmReferenceData/published-calendar'),
  ));
  await assertFails(getDoc(doc(user, 'itsmReferenceData/draft-group')));
  await assertFails(getDoc(doc(admin, 'itsmReferenceData/draft-group')));
  await assertFails(getDoc(
    doc(admin, 'itsmReferenceData/restricted-calendar'),
  ));
});

test('unauthenticated principals cannot read Phase 6 collections', async () => {
  const firestore = environment.unauthenticatedContext().firestore();
  for (const target of [
    'itsmReportSnapshots/manager-operational',
    'serviceCatalogItems/published',
    'workflowDefinitions/published',
    'slaPolicies/published',
    'itsmAuditEvents/non-restricted',
    'itsmAuditExports/manager-completed',
  ]) {
    await assertFails(getDoc(doc(firestore, target)));
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

async function assertSucceedsWithLabel(label, operation) {
  try {
    return await assertSucceeds(operation);
  } catch (error) {
    throw new Error(`${label}: ${error.message}`, { cause: error });
  }
}

function agent(role) {
  return {
    email: `${role.toLowerCase()}@arptc.cd`,
    isActive: true,
    modulePermissions: { ticketing: role },
  };
}

function snapshot(audience, snapshotType) {
  return {
    schemaVersion: 1,
    audience,
    snapshotType,
    scopeType: 'global',
    scopeId: 'global',
    periodStart: baseTime,
    periodEnd: futureTime,
    generatedAt: baseTime,
    confidentiality: 'INTERNAL',
    metrics: { total: 2 },
  };
}

function configuration(status, fields = {}) {
  return {
    name: 'Configuration',
    status,
    isActive: status === 'published',
    createdAt: baseTime,
    updatedAt: baseTime,
    ...fields,
  };
}

function configurationSeeds(firestore) {
  const writes = [];
  for (const root of [
    'serviceCatalogItems',
    'workflowDefinitions',
    'slaPolicies',
  ]) {
    for (const status of ['published', 'retired', 'draft']) {
      const id = status;
      writes.push(setDoc(
        doc(firestore, `${root}/${id}`),
        configuration(status),
      ));
      writes.push(setDoc(
        doc(
          firestore,
          `${root}/${id}/versions/${status === 'draft' ? 'v2' : 'v1'}`,
        ),
        configuration(status, { version: status === 'draft' ? 2 : 1 }),
      ));
    }
  }
  return writes;
}

function slaState(
  requesterId,
  confidentiality = 'INTERNAL',
  authorizedUserIds = [],
) {
  return {
    entityType: 'service_request',
    entityId: `request-${requesterId}`,
    requesterId,
    selfServiceVisible: true,
    confidentiality,
    authorizedUserIds,
    processingStatus: 'active',
    updatedAt: baseTime,
  };
}

function auditEvent(isRestricted, authorizedManagerIds = []) {
  return {
    action: 'updated',
    module: 'support',
    entityType: 'incident',
    entityId: 'incident-1',
    entityReference: 'INC-1',
    actor: {
      userId: 'manager-2',
      departmentId: 'it',
    },
    confidentiality: isRestricted ? 'RESTRICTED' : 'INTERNAL',
    isRestricted,
    authorizedManagerIds,
    correlationId: 'correlation-1',
    createdAt: baseTime,
  };
}

function auditExport(requesterUserId, status, expiresAt) {
  const exportId = status === 'pending'
    ? 'manager-pending'
    : requesterUserId === 'admin-1'
      ? 'admin-completed'
      : expiresAt === expiredTime
        ? 'manager-expired'
        : 'manager-completed';
  const fileName = 'audit.csv';
  return {
    requesterUserId,
    status,
    expiresAt,
    fileName,
    storagePath:
      `itsm/reporting-exports/${requesterUserId}/${exportId}/${fileName}`,
    createdAt: baseTime,
  };
}
