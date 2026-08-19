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

const projectId = 'demo-arptc-connect-organization-rules';
const rules = fs.readFileSync(
  path.resolve(__dirname, '../../firestore.rules'),
  'utf8',
);
const timestamp = Timestamp.fromDate(new Date('2026-08-01T08:00:00.000Z'));

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
      setDoc(doc(firestore, 'organizations/org-a'), organization('ORG-A')),
      setDoc(doc(firestore, 'organizations/org-b'), organization('ORG-B')),
      setDoc(doc(firestore, 'organizationDirectory/org-a'),
        organizationDirectory('ORG-A')),
      setDoc(doc(firestore, 'organizationDirectory/org-b'),
        organizationDirectory('ORG-B')),
      setDoc(doc(firestore, 'organizationUnits/unit-a'), unit('org-a', 'UNIT-A')),
      setDoc(doc(firestore, 'organizationUnits/unit-b'), unit('org-b', 'UNIT-B')),

      setDoc(doc(firestore, 'agents/user-a'), agent('org-a', 'USER')),
      setDoc(doc(firestore, 'agents/user-a-2'), agent('org-a', 'USER')),
      setDoc(doc(firestore, 'agents/manager-a'), agent('org-a', 'MANAGER')),
      setDoc(doc(firestore, 'agents/admin-a'), agent('org-a', 'ADMIN')),
      setDoc(doc(firestore, 'agents/inactive-manager-a'), {
        ...agent('org-a', 'MANAGER'),
        isActive: false,
      }),
      setDoc(doc(firestore, 'agents/unverified-manager-a'),
        agent('org-a', 'MANAGER')),
      setDoc(doc(firestore, 'agents/no-claim-manager-a'),
        agent('org-a', 'MANAGER')),
      setDoc(doc(firestore, 'agents/manager-b'), agent('org-b', 'MANAGER')),
      setDoc(doc(firestore, 'agents/user-b'), agent('org-b', 'USER')),
      setDoc(doc(firestore, 'agents/password-change-user'), {
        ...agent('org-a', 'USER'),
        mustChangePassword: true,
      }),

      setDoc(doc(firestore, 'agentDirectory/user-a'),
        directoryEntry('org-a', 'Alice Agent')),
      setDoc(doc(firestore, 'agentDirectory/user-a-2'),
        directoryEntry('org-a', 'Aline Agent')),
      setDoc(doc(firestore, 'agentDirectory/inactive-user-a'), {
        ...directoryEntry('org-a', 'Archived Agent'),
        isActive: false,
      }),
      setDoc(doc(firestore, 'agentDirectory/user-b'),
        directoryEntry('org-b', 'Bob Agent')),

      setDoc(doc(firestore, 'organizationAssignments/assignment-user-a'),
        assignment('org-a', 'user-a', 'unit-a')),
      setDoc(doc(firestore, 'organizationAssignments/assignment-user-a-2'),
        assignment('org-a', 'user-a-2', 'unit-a')),
      setDoc(doc(firestore, 'organizationAssignments/assignment-user-b'),
        assignment('org-b', 'user-b', 'unit-b')),

      setDoc(doc(firestore, 'organizationAuditEvents/audit-a'),
        auditEvent('org-a')),
      setDoc(doc(firestore, 'organizationAuditEvents/audit-b'),
        auditEvent('org-b')),

      setDoc(doc(firestore, 'agentAuthorizationIndex/user-a'), {
        organizationId: 'org-a',
        isActive: true,
        scopeKeys: ['org:org-a', 'unit:unit-a'],
        moduleRoleKeys: ['usermanagement:USER'],
        scopeRoleKeys: ['unit:unit-a:usermanagement:USER'],
        schemaVersion: 2,
      }),
      setDoc(doc(firestore, 'organizationCodeLocks/ORG-A'), {
        organizationId: 'org-a',
      }),
      setDoc(doc(firestore, 'organizationUnitCodeLocks/org-a:UNIT-A'), {
        organizationId: 'org-a',
        unitId: 'unit-a',
      }),
      setDoc(doc(firestore, 'organizationCommandReceipts/command-1'), {
        organizationId: 'org-a',
        command: 'createOrganizationUnit',
      }),

      ...legacyDocuments(firestore),
    ]);
  });
});

after(async () => {
  await environment.cleanup();
});

