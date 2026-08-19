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
  and,
  deleteDoc,
  doc,
  documentId,
  getDoc,
  getDocs,
  limit,
  or,
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
      setDoc(doc(firestore, 'agents/admin-1'), agent('ADMIN')),
      setDoc(doc(firestore, 'changeRequests/own'), change('user-1')),
      setDoc(doc(firestore, 'changeRequests/other'), change('user-2')),
      setDoc(doc(firestore, 'changeRequests/admin-own'), change('admin-1')),
      setDoc(
        doc(firestore, 'changeRequests/own/comments/public'),
        publicRecord(),
      ),
      setDoc(
        doc(firestore, 'changeRequests/own/comments/internal'),
        internalRecord(),
      ),
      setDoc(
        doc(firestore, 'changeRequests/own/attachments/public'),
        publicRecord(),
      ),
      setDoc(
        doc(firestore, 'changeRequests/own/attachments/internal'),
        internalRecord(),
      ),
      setDoc(
        doc(firestore, 'changeRequests/own/auditLogs/public'),
        publicRecord(),
      ),
      setDoc(
        doc(firestore, 'changeRequests/own/tasks/internal'),
        internalRecord(),
      ),
      setDoc(
        doc(firestore, 'changeRequests/own/approvals/approval-1'),
        { status: 'pending', requestedAt: date(2) },
      ),
      setDoc(
        doc(firestore, 'changeRequests/own/approvalHistory/history-1'),
        { decision: 'approved', occurredAt: date(3) },
      ),
      setDoc(
        doc(firestore, 'changeRequests/own/cabMeetings/meeting-1'),
        { scheduledAt: date(4), agenda: 'Private deliberation' },
      ),
      setDoc(
        doc(firestore, 'changeRequests/own/workflowInstances/workflow-1'),
        { currentState: 'awaiting_approval' },
      ),
      setDoc(
        doc(firestore, 'changeRequests/own/privateNotes/note-1'),
        { body: 'Unknown private path' },
      ),
      setDoc(
        doc(firestore, 'changeCalendarEntries/own-private'),
        calendar('user-1', false, 10),
      ),
      setDoc(
        doc(firestore, 'changeCalendarEntries/other-private'),
        calendar('user-2', false, 11),
      ),
      setDoc(
        doc(firestore, 'changeCalendarEntries/published'),
        calendar('user-2', true, 12),
      ),
      setDoc(
        doc(firestore, 'changeCalendarEntries/admin-private'),
        calendar('admin-1', false, 13),
      ),
      setDoc(
        doc(firestore, 'changeApprovalGroups/cab-core'),
        { name: 'Core CAB', isActive: true },
      ),
      setDoc(
        doc(firestore, 'maintenanceWindows/weekend'),
        { name: 'Weekend', isActive: true },
      ),
    ]);
  });
});

after(async () => {
  await environment.cleanup();
});

test('raw changes are requester-scoped, MANAGER operational, and trusted-write only', async () => {
  const user = firestoreFor('user-1');
  await assertSucceeds(getDoc(doc(user, 'changeRequests/own')));
  await assertFails(getDoc(doc(user, 'changeRequests/other')));

  const admin = firestoreFor('admin-1');
  await assertSucceeds(getDoc(doc(admin, 'changeRequests/admin-own')));
  await assertFails(getDoc(doc(admin, 'changeRequests/other')));

  const manager = firestoreFor('manager-1');
  await assertSucceeds(getDoc(doc(manager, 'changeRequests/own')));
  await assertSucceeds(getDoc(doc(manager, 'changeRequests/other')));

  for (const firestore of [user, admin, manager]) {
    await assertFails(setDoc(doc(firestore, 'changeRequests/forged'), change('user-1')));
    await assertFails(updateDoc(doc(firestore, 'changeRequests/own'), { title: 'Forged' }));
    await assertFails(deleteDoc(doc(firestore, 'changeRequests/own')));
  }
});

