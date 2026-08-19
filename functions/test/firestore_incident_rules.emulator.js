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
  orderBy,
  query,
  serverTimestamp,
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
      setDoc(
        doc(firestore, 'incidentTickets/active-own'),
        ticket({
          createdByUserId: 'user-1',
          createdByEmail: 'user1@arptc.cd',
          affectedUserId: 'user-1',
          affectedUserEmail: 'user1@arptc.cd',
        }),
      ),
      setDoc(
        doc(firestore, 'incidentTickets/active-other'),
        ticket({
          createdByUserId: 'user-2',
          createdByEmail: 'user2@arptc.cd',
          affectedUserId: 'user-2',
          affectedUserEmail: 'user2@arptc.cd',
        }),
      ),
      setDoc(
        doc(firestore, 'incidentTickets/closed-other'),
        ticket({
          createdByUserId: 'user-2',
          createdByEmail: 'user2@arptc.cd',
          affectedUserId: 'user-2',
          affectedUserEmail: 'user2@arptc.cd',
          status: 'closed',
          lifecycleState: 'closed',
        }),
      ),
      setDoc(
        doc(firestore, 'incidentTickets/archived-other'),
        ticket({
          createdByUserId: 'user-2',
          createdByEmail: 'user2@arptc.cd',
          affectedUserId: 'user-2',
          affectedUserEmail: 'user2@arptc.cd',
          status: 'archived',
          lifecycleState: 'archived',
        }),
      ),
      setDoc(
        doc(firestore, 'incidentTickets/admin-own'),
        ticket({
          createdByUserId: 'admin-1',
          createdByEmail: 'admin@arptc.cd',
          affectedUserId: 'admin-1',
          affectedUserEmail: 'admin@arptc.cd',
        }),
      ),
      setDoc(
        doc(
          firestore,
          'incidentTickets/active-own/comments/public-comment',
        ),
        comment({ isInternal: false }),
      ),
      setDoc(
        doc(
          firestore,
          'incidentTickets/active-own/comments/internal-comment',
        ),
        comment({ isInternal: true }),
      ),
      setDoc(
        doc(
          firestore,
          'incidentTickets/active-own/attachments/attachment-1',
        ),
        attachment(),
      ),
      setDoc(
        doc(firestore, 'incidentTickets/active-own/auditLogs/audit-1'),
        auditLog(),
      ),
    ]);
  });
});

after(async () => {
  await environment.cleanup();
});

test('USER reads only owned tickets and uses an owner-scoped list query', async () => {
  const firestore = userFirestore('user-1', 'user1@arptc.cd');

  await assertSucceeds(getDoc(doc(firestore, 'incidentTickets/active-own')));
  await assertFails(getDoc(doc(firestore, 'incidentTickets/active-other')));

  const ownedActiveQuery = query(
    collection(firestore, 'incidentTickets'),
    where('affectedUserEmail', '==', 'user1@arptc.cd'),
    where('lifecycleState', '==', 'active'),
    where('isDeleted', '==', false),
  );
  const result = await assertSucceeds(getDocs(ownedActiveQuery));
  if (result.size !== 1 || result.docs[0].id !== 'active-own') {
    throw new Error('The USER query returned data outside its owner scope.');
  }

  await assertFails(getDocs(collection(firestore, 'incidentTickets')));
});