test('only active and verified principals can access organization data', async () => {
  const inactive = principal('inactive-manager-a');
  const unverified = principal('unverified-manager-a', false);
  const missingClaim = principal('no-claim-manager-a', 'missing');
  const anonymous = environment.unauthenticatedContext().firestore();

  for (const firestore of [inactive, unverified, missingClaim, anonymous]) {
    await assertFails(getDoc(doc(firestore, 'organizations/org-a')));
    await assertFails(getDoc(doc(firestore, 'organizationDirectory/org-a')));
    await assertFails(getDoc(doc(firestore, 'organizationUnits/unit-a')));
    await assertFails(getDoc(doc(firestore, 'agentDirectory/user-a')));
  }

  await assertSucceeds(
    getDoc(doc(inactive, 'agents/inactive-manager-a')),
  );
  await assertFails(
    getDoc(doc(unverified, 'agents/unverified-manager-a')),
  );
  await assertFails(
    getDoc(doc(missingClaim, 'agents/no-claim-manager-a')),
  );
});

test('clients cannot forge notification events for any audience', async () => {
  const manager = principal('manager-a');
  const user = principal('user-a');
  for (const [firestore, target] of [
    [user, { type: 'ALL' }],
    [manager, {
      type: 'MODULE_ROLE',
      moduleKey: 'usermanagement',
      roles: ['MANAGER'],
    }],
  ]) {
    await assertFails(setDoc(doc(firestore, `notificationEvents/${target.type}`), {
      eventType: 'organization.forged',
      moduleKey: 'usermanagement',
      title: 'Forged notification',
      body: 'A client must not create this event.',
      entityType: 'organization',
      entityId: 'org-a',
      route: '/service/usermanagement/organizations',
      createdByUserId: target.type === 'ALL' ? 'user-a' : 'manager-a',
      createdByName: 'Forged Actor',
      createdByEmail: 'forged@example.com',
      target,
      status: 'PENDING',
      createdAt: timestamp,
    }));
  }
});

test('private agents allow self-get and global supervisor reads only', async () => {
  const user = principal('user-a');
  const manager = principal('manager-a');
  const admin = principal('admin-a');
  const otherManager = principal('manager-b');

  await assertSucceeds(getDoc(doc(user, 'agents/user-a')));
  await assertFails(getDoc(doc(user, 'agents/user-a-2')));
  await assertSucceeds(getDoc(doc(manager, 'agents/user-a')));
  await assertSucceeds(getDoc(doc(admin, 'agents/user-a')));
  await assertSucceeds(getDoc(doc(otherManager, 'agents/user-a')));

  const sameOrganization = (firestore, maximum = 100) => query(
    collection(firestore, 'agents'),
    where('organizationId', '==', 'org-a'),
    limit(maximum),
  );
  await assertSucceeds(getDocs(sameOrganization(manager)));
  await assertSucceeds(getDocs(sameOrganization(admin)));
  await assertSucceeds(getDocs(sameOrganization(otherManager)));
  await assertFails(getDocs(sameOrganization(user)));
  await assertFails(getDocs(sameOrganization(manager, 101)));
  await assertFails(getDocs(query(
    collection(manager, 'agents'),
    where('organizationId', '==', 'org-a'),
  )));
  await assertSucceeds(getDocs(query(
    collection(manager, 'agents'),
    where('organizationId', '==', 'org-b'),
    limit(100),
  )));
  await assertFails(getDocs(query(
    collection(user, 'agents'),
    where(documentId(), '==', 'user-a'),
    limit(1),
  )));

  await assertFails(updateDoc(doc(user, 'agents/user-a'), { matricule: 'X' }));
  await assertFails(deleteDoc(doc(manager, 'agents/user-a')));
});

test('first-login agents can read only their profile before changing password', async () => {
  const firestore = principal('password-change-user');

  await assertSucceeds(
    getDoc(doc(firestore, 'agents/password-change-user')),
  );
  await assertFails(getDoc(doc(firestore, 'agents/user-a')));
  await assertFails(getDoc(doc(firestore, 'organizations/org-a')));
  await assertFails(getDoc(doc(firestore, 'organizationDirectory/org-a')));
  await assertFails(getDoc(doc(firestore, 'agentDirectory/user-a')));
});

