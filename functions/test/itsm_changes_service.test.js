'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  calculateChangeRisk,
  executeChangesCommand,
  findCalendarConflicts,
} = require('../src/itsm_changes_service');
const {
  ITSM_CHANGES_COMMANDS,
  validateChangesCommand,
} = require('../src/itsm_changes_validation');

const fieldValue = { serverTimestamp: () => 'server-time' };
const timestamp = {
  now: () => new Date('2026-08-01T10:00:00.000Z'),
  fromDate: (date) => date.toISOString(),
};
const user = actor('user-1', 'USER', 'User One', 'user1@arptc.cd');
const admin = actor('admin-1', 'ADMIN', 'Admin One', 'admin1@arptc.cd');
const manager1 = actor(
  'manager-1',
  'MANAGER',
  'Manager One',
  'manager1@arptc.cd',
);
const manager2 = actor(
  'manager-2',
  'MANAGER',
  'Manager Two',
  'manager2@arptc.cd',
);

test('draft initialization pins a published workflow and is replay safe', async () => {
  const db = fakeDatabase(baseSeed());
  const value = draftCommand('normal', 'draft-replay-1234');
  const first = await execute(db, user, value);
  const replay = await execute(db, user, value);

  assert.deepEqual(replay, first);
  const change = db.document(`changeRequests/${first.changeId}`);
  assert.equal(change.requesterId, 'user-1');
  assert.equal(change.requesterName, 'User One');
  assert.equal(change.workflowVersion, 1);
  assert.equal(change.workflowVersionDocumentId, 'version_1');
  assert.equal(change.status, 'draft');
  assert.equal(change.revision, 0);
  assert.match(change.changeNumber, /^CHG-20260801-/);
  assert.equal(db.pathsMatching(/^changeRequests\/[^/]+$/).length, 1);
  assert.equal(db.pathsMatching(/\/auditLogs\//).length, 1);
  const auditPath = db.pathsMatching(/\/auditLogs\//)[0];
  assert.equal(db.document(auditPath).requesterVisible, true);
  assert.equal(db.document(auditPath).isInternal, false);
  assert.equal(db.pathsMatching(/^itsmAuditEvents\//).length, 1);
  assert.equal(db.pathsMatching(/^itsmCommandReceipts\//).length, 1);
  assert.equal(
    db.document(`itsmWorkItemIndex/change_request:${first.changeId}`).requesterId,
    'user-1',
  );
});

test('USER and ADMIN can save, submit, and cancel only their own changes', async () => {
  const db = fakeDatabase(baseSeed());
  const created = await execute(db, user, draftCommand('normal', 'owner-draft-1234'));

  await assert.rejects(
    () => execute(db, admin, command(
      ITSM_CHANGES_COMMANDS.saveDraft,
      'cross-user-save-1234',
      {
        changeId: created.changeId,
        expectedRevision: 0,
        title: 'Cross-user edit',
        description: 'Must not be allowed.',
        justification: 'Not the requester.',
      },
    )),
    (error) => error.code === 'permission-denied',
  );

  await execute(db, user, command(
    ITSM_CHANGES_COMMANDS.saveDraft,
    'owner-save-1234',
    {
      changeId: created.changeId,
      expectedRevision: 0,
      title: 'Updated title',
      description: 'Updated description.',
      justification: 'Updated justification.',
    },
  ));
  await execute(db, user, command(
    ITSM_CHANGES_COMMANDS.submit,
    'owner-submit-1234',
    { changeId: created.changeId, expectedRevision: 1 },
  ));
  const submitted = db.document(`changeRequests/${created.changeId}`);
  assert.equal(submitted.status, 'submitted');
  assert.equal(submitted.revision, 2);
  const notification = db.documentsMatching(/^notificationEvents\//)[0];
  assert.deepEqual(notification.target, {
    type: 'MODULE_ROLE',
    moduleKey: 'ticketing',
    roles: ['MANAGER'],
  });

  await execute(db, user, command(
    ITSM_CHANGES_COMMANDS.cancel,
    'owner-cancel-1234',
    {
      changeId: created.changeId,
      expectedRevision: 2,
      reason: 'Business need withdrawn.',
    },
  ));
  assert.equal(db.document(`changeRequests/${created.changeId}`).status, 'cancelled');
});

test('MANAGER assessment resolves the owner and references authoritatively and calculates risk', async () => {
  const db = fakeDatabase(baseSeed());
  const created = await createSubmittedChange(db, user, 'normal', 'assess-base');
  const assessed = await execute(db, manager1, assessmentCommand(
    created.changeId,
    1,
    'critical',
    'high',
    'high',
  ));
  const change = db.document(`changeRequests/${created.changeId}`);
  assert.equal(assessed.risk, 'critical');
  assert.equal(assessed.riskScore, 15);
  assert.equal(change.ownerUserId, 'manager-2');
  assert.equal(change.ownerName, 'Authoritative Manager Two');
  assert.equal(change.ownerEmail, 'manager2@arptc.cd');
  assert.equal(change.status, 'assessment');
  assert.deepEqual(change.affectedServiceIds, ['network']);
  assert.equal(db.documentsMatching(/^notificationEvents\//).at(-1).eventType,
    'change.owner_assigned');

  assert.deepEqual(calculateChangeRisk({
    impact: 'low',
    urgency: 'low',
    complexity: 'low',
  }), { level: 'low', score: 2 });
});

test('normal approval uses a configured MANAGER group and immutable history', async () => {
  const db = fakeDatabase(baseSeed());
  const created = await createAssessedChange(db, user, 'normal', 'approval-base');
  const requested = await execute(db, manager1, command(
    ITSM_CHANGES_COMMANDS.requestApproval,
    'approval-request-1234',
    { changeId: created.changeId, expectedRevision: 2 },
  ));
  assert.equal(requested.status, 'awaiting_approval');
  assert.equal(requested.approvalDueAt, '2026-08-04T10:00:00.000Z');
  const approval = db.document(
    `changeRequests/${created.changeId}/approvals/${requested.approvalId}`,
  );
  assert.equal(approval.assignedGroupId, 'cab-core');
  assert.deepEqual(approval.approverUserIds, ['manager-1', 'manager-2']);
  assert.equal(approval.status, 'pending');
  assert.equal(db.pathsMatching(/\/approvalHistory\//).length, 1);

  const decision = await execute(db, manager2, command(
    ITSM_CHANGES_COMMANDS.decideApproval,
    'approval-decision-1234',
    {
      changeId: created.changeId,
      approvalId: requested.approvalId,
      expectedRevision: 3,
      decision: 'approved',
      comment: 'Approved with monitoring.',
      conditions: ['Monitor the network for two hours.'],
    },
  ));
  assert.equal(decision.status, 'approved');
  assert.equal(db.pathsMatching(/\/approvalHistory\//).length, 2);
  assert.equal(
    db.document(`changeRequests/${created.changeId}`).approvalConditions[0],
    'Monitor the network for two hours.',
  );

  await assert.rejects(
    () => execute(db, manager1, command(
      ITSM_CHANGES_COMMANDS.decideApproval,
      'approval-replay-other-1234',
      {
        changeId: created.changeId,
        approvalId: requested.approvalId,
        expectedRevision: 4,
        decision: 'approved',
        comment: 'Try to overwrite immutable history.',
      },
    )),
    (error) => error.code === 'failed-precondition',
  );
  assert.equal(db.pathsMatching(/\/approvalHistory\//).length, 2);
});

test('normal and emergency requesters cannot approve their own changes', async () => {
  for (const changeType of ['normal', 'emergency']) {
    const db = fakeDatabase(baseSeed());
    const created = await createAssessedChange(
      db,
      manager1,
      changeType,
      `self-${changeType}`,
    );
    const requested = await execute(db, manager2, command(
      ITSM_CHANGES_COMMANDS.requestApproval,
      `request-${changeType}-1234`,
      { changeId: created.changeId, expectedRevision: 2 },
    ));
    await assert.rejects(
      () => execute(db, manager1, command(
        ITSM_CHANGES_COMMANDS.decideApproval,
        `self-decision-${changeType}-1234`,
        {
          changeId: created.changeId,
          approvalId: requested.approvalId,
          expectedRevision: 3,
          decision: 'approved',
          comment: 'Self approval must fail.',
        },
      )),
      (error) => error.code === 'permission-denied' && /requester/.test(error.message),
    );
    assert.equal(
      db.document(
        `changeRequests/${created.changeId}/approvals/${requested.approvalId}`,
      ).status,
      'pending',
    );
    if (changeType === 'emergency') {
      assert.equal(
        db.documentsMatching(/\/approvalHistory\//)[0].emergencyDecision,
        true,
      );
    }
  }
});

test('clarification returns a change to assessment and rejection closes it', async () => {
  for (const [decision, expectedStatus, expectedLifecycle] of [
    ['clarification_requested', 'assessment', 'active'],
    ['rejected', 'rejected', 'closed'],
  ]) {
    const db = fakeDatabase(baseSeed());
    const created = await createAssessedChange(db, user, 'normal', `decision-${decision}`);
    const requested = await execute(db, manager1, command(
      ITSM_CHANGES_COMMANDS.requestApproval,
      `request-${decision}-1234`,
      { changeId: created.changeId, expectedRevision: 2 },
    ));
    await execute(db, manager2, command(
      ITSM_CHANGES_COMMANDS.decideApproval,
      `decide-${decision}-1234`,
      {
        changeId: created.changeId,
        approvalId: requested.approvalId,
        expectedRevision: 3,
        decision,
        comment: 'Decision explanation.',
      },
    ));
    const change = db.document(`changeRequests/${created.changeId}`);
    assert.equal(change.status, expectedStatus);
    assert.equal(change.lifecycleState, expectedLifecycle);
  }
});

test('standard changes bypass CAB only when the pinned workflow is pre-authorized', async () => {
  const seed = baseSeed();
  seed['workflowDefinitions/change-workflow/versions/version_1']
    .standardPreAuthorized = true;
  const db = fakeDatabase(seed);
  const created = await createAssessedChange(db, user, 'standard', 'standard-preauth');
  const approved = await execute(db, manager1, command(
    ITSM_CHANGES_COMMANDS.requestApproval,
    'standard-preauth-1234',
    { changeId: created.changeId, expectedRevision: 2 },
  ));
  assert.equal(approved.status, 'approved');
  assert.equal(db.pathsMatching(/\/approvals\//).length, 0);
  assert.equal(db.document(`changeRequests/${created.changeId}`).approvalState,
    'pre_authorized');
});

test('CAB meetings resolve participants from the configured MANAGER group', async () => {
  const db = fakeDatabase(baseSeed({
    'changeRequests/change-cab': assessedChange({ revision: 3 }),
  }));
  const saved = await execute(db, manager1, command(
    ITSM_CHANGES_COMMANDS.saveCabMeeting,
    'cab-meeting-save-1234',
    {
      changeId: 'change-cab',
      expectedRevision: 3,
      approvalGroupId: 'cab-core',
      title: 'Core CAB',
      agenda: 'Review high-risk network changes.',
      participantUserIds: ['manager-1', 'manager-2'],
      scheduledStartAt: '2026-08-05T09:00:00.000Z',
      scheduledEndAt: '2026-08-05T10:00:00.000Z',
      notes: 'Initial agenda.',
    },
  ));
  const meeting = db.document(
    `changeRequests/change-cab/cabMeetings/${saved.meetingId}`,
  );
  assert.equal(meeting.participants[1].name, 'Authoritative Manager Two');
  assert.equal(meeting.decisionDeadlineAt, '2026-08-06T10:00:00.000Z');
  assert.equal(meeting.createdByUserId, 'manager-1');
  assert.equal(saved.revision, 4);
  const cabAuditPath = db.pathsMatching(/\/auditLogs\//)[0];
  assert.equal(db.document(cabAuditPath).requesterVisible, false);
  assert.equal(db.document(cabAuditPath).isInternal, true);
});

test('scheduling maintains a bounded calendar projection with conflicts', async () => {
  const db = fakeDatabase(baseSeed({
    'changeRequests/change-schedule': approvedChange(),
  }));
  const scheduled = await execute(db, manager1, command(
    ITSM_CHANGES_COMMANDS.schedule,
    'schedule-change-1234',
    {
      changeId: 'change-schedule',
      expectedRevision: 4,
      plannedStartAt: '2026-08-10T08:00:00.000Z',
      plannedEndAt: '2026-08-10T10:00:00.000Z',
      expectedDowntimeMinutes: 30,
      publishMaintenance: true,
    },
  ), {
    findCalendarConflicts: async ({ limit }) => {
      assert.equal(limit, 50);
      return [{ changeId: 'change-conflict' }];
    },
  });
  assert.equal(scheduled.status, 'scheduled');
  assert.equal(scheduled.hasConflict, true);
  assert.equal(scheduled.conflictCount, 1);
  const calendar = db.document('changeCalendarEntries/change-schedule');
  assert.equal(calendar.publishMaintenance, true);
  assert.equal(calendar.hasConflict, true);
  assert.equal(calendar.isActive, true);
  assert.equal(calendar.calendarRoute,
    '/services/itsm/changes/calendar?changeId=change-schedule');
});

test('default conflict discovery uses a capped single-field date window', async () => {
  const clauses = [];
  const query = {
    where(field, operator, value) {
      clauses.push(['where', field, operator, value]);
      return this;
    },
    orderBy(field) {
      clauses.push(['orderBy', field]);
      return this;
    },
    limit(value) {
      clauses.push(['limit', value]);
      return this;
    },
  };
  const conflicts = await findCalendarConflicts({
    db: { collection: () => query },
    transaction: {
      get: async () => ({
        docs: [
          calendarDocument('other-1', '2026-08-10T09:00:00.000Z', ['network']),
          calendarDocument('ended', '2026-08-10T07:00:00.000Z', ['network']),
          calendarDocument('other-service', '2026-08-10T09:00:00.000Z', ['email']),
        ],
      }),
    },
    timestamp,
    changeId: 'change-1',
    start: new Date('2026-08-10T08:00:00.000Z'),
    end: new Date('2026-08-10T10:00:00.000Z'),
    affectedServiceIds: ['network'],
    affectedCiIds: [],
    limit: 999,
  });
  assert.deepEqual(conflicts.map((entry) => entry.changeId), ['other-1']);
  assert.deepEqual(clauses, [
    ['where', 'plannedStartAt', '>=', '2026-05-12T08:00:00.000Z'],
    ['where', 'plannedStartAt', '<', '2026-08-10T10:00:00.000Z'],
    ['orderBy', 'plannedStartAt'],
    ['limit', 50],
  ]);
});

test('implementation, result, PIR, and closure preserve the governed lifecycle', async () => {
  const db = fakeDatabase(baseSeed({
    'changeRequests/change-implementation': {
      ...approvedChange(),
      status: 'scheduled',
      revision: 5,
      plannedStartAt: '2026-08-10T08:00:00.000Z',
      plannedEndAt: '2026-08-10T10:00:00.000Z',
    },
  }));
  await execute(db, manager1, command(
    ITSM_CHANGES_COMMANDS.startImplementation,
    'implementation-start-1234',
    {
      changeId: 'change-implementation',
      expectedRevision: 5,
      comment: 'Implementation bridge opened.',
    },
  ));
  await execute(db, manager1, command(
    ITSM_CHANGES_COMMANDS.recordImplementationResult,
    'implementation-result-1234',
    {
      changeId: 'change-implementation',
      expectedRevision: 6,
      outcome: 'succeeded',
      summary: 'Deployment and validation succeeded.',
      evidenceAttachmentIds: ['evidence-1'],
    },
  ));
  await execute(db, manager2, command(
    ITSM_CHANGES_COMMANDS.recordPostImplementationReview,
    'pir-record-1234',
    {
      changeId: 'change-implementation',
      expectedRevision: 7,
      outcome: 'successful',
      summary: 'Objectives achieved.',
      lessonsLearned: 'Extend the monitoring window.',
      followUpActions: ['Update the operational runbook.'],
      evidenceAttachmentIds: ['pir-evidence-1'],
    },
  ));
  const closed = await execute(db, manager2, command(
    ITSM_CHANGES_COMMANDS.close,
    'change-close-1234',
    {
      changeId: 'change-implementation',
      expectedRevision: 8,
      comment: 'PIR accepted.',
    },
  ));
  assert.equal(closed.status, 'closed');
  assert.equal(closed.revision, 9);
  const change = db.document('changeRequests/change-implementation');
  assert.equal(change.implementationOutcome, 'succeeded');
  assert.equal(change.postImplementationReview.outcome, 'successful');
  assert.equal(change.lifecycleState, 'closed');
  assert.equal(db.document('changeCalendarEntries/change-implementation').isActive,
    false);
});

test('failed and rolled-back outcomes become terminal without a PIR', async () => {
  for (const outcome of ['failed', 'rolled_back']) {
    const db = fakeDatabase(baseSeed({
      [`changeRequests/change-${outcome}`]: {
        ...approvedChange(),
        status: 'implementation',
        revision: 6,
      },
    }));
    const completed = await execute(db, manager1, command(
      ITSM_CHANGES_COMMANDS.recordImplementationResult,
      `result-${outcome}-1234`,
      {
        changeId: `change-${outcome}`,
        expectedRevision: 6,
        outcome,
        summary: `Implementation ${outcome}.`,
      },
    ));
    assert.equal(completed.status, outcome);
    assert.equal(db.document(`changeRequests/change-${outcome}`).lifecycleState,
      'closed');
  }
});

test('stale revisions and direct USER operational service calls are rejected', async () => {
  const db = fakeDatabase(baseSeed({
    'changeRequests/change-stale': assessedChange({ revision: 2 }),
  }));
  await assert.rejects(
    () => execute(db, manager1, command(
      ITSM_CHANGES_COMMANDS.requestApproval,
      'stale-revision-1234',
      { changeId: 'change-stale', expectedRevision: 1 },
    )),
    (error) => error.code === 'aborted',
  );
  await assert.rejects(
    () => execute(db, user, assessmentCommand('change-stale', 2)),
    (error) => error.code === 'permission-denied',
  );
});

async function createSubmittedChange(db, requester, type, key) {
  const created = await execute(db, requester, draftCommand(type, `${key}-draft-1234`));
  await execute(db, requester, command(
    ITSM_CHANGES_COMMANDS.submit,
    `${key}-submit-1234`,
    { changeId: created.changeId, expectedRevision: 0 },
  ));
  return created;
}

async function createAssessedChange(db, requester, type, key) {
  const created = await createSubmittedChange(db, requester, type, key);
  await execute(db, manager2, assessmentCommand(created.changeId, 1));
  return created;
}

function draftCommand(type, idempotencyKey) {
  return command(ITSM_CHANGES_COMMANDS.initializeDraft, idempotencyKey, {
    workflowDefinitionId: 'change-workflow',
    changeType: type,
    title: `${type} network change`,
    description: 'Upgrade the network edge.',
    justification: 'Improve service reliability.',
  });
}

function assessmentCommand(
  changeId,
  expectedRevision,
  impact = 'high',
  urgency = 'medium',
  complexity = 'medium',
) {
  return command(ITSM_CHANGES_COMMANDS.assess, `assess-${changeId}-1234`, {
    changeId,
    expectedRevision,
    ownerUserId: 'manager-2',
    affectedServiceIds: ['network'],
    affectedCiIds: ['router-1'],
    affectedAssetIds: ['asset-1'],
    relatedIncidentIds: ['incident-1'],
    relatedRequestIds: ['request-1'],
    impact,
    urgency,
    complexity,
    expectedDowntimeMinutes: 30,
    implementationPlan: 'Deploy during the approved window.',
    testPlan: 'Run connectivity and service checks.',
    communicationPlan: 'Notify affected departments.',
    rollbackPlan: 'Restore the previous firmware.',
    approvalGroupId: 'cab-core',
  });
}

function command(type, idempotencyKey, payload) {
  return validateChangesCommand({ command: type, idempotencyKey, payload });
}

function execute(db, principal, value, dependencies) {
  return executeChangesCommand({
    db,
    fieldValue,
    timestamp,
    actor: principal,
    command: value,
    dependencies,
  });
}

function actor(uid, role, displayName, email) {
  return Object.freeze({ uid, role, displayName, email });
}

function baseSeed(extra = {}) {
  return {
    'workflowDefinitions/change-workflow': {
      status: 'published',
      publishedVersion: 1,
      supportedChangeTypes: ['standard', 'normal', 'emergency'],
    },
    'workflowDefinitions/change-workflow/versions/version_1': {
      status: 'published',
      supportedChangeTypes: ['standard', 'normal', 'emergency'],
      defaultApprovalGroupId: 'cab-core',
      approvalDeadlineHours: 72,
      standardPreAuthorized: false,
    },
    'agents/manager-1': managerAgent('One'),
    'agents/manager-2': managerAgent('Two'),
    'changeApprovalGroups/cab-core': {
      name: 'Core CAB',
      isActive: true,
      memberUserIds: ['manager-1', 'manager-2'],
      approvalDeadlineHours: 72,
      decisionDeadlineHours: 24,
    },
    'itServices/network': { name: 'Network', isActive: true },
    'configurationItems/router-1': { name: 'Core Router' },
    'assets/asset-1': { assetTag: 'RTR-001' },
    'incidentTickets/incident-1': { ticketNumber: 'INC-1' },
    'serviceRequests/request-1': { requestNumber: 'REQ-1' },
    ...extra,
  };
}

function managerAgent(suffix) {
  return {
    firstName: 'Authoritative',
    name: 'Manager',
    postName: suffix,
    email: `manager${suffix === 'One' ? '1' : '2'}@arptc.cd`,
    isActive: true,
    modulePermissions: { ticketing: 'MANAGER' },
  };
}

function assessedChange(overrides = {}) {
  return {
    id: 'change-cab',
    changeNumber: 'CHG-20260801-CAB001',
    title: 'Network change',
    description: 'Description',
    justification: 'Justification',
    changeType: 'normal',
    status: 'assessment',
    lifecycleState: 'active',
    requesterId: 'user-1',
    requesterName: 'User One',
    requesterEmail: 'user1@arptc.cd',
    ownerUserId: 'manager-2',
    ownerName: 'Authoritative Manager Two',
    ownerEmail: 'manager2@arptc.cd',
    workflowDefinitionId: 'change-workflow',
    workflowVersion: 1,
    workflowVersionDocumentId: 'version_1',
    affectedServiceIds: ['network'],
    affectedCiIds: ['router-1'],
    affectedAssetIds: ['asset-1'],
    impact: 'high',
    urgency: 'medium',
    complexity: 'medium',
    risk: 'high',
    riskScore: 8,
    implementationPlan: 'Deploy.',
    testPlan: 'Test.',
    communicationPlan: 'Notify.',
    rollbackPlan: 'Rollback.',
    approvalGroupId: 'cab-core',
    revision: 2,
    createdAt: 'created-time',
    updatedAt: 'updated-time',
    ...overrides,
  };
}

function approvedChange() {
  return {
    ...assessedChange(),
    id: 'change-schedule',
    status: 'approved',
    approvalState: 'approved',
    revision: 4,
  };
}

function calendarDocument(id, plannedEndAt, affectedServiceIds) {
  return {
    id,
    data: () => ({
      plannedEndAt,
      affectedServiceIds,
      affectedCiIds: [],
      isActive: true,
    }),
  };
}

function fakeDatabase(seed = {}) {
  const documents = new Map(
    Object.entries(seed).map(([path, value]) => [path, clone(value)]),
  );

  class Reference {
    constructor(path) {
      this.path = path;
      this.id = path.split('/').at(-1);
    }
    collection(name) { return new Collection(`${this.path}/${name}`); }
  }
  class Collection {
    constructor(path) { this.path = path; }
    doc(id) { return new Reference(`${this.path}/${id}`); }
  }
  const snapshot = (reference) => {
    const value = documents.get(reference.path);
    return {
      id: reference.id,
      ref: reference,
      exists: value !== undefined,
      data: () => clone(value),
      get: (field) => value && value[field],
    };
  };
  return {
    collection(name) { return new Collection(name); },
    document(path) { return clone(documents.get(path)); },
    pathsMatching(pattern) {
      return [...documents.keys()].filter((path) => pattern.test(path));
    },
    documentsMatching(pattern) {
      return [...documents.entries()]
        .filter(([path]) => pattern.test(path))
        .map(([, value]) => clone(value));
    },
    async runTransaction(callback) {
      const writes = [];
      const transaction = {
        get: async (reference) => snapshot(reference),
        create: (reference, value) => writes.push({
          kind: 'create',
          reference,
          value,
        }),
        set: (reference, value, options) => writes.push({
          kind: 'set',
          reference,
          value,
          options,
        }),
        update: (reference, value) => writes.push({
          kind: 'update',
          reference,
          value,
        }),
      };
      const result = await callback(transaction);
      const next = new Map([...documents.entries()].map(([path, value]) => [
        path,
        clone(value),
      ]));
      for (const write of writes) {
        const path = write.reference.path;
        if (write.kind === 'create') {
          if (next.has(path)) throw new Error(`Document already exists: ${path}`);
          next.set(path, clone(write.value));
        } else if (write.kind === 'update') {
          if (!next.has(path)) throw new Error(`Document does not exist: ${path}`);
          next.set(path, { ...next.get(path), ...clone(write.value) });
        } else {
          next.set(path, write.options && write.options.merge
            ? { ...(next.get(path) || {}), ...clone(write.value) }
            : clone(write.value));
        }
      }
      documents.clear();
      for (const [path, value] of next) documents.set(path, value);
      return result;
    },
  };
}

function clone(value) {
  return value === undefined ? undefined : structuredClone(value);
}