test('bounded list queries prove requester and operational scope', async () => {
  const user = firestoreFor('user-1');
  const own = await assertSucceeds(getDocs(query(
    collection(user, 'changeRequests'),
    where('requesterId', '==', 'user-1'),
    where('lifecycleState', '==', 'active'),
    orderBy('updatedAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(25),
  )));
  if (own.size !== 1 || own.docs[0].id !== 'own') {
    throw new Error('Requester query escaped its self-service boundary.');
  }
  await assertFails(getDocs(query(collection(user, 'changeRequests'), limit(25))));

  const admin = firestoreFor('admin-1');
  const adminOwn = await assertSucceeds(getDocs(query(
    collection(admin, 'changeRequests'),
    where('requesterId', '==', 'admin-1'),
    where('lifecycleState', '==', 'active'),
    orderBy('updatedAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(25),
  )));
  if (adminOwn.size !== 1 || adminOwn.docs[0].id !== 'admin-own') {
    throw new Error('ADMIN raw query escaped its own requester boundary.');
  }
  await assertFails(getDocs(query(collection(admin, 'changeRequests'), limit(25))));

  const manager = firestoreFor('manager-1');
  const operational = await assertSucceeds(getDocs(query(
    collection(manager, 'changeRequests'),
    where('lifecycleState', '==', 'active'),
    orderBy('updatedAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(25),
  )));
  if (operational.size !== 3) {
    throw new Error('MANAGER did not receive the bounded operational queue.');
  }
});

test('requester sees only public subresources while MANAGER sees internal records', async () => {
  const user = firestoreFor('user-1');
  await assertSucceeds(getDoc(doc(user, 'changeRequests/own/comments/public')));
  await assertFails(getDoc(doc(user, 'changeRequests/own/comments/internal')));
  await assertSucceeds(getDoc(doc(user, 'changeRequests/own/attachments/public')));
  await assertFails(getDoc(doc(user, 'changeRequests/own/attachments/internal')));
  await assertSucceeds(getDoc(doc(user, 'changeRequests/own/auditLogs/public')));
  await assertFails(getDoc(doc(user, 'changeRequests/own/tasks/internal')));
  await assertFails(getDoc(doc(user, 'changeRequests/other/comments/public')));

  const manager = firestoreFor('manager-1');
  await assertSucceeds(getDoc(doc(manager, 'changeRequests/own/comments/internal')));
  await assertSucceeds(getDoc(doc(manager, 'changeRequests/own/attachments/internal')));
  await assertSucceeds(getDoc(doc(manager, 'changeRequests/own/tasks/internal')));
  await assertFails(updateDoc(
    doc(manager, 'changeRequests/own/comments/public'),
    { body: 'Client mutation is forbidden' },
  ));
});

test('CAB deliberations and workflow internals are MANAGER-only and immutable', async () => {
  const privatePaths = [
    'changeRequests/own/approvals/approval-1',
    'changeRequests/own/approvalHistory/history-1',
    'changeRequests/own/cabMeetings/meeting-1',
    'changeRequests/own/workflowInstances/workflow-1',
  ];
  for (const uid of ['user-1', 'admin-1']) {
    const firestore = firestoreFor(uid);
    for (const documentPath of privatePaths) {
      await assertFails(getDoc(doc(firestore, documentPath)));
    }
  }

  const manager = firestoreFor('manager-1');
  for (const documentPath of privatePaths) {
    await assertSucceeds(getDoc(doc(manager, documentPath)));
  }
  await assertFails(updateDoc(
    doc(manager, 'changeRequests/own/approvals/approval-1'),
    { status: 'approved' },
  ));
  await assertFails(getDoc(
    doc(manager, 'changeRequests/own/privateNotes/note-1'),
  ));
});

test('calendar grants USER own-or-published, ADMIN published-only, and MANAGER operations', async () => {
  const user = firestoreFor('user-1');
  await assertSucceeds(getDoc(doc(user, 'changeCalendarEntries/own-private')));
  await assertSucceeds(getDoc(doc(user, 'changeCalendarEntries/published')));
  await assertFails(getDoc(doc(user, 'changeCalendarEntries/other-private')));

  const userCalendar = await assertSucceeds(getDocs(query(
    collection(user, 'changeCalendarEntries'),
    and(
      or(
        where('requesterId', '==', 'user-1'),
        where('publishMaintenance', '==', true),
      ),
      where('plannedStartAt', '>=', date(9)),
      where('plannedStartAt', '<', date(20)),
    ),
    orderBy('plannedStartAt'),
    orderBy(documentId()),
    limit(100),
  )));
  if (userCalendar.size !== 2) {
    throw new Error('USER calendar did not return own and published entries.');
  }
  const userConflicts = await assertSucceeds(getDocs(query(
    collection(user, 'changeCalendarEntries'),
    and(
      or(
        where('requesterId', '==', 'user-1'),
        where('publishMaintenance', '==', true),
      ),
      where('hasConflict', '==', true),
      where('plannedStartAt', '>=', date(9)),
      where('plannedStartAt', '<', date(20)),
    ),
    orderBy('plannedStartAt'),
    orderBy(documentId()),
    limit(100),
  )));
  if (userConflicts.size !== 2) {
    throw new Error('USER conflict filter escaped own-or-published scope.');
  }
  await assertFails(getDocs(query(collection(user, 'changeCalendarEntries'), limit(100))));

  const admin = firestoreFor('admin-1');
  await assertSucceeds(getDoc(doc(admin, 'changeCalendarEntries/published')));
  await assertFails(getDoc(doc(admin, 'changeCalendarEntries/admin-private')));
  const executive = await assertSucceeds(getDocs(query(
    collection(admin, 'changeCalendarEntries'),
    where('publishMaintenance', '==', true),
    where('plannedStartAt', '>=', date(9)),
    where('plannedStartAt', '<', date(20)),
    orderBy('plannedStartAt'),
    orderBy(documentId()),
    limit(100),
  )));
  if (executive.size !== 1 || executive.docs[0].id !== 'published') {
    throw new Error('ADMIN calendar exposed an unpublished projection.');
  }
  const executiveConflicts = await assertSucceeds(getDocs(query(
    collection(admin, 'changeCalendarEntries'),
    where('publishMaintenance', '==', true),
    where('hasConflict', '==', true),
    where('plannedStartAt', '>=', date(9)),
    where('plannedStartAt', '<', date(20)),
    orderBy('plannedStartAt'),
    orderBy(documentId()),
    limit(100),
  )));
  if (executiveConflicts.size !== 1) {
    throw new Error('ADMIN conflict filter exposed a private projection.');
  }

  const manager = firestoreFor('manager-1');
  const operational = await assertSucceeds(getDocs(query(
    collection(manager, 'changeCalendarEntries'),
    where('plannedStartAt', '>=', date(9)),
    where('plannedStartAt', '<', date(20)),
    orderBy('plannedStartAt'),
    orderBy(documentId()),
    limit(100),
  )));
  if (operational.size !== 4) {
    throw new Error('MANAGER calendar did not expose all bounded entries.');
  }
  const operationalConflicts = await assertSucceeds(getDocs(query(
    collection(manager, 'changeCalendarEntries'),
    where('hasConflict', '==', true),
    where('plannedStartAt', '>=', date(9)),
    where('plannedStartAt', '<', date(20)),
    orderBy('plannedStartAt'),
    orderBy(documentId()),
    limit(100),
  )));
  if (operationalConflicts.size !== 2) {
    throw new Error('MANAGER conflict filter returned the wrong bounded set.');
  }
  await assertFails(updateDoc(
    doc(manager, 'changeCalendarEntries/published'),
    { publishMaintenance: false },
  ));
});

test('CAB configuration and maintenance windows are MANAGER-read/trusted-write only', async () => {
  for (const uid of ['user-1', 'admin-1']) {
    const firestore = firestoreFor(uid);
    await assertFails(getDoc(doc(firestore, 'changeApprovalGroups/cab-core')));
    await assertFails(getDoc(doc(firestore, 'maintenanceWindows/weekend')));
  }

  const manager = firestoreFor('manager-1');
  await assertSucceeds(getDoc(doc(manager, 'changeApprovalGroups/cab-core')));
  await assertSucceeds(getDoc(doc(manager, 'maintenanceWindows/weekend')));
  await assertFails(updateDoc(
    doc(manager, 'changeApprovalGroups/cab-core'),
    { name: 'Forged CAB' },
  ));
  await assertFails(setDoc(
    doc(manager, 'maintenanceWindows/forged'),
    { name: 'Forged window' },
  ));
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

function change(requesterId, overrides = {}) {
  return {
    requesterId,
    requesterEmail: `${requesterId}@arptc.cd`,
    title: `Change for ${requesterId}`,
    status: 'submitted',
    lifecycleState: 'active',
    confidentiality: 'internal',
    selfServiceVisible: true,
    changeType: 'normal',
    risk: 'medium',
    createdAt: date(1),
    updatedAt: date(2),
    ...overrides,
  };
}

function calendar(requesterId, publishMaintenance, day) {
  return {
    requesterId,
    changeId: `${requesterId}-${day}`,
    changeType: 'normal',
    status: 'scheduled',
    affectedServiceIds: ['email'],
    affectedCiIds: ['ci-mail'],
    hasConflict: day % 2 === 0,
    publishMaintenance,
    plannedStartAt: date(day),
    plannedEndAt: date(day, 2),
  };
}

function publicRecord() {
  return { isInternal: false, selfServiceVisible: true };
}

function internalRecord() {
  return { isInternal: true, selfServiceVisible: false };
}

function date(day, hour = 0) {
  return new Date(Date.UTC(2026, 6, day, hour));
}