test('agentDirectory is safe, same-org, bounded, and hides inactive entries from users', async () => {
  const user = principal('user-a');
  const manager = principal('manager-a');
  const otherManager = principal('manager-b');

  await assertSucceeds(getDoc(doc(user, 'agentDirectory/user-a-2')));
  await assertFails(getDoc(doc(user, 'agentDirectory/inactive-user-a')));
  await assertSucceeds(getDoc(doc(manager, 'agentDirectory/inactive-user-a')));
  await assertSucceeds(getDoc(doc(otherManager, 'agentDirectory/user-a')));

  const activeDirectoryQuery = (firestore, maximum = 100) => query(
    collection(firestore, 'agentDirectory'),
    where('organizationId', '==', 'org-a'),
    where('isActive', '==', true),
    orderBy('displayNameLower'),
    orderBy(documentId()),
    limit(maximum),
  );
  const result = await assertSucceeds(getDocs(activeDirectoryQuery(user)));
  if (result.size !== 2) {
    throw new Error(`Expected two active directory entries, received ${result.size}.`);
  }
  await assertSucceeds(getDocs(activeDirectoryQuery(manager)));
  await assertSucceeds(getDocs(activeDirectoryQuery(otherManager)));
  await assertSucceeds(getDocs(query(
    collection(manager, 'agentDirectory'),
    where('organizationId', '==', 'org-a'),
    orderBy('displayNameLower'),
    orderBy(documentId()),
    limit(100),
  )));
  await assertFails(getDocs(activeDirectoryQuery(user, 101)));
  await assertFails(getDocs(query(
    collection(user, 'agentDirectory'),
    where('organizationId', '==', 'org-a'),
    where('isActive', '==', true),
  )));
  await assertFails(getDocs(query(
    collection(user, 'agentDirectory'),
    where('organizationId', '==', 'org-b'),
    where('isActive', '==', true),
    limit(100),
  )));
  await assertFails(setDoc(doc(user, 'agentDirectory/forged'),
    directoryEntry('org-a', 'Forged Agent')));
});

test('users see only their safe organization directory while supervisors read bounded private hierarchy data', async () => {
  const user = principal('user-a');
  const manager = principal('manager-a');

  await assertFails(getDoc(doc(user, 'organizations/org-a')));
  await assertFails(getDoc(doc(user, 'organizations/org-b')));
  await assertSucceeds(getDoc(doc(user, 'organizationDirectory/org-a')));
  await assertFails(getDoc(doc(user, 'organizationDirectory/org-b')));
  await assertSucceeds(getDocs(query(
    collection(user, 'organizationDirectory'),
    where(documentId(), '==', 'org-a'),
    limit(100),
  )));
  await assertFails(getDocs(query(
    collection(user, 'organizationDirectory'),
    orderBy('nameLower'),
    orderBy(documentId()),
    limit(100),
  )));
  await assertSucceeds(getDocs(query(
    collection(manager, 'organizations'),
    orderBy('nameLower'),
    orderBy(documentId()),
    limit(100),
  )));
  await assertSucceeds(getDoc(doc(manager, 'organizations/org-b')));
  await assertFails(getDocs(query(
    collection(user, 'organizations'),
    where(documentId(), '==', 'org-a'),
  )));
  await assertSucceeds(getDocs(query(
    collection(manager, 'organizationUnits'),
    where('organizationId', '==', 'org-b'),
    where('status', 'in', ['ACTIVE', 'INACTIVE']),
    orderBy('nameLower'),
    orderBy(documentId()),
    limit(100),
  )));
  await assertFails(getDocs(query(
    collection(user, 'organizations'),
    where(documentId(), '==', 'org-b'),
    limit(100),
  )));

  await assertFails(getDoc(doc(user, 'organizationUnits/unit-a')));
  await assertFails(getDoc(doc(user, 'organizationUnits/unit-b')));
  await assertFails(getDocs(query(
    collection(user, 'organizationUnits'),
    where('organizationId', '==', 'org-a'),
    where('status', 'in', ['ACTIVE', 'INACTIVE']),
    orderBy('nameLower'),
    orderBy(documentId()),
    limit(100),
  )));
  await assertFails(getDocs(query(
    collection(user, 'organizationUnits'),
    where('organizationId', '==', 'org-a'),
  )));
  await assertFails(getDocs(query(
    collection(user, 'organizationUnits'),
    where('organizationId', '==', 'org-b'),
    limit(100),
  )));

  await assertFails(setDoc(doc(manager, 'organizations/forged'),
    organization('FORGED')));
  await assertFails(updateDoc(doc(manager, 'organizationUnits/unit-a'), {
    name: 'Client mutation',
  }));
  await assertFails(deleteDoc(doc(manager, 'organizationUnits/unit-a')));
});

