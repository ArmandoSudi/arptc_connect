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
  doc,
  getDoc,
  getDocs,
  limit,
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
        doc(firestore, 'serviceCatalogItems/published'),
        catalogue('published'),
      ),
      setDoc(
        doc(firestore, 'serviceCatalogItems/draft'),
        catalogue('draft'),
      ),
      setDoc(
        doc(firestore, 'knowledgeCategories/published'),
        configuration('published'),
      ),
      setDoc(
        doc(firestore, 'knowledgeCategories/draft'),
        configuration('draft'),
      ),
      setDoc(
        doc(firestore, 'knowledgeArticles/employee'),
        article('published', 'employee'),
      ),
      setDoc(
        doc(firestore, 'knowledgeArticles/dsi'),
        article('published', 'dsi_only'),
      ),
      setDoc(
        doc(firestore, 'knowledgeArticles/draft'),
        article('draft', 'employee'),
      ),
      setDoc(
        doc(firestore, 'knowledgeArticles/employee/versions/v1'),
        configuration('published'),
      ),
      setDoc(
        doc(firestore, 'knowledgeArticles/employee/versions/draft-v2'),
        configuration('draft'),
      ),
      setDoc(
        doc(firestore, 'knowledgeArticles/employee/feedback/user-1'),
        {
          userId: 'user-1',
          isHelpful: true,
        },
      ),
      setDoc(
        doc(firestore, 'knowledgeArticles/employee/views/view-1'),
        {
          viewedByUserId: 'user-1',
        },
      ),
      setDoc(
        doc(firestore, 'knowledgeArticles/employee/versions/v1/attachments/public'),
        {
          articleId: 'employee',
          versionId: 'v1',
          isInternal: false,
          storagePath:
            'itsm/knowledgeArticles/employee/versions/v1/attachments/public/file.pdf',
        },
      ),
      setDoc(
        doc(firestore, 'knowledgeArticles/employee/versions/v1/attachments/internal'),
        {
          articleId: 'employee',
          versionId: 'v1',
          isInternal: true,
          storagePath:
            'itsm/knowledgeArticles/employee/versions/v1/attachments/internal/file.pdf',
        },
      ),
      setDoc(
        doc(firestore, 'serviceRequests/own'),
        serviceRequest('user-1'),
      ),
      setDoc(
        doc(firestore, 'serviceRequests/other'),
        serviceRequest('user-2'),
      ),
      setDoc(
        doc(firestore, 'serviceRequests/admin-own'),
        serviceRequest('admin-1'),
      ),
      setDoc(
        doc(firestore, 'serviceRequests/own/tasks/task-1'),
        {
          status: 'pending',
          isInternal: true,
        },
      ),
      setDoc(
        doc(firestore, 'serviceRequests/own/approvals/approval-1'),
        {
          status: 'pending',
        },
      ),
      setDoc(
        doc(firestore, 'serviceRequests/own/auditLogs/audit-1'),
        {
          eventType: 'service_request.submitted',
          isInternal: false,
        },
      ),
      setDoc(
        doc(firestore, 'itsmWorkItemIndex/service_request:own'),
        {
          ...serviceRequest('user-1'),
          id: 'own',
          type: 'service_request',
          selfServiceVisible: true,
        },
      ),
    ]);
  });
});

after(async () => {
  await environment.cleanup();
});

test('self-service reads only published active catalogue entries', async () => {
  for (const uid of ['user-1', 'admin-1']) {
    const firestore = userFirestore(uid);
    await assertSucceeds(
      getDoc(doc(firestore, 'serviceCatalogItems/published')),
    );
    await assertFails(
      getDoc(doc(firestore, 'serviceCatalogItems/draft')),
    );
  }

  const manager = userFirestore('manager-1');
  await assertSucceeds(
    getDoc(doc(manager, 'serviceCatalogItems/published')),
  );
  await assertSucceeds(getDoc(doc(manager, 'serviceCatalogItems/draft')));
});