test('USER creates only the minimal open incident contract', async () => {
  const firestore = userFirestore('user-1', 'user1@arptc.cd');
  const ticketRef = doc(firestore, 'incidentTickets/new-user-ticket');

  await assertSucceeds(
    setDoc(ticketRef, {
      ...ticket({
        createdByUserId: 'user-1',
        createdByEmail: 'user1@arptc.cd',
        affectedUserId: 'user-1',
        affectedUserEmail: 'user1@arptc.cd',
      }),
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );

  await assertFails(
    setDoc(doc(firestore, 'incidentTickets/invalid-user-ticket'), {
      ...ticket({
        createdByUserId: 'user-1',
        createdByEmail: 'user1@arptc.cd',
        affectedUserId: 'user-2',
        affectedUserEmail: 'user2@arptc.cd',
      }),
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
  await assertFails(updateDoc(ticketRef, { title: 'Client-side escalation' }));
});

test('MANAGER operates active and closed tickets but cannot read archived', async () => {
  const firestore = userFirestore('manager-1', 'manager@arptc.cd');

  await assertSucceeds(getDoc(doc(firestore, 'incidentTickets/active-other')));
  await assertSucceeds(getDoc(doc(firestore, 'incidentTickets/closed-other')));
  await assertFails(getDoc(doc(firestore, 'incidentTickets/archived-other')));

  const activeQuery = query(
    collection(firestore, 'incidentTickets'),
    where('lifecycleState', '==', 'active'),
  );
  await assertSucceeds(getDocs(activeQuery));
  await assertFails(getDocs(collection(firestore, 'incidentTickets')));

  await assertSucceeds(
    updateDoc(doc(firestore, 'incidentTickets/active-other'), {
      categoryId: 'connectivity',
      updatedAt: serverTimestamp(),
    }),
  );
});

test('ADMIN reads only owned raw incidents and remains read-only', async () => {
  const firestore = userFirestore('admin-1', 'admin@arptc.cd');

  await assertSucceeds(
    getDoc(doc(firestore, 'incidentTickets/admin-own')),
  );
  await assertFails(getDoc(doc(firestore, 'incidentTickets/active-other')));
  await assertFails(getDoc(doc(firestore, 'incidentTickets/archived-other')));
  await assertFails(getDocs(collection(firestore, 'incidentTickets')));
  const ownQuery = query(
    collection(firestore, 'incidentTickets'),
    where('affectedUserEmail', '==', 'admin@arptc.cd'),
    where('lifecycleState', '==', 'active'),
    where('isDeleted', '==', false),
  );
  await assertSucceeds(getDocs(ownQuery));
  await assertFails(
    updateDoc(doc(firestore, 'incidentTickets/active-other'), {
      categoryId: 'admin-change',
      updatedAt: serverTimestamp(),
    }),
  );
  await assertSucceeds(
    setDoc(
      doc(firestore, 'incidentTickets/admin-created'),
      {
        ...ticket({
          createdByUserId: 'admin-1',
          createdByEmail: 'admin@arptc.cd',
          affectedUserId: 'admin-1',
          affectedUserEmail: 'admin@arptc.cd',
          createdByRole: 'ADMIN',
        }),
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      },
    ),
  );
});

test('comment queries mirror public/internal rule boundaries', async () => {
  const userDb = userFirestore('user-1', 'user1@arptc.cd');
  const comments = collection(
    userDb,
    'incidentTickets/active-own/comments',
  );
  const publicComments = query(
    comments,
    where('isInternal', '==', false),
    orderBy('createdAt', 'desc'),
  );

  const result = await assertSucceeds(getDocs(publicComments));
  if (result.size !== 1 || result.docs[0].id !== 'public-comment') {
    throw new Error('The public comment query returned an internal note.');
  }
  await assertFails(getDocs(query(comments, orderBy('createdAt', 'desc'))));

  const managerDb = userFirestore('manager-1', 'manager@arptc.cd');
  await assertSucceeds(
    getDocs(
      query(
        collection(
          managerDb,
          'incidentTickets/active-own/comments',
        ),
        orderBy('createdAt', 'desc'),
      ),
    ),
  );
});

test('comments, attachments, and audit history are append-only', async () => {
  const firestore = userFirestore('user-1', 'user1@arptc.cd');

  await assertSucceeds(
    addDoc(collection(firestore, 'incidentTickets/active-own/comments'), {
      body: 'Public update',
      createdByUserId: 'user-1',
      createdByEmail: 'user1@arptc.cd',
      isInternal: false,
      createdAt: serverTimestamp(),
    }),
  );
  await assertFails(
    addDoc(collection(firestore, 'incidentTickets/active-own/comments'), {
      body: 'Hidden update',
      createdByUserId: 'user-1',
      createdByEmail: 'user1@arptc.cd',
      isInternal: true,
      createdAt: serverTimestamp(),
    }),
  );
  await assertSucceeds(
    addDoc(collection(firestore, 'incidentTickets/active-own/attachments'), {
      fileName: 'evidence.pdf',
      uploadedByUserId: 'user-1',
      createdAt: serverTimestamp(),
    }),
  );
  await assertSucceeds(
    addDoc(collection(firestore, 'incidentTickets/active-own/auditLogs'), {
      action: 'commented',
      actorUserId: 'user-1',
      actorEmail: 'user1@arptc.cd',
      createdAt: serverTimestamp(),
    }),
  );

  await assertFails(
    updateDoc(
      doc(
        firestore,
        'incidentTickets/active-own/comments/public-comment',
      ),
      { body: 'Rewritten history' },
    ),
  );
  await assertFails(
    deleteDoc(
      doc(firestore, 'incidentTickets/active-own/auditLogs/audit-1'),
    ),
  );
});

test('ticket deletion is denied for every incident role', async () => {
  for (const [uid, email] of [
    ['user-1', 'user1@arptc.cd'],
    ['manager-1', 'manager@arptc.cd'],
    ['admin-1', 'admin@arptc.cd'],
  ]) {
    const firestore = userFirestore(uid, email);
    await assertFails(
      deleteDoc(doc(firestore, 'incidentTickets/active-own')),
    );
  }
});

function userFirestore(uid, email) {
  return environment
    .authenticatedContext(uid, { email, email_verified: true })
    .firestore();
}

function agent(role) {
  return {
    email: `${role.toLowerCase()}@arptc.cd`,
    isActive: true,
    modulePermissions: { ticketing: role },
  };
}

function ticket({
  createdByUserId,
  createdByEmail,
  affectedUserId,
  affectedUserEmail,
  createdByRole = 'USER',
  status = 'open',
  lifecycleState = 'active',
}) {
  const timestamp = Timestamp.fromDate(new Date('2026-07-01T08:00:00.000Z'));
  return {
    ticketNumber: 'INC-001',
    title: 'Connectivity issue',
    description: 'Unable to connect',
    status,
    lifecycleState,
    createdByRole,
    createdByUserId,
    createdByEmail,
    affectedUserId,
    affectedUserEmail,
    assignedToUserId: '',
    categoryId: '',
    impact: '',
    urgency: '',
    priority: '',
    createdAt: timestamp,
    updatedAt: timestamp,
    archivedAt: null,
    isDeleted: false,
  };
}

function comment({ isInternal }) {
  return {
    body: isInternal ? 'Internal note' : 'Public update',
    createdByUserId: 'manager-1',
    createdByEmail: 'manager@arptc.cd',
    isInternal,
    createdAt: Timestamp.fromDate(new Date('2026-07-01T09:00:00.000Z')),
  };
}

function attachment() {
  return {
    fileName: 'evidence.pdf',
    uploadedByUserId: 'user-1',
    createdAt: Timestamp.fromDate(new Date('2026-07-01T09:00:00.000Z')),
  };
}

function auditLog() {
  return {
    action: 'created',
    actorUserId: 'user-1',
    actorEmail: 'user1@arptc.cd',
    createdAt: Timestamp.fromDate(new Date('2026-07-01T08:00:00.000Z')),
  };
}