test('assignments allow own or global supervisor bounded reads and no writes', async () => {
  const user = principal('user-a');
  const manager = principal('manager-a');
  const admin = principal('admin-a');
  const otherManager = principal('manager-b');

  await assertSucceeds(
    getDoc(doc(user, 'organizationAssignments/assignment-user-a')),
  );
  await assertFails(
    getDoc(doc(user, 'organizationAssignments/assignment-user-a-2')),
  );
  await assertSucceeds(
    getDoc(doc(manager, 'organizationAssignments/assignment-user-a-2')),
  );
  await assertSucceeds(
    getDoc(doc(admin, 'organizationAssignments/assignment-user-a-2')),
  );
  await assertSucceeds(
    getDoc(doc(otherManager, 'organizationAssignments/assignment-user-a')),
  );

  const ownHistory = (maximum = 100) => query(
    collection(user, 'organizationAssignments'),
    where('agentId', '==', 'user-a'),
    orderBy('startsAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(maximum),
  );
  await assertSucceeds(getDocs(ownHistory()));
  await assertFails(getDocs(ownHistory(101)));
  await assertFails(getDocs(query(
    collection(user, 'organizationAssignments'),
    where('agentId', '==', 'user-a'),
  )));

  await assertSucceeds(getDocs(query(
    collection(manager, 'organizationAssignments'),
    where('organizationId', '==', 'org-a'),
    where('agentId', '==', 'user-a-2'),
    orderBy('startsAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(100),
  )));
  await assertSucceeds(getDocs(query(
    collection(manager, 'organizationAssignments'),
    where('organizationId', '==', 'org-a'),
    where('unitId', '==', 'unit-a'),
    orderBy('startsAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(100),
  )));
  await assertSucceeds(getDocs(query(
    collection(manager, 'organizationAssignments'),
    where('agentId', '==', 'user-a-2'),
    orderBy('startsAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(100),
  )));
  await assertSucceeds(getDocs(query(
    collection(manager, 'organizationAssignments'),
    where('unitId', '==', 'unit-a'),
    orderBy('startsAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(100),
  )));
  await assertSucceeds(getDocs(query(
    collection(manager, 'organizationAssignments'),
    where('organizationId', '==', 'org-b'),
    limit(100),
  )));
  await assertFails(getDocs(query(
    collection(manager, 'organizationAssignments'),
    limit(101),
  )));
  await assertFails(getDocs(query(
    collection(user, 'organizationAssignments'),
    where('organizationId', '==', 'org-a'),
    limit(100),
  )));

  await assertFails(updateDoc(
    doc(manager, 'organizationAssignments/assignment-user-a'),
    { status: 'ENDED' },
  ));
  await assertFails(setDoc(
    doc(manager, 'organizationAssignments/forged'),
    assignment('org-a', 'user-a', 'unit-a'),
  ));
});

test('organization audit is append-only and visible only to supervisors', async () => {
  const user = principal('user-a');
  const manager = principal('manager-a');
  const admin = principal('admin-a');
  const otherManager = principal('manager-b');

  await assertSucceeds(getDoc(doc(manager, 'organizationAuditEvents/audit-a')));
  await assertSucceeds(getDoc(doc(admin, 'organizationAuditEvents/audit-a')));
  await assertFails(getDoc(doc(user, 'organizationAuditEvents/audit-a')));
  await assertSucceeds(getDoc(doc(otherManager, 'organizationAuditEvents/audit-a')));

  const auditQuery = (firestore, maximum = 100) => query(
    collection(firestore, 'organizationAuditEvents'),
    where('organizationId', '==', 'org-a'),
    orderBy('createdAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(maximum),
  );
  await assertSucceeds(getDocs(auditQuery(manager)));
  await assertSucceeds(getDocs(auditQuery(admin)));
  await assertFails(getDocs(auditQuery(user)));
  await assertFails(getDocs(auditQuery(manager, 101)));
  await assertFails(getDocs(query(
    collection(manager, 'organizationAuditEvents'),
    where('organizationId', '==', 'org-a'),
  )));

  await assertFails(setDoc(doc(manager, 'organizationAuditEvents/forged'),
    auditEvent('org-a')));
  await assertFails(updateDoc(doc(manager, 'organizationAuditEvents/audit-a'), {
    reason: 'Rewritten history',
  }));
  await assertFails(deleteDoc(doc(manager, 'organizationAuditEvents/audit-a')));
});

test('authorization projections, locks, and command receipts are client-inaccessible', async () => {
  const manager = principal('manager-a');
  const protectedPaths = [
    'agentAuthorizationIndex/user-a',
    'organizationCodeLocks/ORG-A',
    'organizationUnitCodeLocks/org-a:UNIT-A',
    'organizationCommandReceipts/command-1',
  ];

  for (const protectedPath of protectedPaths) {
    await assertFails(getDoc(doc(manager, protectedPath)));
    await assertFails(setDoc(doc(manager, `${protectedPath}-forged`), {
      organizationId: 'org-a',
    }));
    await assertFails(deleteDoc(doc(manager, protectedPath)));
  }
});

test('legacy hierarchy collections are denied to every client role', async () => {
  const contexts = [
    principal('user-a'),
    principal('manager-a'),
    principal('admin-a'),
  ];
  const collections = ['departments', 'services', 'bureaux', 'directions'];

  for (const firestore of contexts) {
    for (const collectionName of collections) {
      await assertFails(getDoc(doc(firestore, `${collectionName}/legacy`)));
      await assertFails(getDocs(query(
        collection(firestore, collectionName),
        limit(1),
      )));
      await assertFails(setDoc(doc(firestore, `${collectionName}/forged`), {
        name: 'Forbidden legacy record',
      }));
    }
  }
});

function principal(uid, emailVerified = true) {
  const claims = { email: `${uid}@arptc.cd` };
  if (emailVerified !== 'missing') claims.email_verified = emailVerified;
  return environment.authenticatedContext(uid, claims).firestore();
}

function agent(organizationId, role) {
  return {
    email: `${role.toLowerCase()}@arptc.cd`,
    firstName: role,
    name: 'Agent',
    matricule: `MAT-${role}`,
    isActive: true,
    organizationId,
    organizationSchemaVersion: 2,
    modulePermissions: { usermanagement: role },
  };
}

function organization(code) {
  return {
    code,
    name: code,
    nameLower: code.toLowerCase(),
    status: 'ACTIVE',
    schemaVersion: 2,
    createdAt: timestamp,
    updatedAt: timestamp,
  };
}

function organizationDirectory(name) {
  return {
    name,
    nameLower: name.toLowerCase(),
    status: 'ACTIVE',
    updatedAt: timestamp,
  };
}

function unit(organizationId, code) {
  return {
    organizationId,
    type: 'DEPARTMENT',
    code,
    name: code,
    nameLower: code.toLowerCase(),
    parentUnitId: null,
    ancestorUnitIds: [],
    pathUnitIds: [code.toLowerCase()],
    pathNames: [code],
    scopeKeys: [`org:${organizationId}`],
    status: 'ACTIVE',
    schemaVersion: 2,
    createdAt: timestamp,
    updatedAt: timestamp,
  };
}

function directoryEntry(organizationId, displayName) {
  return {
    displayName,
    displayNameLower: displayName.toLowerCase(),
    firstName: displayName.split(' ')[0],
    name: 'Agent',
    postName: '',
    email: `${displayName.toLowerCase().replaceAll(' ', '.')}@arptc.cd`,
    profilePictureUrl: null,
    jobTitle: 'Agent',
    organizationId,
    organizationName: organizationId,
    primaryOrganizationUnitId: organizationId === 'org-a' ? 'unit-a' : 'unit-b',
    primaryOrganizationUnitName: 'Unit',
    primaryOrganizationUnitType: 'DEPARTMENT',
    organizationPathNames: ['Unit'],
    scopeKeys: [`org:${organizationId}`],
    isActive: true,
    updatedAt: timestamp,
  };
}

function assignment(organizationId, agentId, unitId) {
  return {
    organizationId,
    agentId,
    unitId,
    unitType: 'DEPARTMENT',
    unitName: 'Unit',
    pathUnitIds: [unitId],
    pathNames: ['Unit'],
    scopeKeys: [`org:${organizationId}`, `unit:${unitId}`],
    assignmentType: 'MEMBER',
    isPrimary: true,
    isActing: false,
    status: 'ACTIVE',
    startsAt: timestamp,
    endsAt: null,
    reason: 'Initial assignment',
    createdAt: timestamp,
    updatedAt: timestamp,
  };
}

function auditEvent(organizationId) {
  return {
    eventType: 'ORGANIZATION_UNIT_CREATED',
    actorUid: 'manager-a',
    organizationId,
    reason: 'Test fixture',
    commandId: 'command-1',
    createdAt: timestamp,
  };
}

function legacyDocuments(firestore) {
  return ['departments', 'services', 'bureaux', 'directions'].map(
    (collectionName) => setDoc(doc(firestore, `${collectionName}/legacy`), {
      name: 'Legacy record',
    }),
  );
}