test('service requests are callable-created and owner-scoped', async () => {
  const user = userFirestore('user-1');
  await assertSucceeds(getDoc(doc(user, 'serviceRequests/own')));
  await assertFails(getDoc(doc(user, 'serviceRequests/other')));
  await assertFails(
    setDoc(doc(user, 'serviceRequests/direct-submit'), {
      requesterId: 'user-1',
      status: 'submitted',
      lifecycleState: 'active',
      confidentiality: 'INTERNAL',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );

  const admin = userFirestore('admin-1');
  await assertSucceeds(
    getDoc(doc(admin, 'serviceRequests/admin-own')),
  );
  await assertFails(getDoc(doc(admin, 'serviceRequests/other')));

  const manager = userFirestore('manager-1');
  await assertSucceeds(getDoc(doc(manager, 'serviceRequests/other')));
  await assertFails(
    setDoc(doc(manager, 'serviceRequests/manager-direct'), {
      requesterId: 'manager-1',
      status: 'submitted',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
});

test('bounded owner and manager operational queries cannot escape scope', async () => {
  const user = userFirestore('user-1');
  const ownQuery = query(
    collection(user, 'serviceRequests'),
    where('requesterId', '==', 'user-1'),
    orderBy('updatedAt', 'desc'),
    limit(25),
  );
  const own = await assertSucceeds(getDocs(ownQuery));
  if (own.size !== 1 || own.docs[0].id !== 'own') {
    throw new Error('Owner query escaped its requester boundary.');
  }
  await assertFails(
    getDocs(query(collection(user, 'serviceRequests'), limit(25))),
  );

  const manager = userFirestore('manager-1');
  const operational = await assertSucceeds(
    getDocs(query(
      collection(manager, 'serviceRequests'),
      where('lifecycleState', '==', 'active'),
      orderBy('updatedAt', 'desc'),
      limit(25),
    )),
  );
  if (operational.size !== 3) {
    throw new Error('MANAGER did not receive the operational queue.');
  }
});

test('knowledge self-service sees employee publications, MANAGER manages content', async () => {
  for (const uid of ['user-1', 'admin-1']) {
    const firestore = userFirestore(uid);
    await assertSucceeds(
      getDoc(doc(firestore, 'knowledgeArticles/employee')),
    );
    await assertFails(getDoc(doc(firestore, 'knowledgeArticles/dsi')));
    await assertFails(getDoc(doc(firestore, 'knowledgeArticles/draft')));
    await assertSucceeds(
      getDoc(doc(
        firestore,
        'knowledgeArticles/employee/versions/v1',
      )),
    );
    await assertFails(
      getDoc(doc(
        firestore,
        'knowledgeArticles/employee/versions/draft-v2',
      )),
    );
  }

  const manager = userFirestore('manager-1');
  await assertSucceeds(getDoc(doc(manager, 'knowledgeArticles/dsi')));
  await assertSucceeds(getDoc(doc(manager, 'knowledgeArticles/draft')));
  await assertFails(
    setDoc(doc(manager, 'knowledgeArticles/new-draft'), {
      title: 'Reset a password',
      status: 'draft',
      visibility: 'employee',
      viewCount: 0,
      feedbackCount: 0,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
  await assertFails(
    updateDoc(doc(manager, 'knowledgeArticles/draft'), {
      title: 'Updated draft',
      updatedAt: serverTimestamp(),
    }),
  );
  await assertFails(
    updateDoc(doc(manager, 'knowledgeArticles/employee'), {
      viewCount: 999,
      updatedAt: serverTimestamp(),
    }),
  );
});

test('knowledge usage, feedback, indexes, audit, approvals and tasks are server-only', async () => {
  const user = userFirestore('user-1');
  await assertSucceeds(
    getDoc(doc(user, 'knowledgeArticles/employee/feedback/user-1')),
  );
  await assertFails(
    setDoc(
      doc(user, 'knowledgeArticles/employee/feedback/user-1'),
      { isHelpful: false },
    ),
  );
  await assertFails(
    setDoc(
      doc(user, 'knowledgeArticles/employee/views/forged'),
      { viewedByUserId: 'user-1' },
    ),
  );
  await assertFails(
    updateDoc(doc(user, 'itsmWorkItemIndex/service_request:own'), {
      status: 'closed',
    }),
  );
  await assertFails(
    updateDoc(doc(user, 'serviceRequests/own/tasks/task-1'), {
      status: 'completed',
    }),
  );
  await assertFails(
    updateDoc(
      doc(user, 'serviceRequests/own/approvals/approval-1'),
      { status: 'approved' },
    ),
  );
  await assertFails(
    updateDoc(doc(user, 'serviceRequests/own/auditLogs/audit-1'), {
      actorUserId: 'user-1',
    }),
  );
});

test('knowledge attachment metadata follows article visibility', async () => {
  const user = userFirestore('user-1');
  await assertSucceeds(
    getDoc(doc(
      user,
      'knowledgeArticles/employee/versions/v1/attachments/public',
    )),
  );
  await assertFails(
    getDoc(doc(
      user,
      'knowledgeArticles/employee/versions/v1/attachments/internal',
    )),
  );

  const manager = userFirestore('manager-1');
  await assertSucceeds(
    getDoc(doc(
      manager,
      'knowledgeArticles/employee/versions/v1/attachments/internal',
    )),
  );
});

function userFirestore(uid) {
  return environment
    .authenticatedContext(uid, {
      email: `${uid}@arptc.cd`,
      email_verified: true,
    })
    .firestore();
}

function agent(role) {
  return {
    firstName: 'Test',
    name: role,
    email: `${role.toLowerCase()}@arptc.cd`,
    isActive: true,
    modulePermissions: { ticketing: role },
  };
}

function catalogue(status) {
  return {
    name: `${status} item`,
    status,
    isActive: true,
    titleLower: `${status} item`,
    createdAt: new Date('2026-01-01T00:00:00Z'),
    updatedAt: new Date('2026-01-01T00:00:00Z'),
  };
}

function configuration(status) {
  return {
    name: status,
    status,
    state: status,
    isActive: true,
    createdAt: new Date('2026-01-01T00:00:00Z'),
    updatedAt: new Date('2026-01-01T00:00:00Z'),
  };
}

function article(status, visibility) {
  return {
    title: `${status} ${visibility}`,
    titleLower: `${status} ${visibility}`,
    status,
    state: status,
    visibility,
    viewCount: 0,
    usageCount: 0,
    feedbackCount: 0,
    helpfulCount: 0,
    notHelpfulCount: 0,
    createdAt: new Date('2026-01-01T00:00:00Z'),
    updatedAt: new Date('2026-01-01T00:00:00Z'),
  };
}

function serviceRequest(requesterId) {
  return {
    requesterId,
    requestNumber: `REQ-${requesterId}`,
    status: 'submitted',
    lifecycleState: 'active',
    confidentiality: 'INTERNAL',
    selfServiceVisible: true,
    createdAt: new Date('2026-01-01T00:00:00Z'),
    updatedAt: new Date('2026-01-02T00:00:00Z'),
  };
}
