'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  executeSecurityComplianceCommand,
} = require('../src/itsm_security_compliance_service');
const {
  SECURITY_COMPLIANCE_COMMANDS: C,
  validateSecurityComplianceCommand,
} = require('../src/itsm_security_compliance_validation');

const fieldValue = { serverTimestamp: () => 'server-time' };
const timestamp = { fromDate: (date) => date.toISOString() };
const user = actor('user-1', 'USER');
const admin = actor('admin-1', 'ADMIN');
const manager1 = actor('manager-1', 'MANAGER');
const manager2 = actor('manager-2', 'MANAGER');

test('finding lifecycle is transactional, audited, indexed, and replay safe', async () => {
  const db = fakeDatabase(seed());
  const create = input(C.createFinding, {
    findingId: 'finding-1',
    title: 'Unsupported operating system',
    description: 'An assigned endpoint is unsupported.',
    source: 'asset compliance scan',
    severity: 'high',
    risk: 'high',
    affectedAssetIds: ['asset-1'],
    dueAt: '2026-08-10T00:00:00Z',
  }, 'finding-create-1234');
  const first = await execute(db, manager1, create);
  const replay = await execute(db, manager1, create);
  assert.deepEqual(replay, first);
  assert.equal(db.document('securityFindings/finding-1').createdByUserId, 'manager-1');
  assert.equal(db.countPrefix('securityFindings/finding-1/auditLogs/'), 1);
  assert.equal(db.countPrefix('itsmCommandReceipts/'), 1);

  await execute(db, manager1, input(C.triageFinding, {
    findingId: 'finding-1', expectedRevision: 0,
    severity: 'critical', risk: 'critical',
    dueAt: '2026-08-05T00:00:00Z',
  }));
  await execute(db, manager1, input(C.assignFinding, {
    findingId: 'finding-1', expectedRevision: 1, ownerUserId: 'manager-2',
  }));
  await execute(db, manager2, input(C.planRemediation, {
    findingId: 'finding-1', expectedRevision: 2,
    remediationPlan: 'Upgrade the endpoint.',
    remediationLinks: [{ type: 'change_request', recordId: 'change-1' }],
  }));
  await execute(db, manager2, input(C.submitFindingValidation, {
    findingId: 'finding-1', expectedRevision: 3, comment: 'Ready.',
  }));
  await execute(db, manager1, input(C.validateFinding, {
    findingId: 'finding-1', expectedRevision: 4,
    result: 'failed', comment: 'Patch evidence is incomplete.',
  }));
  const finding = db.document('securityFindings/finding-1');
  assert.equal(finding.status, 'remediation');
  assert.equal(finding.validationResult, 'failed');
  assert.equal(finding.ownerUserId, 'manager-2');
  assert.equal(db.document('itsmWorkItemIndex/security_finding:finding-1').selfServiceVisible, false);
  assert(db.countPrefix('notificationEvents/') >= 3);
  assert(db.countPrefix('itsmAuditEvents/') >= 6);
});

test('services reject forged roles, stale revisions, and invalid transitions', async () => {
  const db = fakeDatabase(seed({
    'securityFindings/finding-1': {
      reference: 'SECF-1', status: 'detected', revision: 0,
    },
  }));
  await assert.rejects(
    execute(db, user, input(C.triageFinding, {
      findingId: 'finding-1', expectedRevision: 0,
      severity: 'high', risk: 'high',
    })),
    (error) => error.code === 'permission-denied',
  );
  await assert.rejects(
    execute(db, manager1, input(C.triageFinding, {
      findingId: 'finding-1', expectedRevision: 7,
      severity: 'high', risk: 'high',
    })),
    (error) => error.code === 'aborted',
  );
  await assert.rejects(
    execute(db, manager1, input(C.closeFinding, {
      findingId: 'finding-1', expectedRevision: 0, comment: 'No.',
    })),
    (error) => error.code === 'failed-precondition',
  );
});

test('risk acceptance records justification before finding closure', async () => {
  const db = fakeDatabase(seed({
    'securityFindings/finding-1': {
      reference: 'SECF-1', status: 'triaged', revision: 2,
      risk: 'medium', lifecycleState: 'active',
    },
  }));
  await execute(db, manager1, input(C.acceptFindingRisk, {
    findingId: 'finding-1', expectedRevision: 2,
    reason: 'Compensating monitoring accepted by security.',
    expiresAt: '2026-12-31T23:59:59Z',
  }));
  await execute(db, manager1, input(C.closeFinding, {
    findingId: 'finding-1', expectedRevision: 3,
    comment: 'Risk acceptance recorded.',
  }));
  const finding = db.document('securityFindings/finding-1');
  assert.equal(finding.status, 'closed');
  assert.equal(finding.lifecycleState, 'closed');
  assert.equal(finding.riskAcceptedByUserId, 'manager-1');
  assert.equal(finding.closedAt, 'server-time');
});

test('exception approval enforces ownership and independent designated approvers', async () => {
  const db = fakeDatabase(seed());
  await execute(db, user, input(C.createException, exceptionPayload('exception-1')));
  await execute(db, user, input(C.submitException, {
    exceptionId: 'exception-1', expectedRevision: 0,
  }));
  await assert.rejects(
    execute(db, admin, input(C.closeException, {
      exceptionId: 'exception-1', expectedRevision: 1, reason: 'Forged access.',
    })),
    (error) => error.code === 'permission-denied',
  );
  await assert.rejects(
    execute(db, manager1, input(C.requestExceptionApproval, {
      exceptionId: 'exception-1', expectedRevision: 1,
      approvalId: 'approval-bad', approverUserIds: ['user-1'],
    })),
    (error) => error.code === 'failed-precondition',
  );

  await execute(db, manager1, input(C.requestExceptionApproval, {
    exceptionId: 'exception-1', expectedRevision: 1,
    approvalId: 'approval-1', approverUserIds: ['manager-2'],
  }));
  await assert.rejects(
    execute(db, manager1, input(C.decideExceptionApproval, {
      exceptionId: 'exception-1', expectedRevision: 2,
      approvalId: 'approval-1', decision: 'approved', comment: 'Attempt.',
    })),
    (error) => error.code === 'permission-denied',
  );
  await execute(db, manager2, input(C.decideExceptionApproval, {
    exceptionId: 'exception-1', expectedRevision: 2,
    approvalId: 'approval-1', decision: 'approved', comment: 'Controls verified.',
  }));
  await execute(db, manager1, input(C.activateException, {
    exceptionId: 'exception-1', expectedRevision: 3,
  }));
  assert.equal(db.document('securityExceptions/exception-1').status, 'active');
  assert.equal(db.document('securityExceptions/exception-1').selfServiceVisible, true);
  assert.equal(db.document('securityExceptions/exception-1').requester.userId, 'user-1');
  assert.equal(
    db.document('securityExceptions/exception-1/approvals/approval-1').decidedByUserId,
    'manager-2',
  );
  assert.equal(db.countPrefix('securityExceptions/exception-1/approvalHistory/'), 1);
  const auditPaths = db.pathsWithPrefix(
    'securityExceptions/exception-1/auditLogs/',
  );
  assert.ok(auditPaths.length > 0);
  for (const path of auditPaths) {
    const audit = db.document(path);
    assert.equal(audit.confidentiality, 'internal');
    assert.equal(audit.requesterVisible, true);
    assert.equal(audit.isInternal, false);
  }
});

test('exception requester cannot be their sole approver even when requester is MANAGER', async () => {
  const db = fakeDatabase(seed());
  await execute(db, manager1, input(C.createException, exceptionPayload('exception-manager')));
  await execute(db, manager1, input(C.submitException, {
    exceptionId: 'exception-manager', expectedRevision: 0,
  }));
  await assert.rejects(
    execute(db, manager1, input(C.requestExceptionApproval, {
      exceptionId: 'exception-manager', expectedRevision: 1,
      approverUserIds: ['manager-1'],
    })),
    (error) => error.code === 'failed-precondition' && /requester/.test(error.message),
  );
});

test('security approval groups expand only active MANAGER members', async () => {
  const db = fakeDatabase(seed({
    'securityApprovalGroups/group-1': {
      status: 'active', memberUserIds: ['manager-2'],
    },
  }));
  await execute(db, user, input(C.createException, exceptionPayload('exception-group')));
  await execute(db, user, input(C.submitException, {
    exceptionId: 'exception-group', expectedRevision: 0,
  }));
  await execute(db, manager1, input(C.requestExceptionApproval, {
    exceptionId: 'exception-group', expectedRevision: 1,
    approverUserIds: [], approverGroupId: 'group-1',
  }));
  const approvalId = db.document('securityExceptions/exception-group').currentApprovalId;
  assert.deepEqual(
    db.document(`securityExceptions/exception-group/approvals/${approvalId}`).approverUserIds,
    ['manager-2'],
  );
});

test('approval groups exclude requester while retaining independent approvers', async () => {
  const db = fakeDatabase(seed({
    'securityApprovalGroups/group-mixed': {
      status: 'active', memberUserIds: ['manager-1', 'manager-2'],
    },
  }));
  await execute(db, manager1, input(C.createException, exceptionPayload('exception-mixed')));
  await execute(db, manager1, input(C.submitException, {
    exceptionId: 'exception-mixed', expectedRevision: 0,
  }));
  await execute(db, manager1, input(C.requestExceptionApproval, {
    exceptionId: 'exception-mixed', expectedRevision: 1,
    approverUserIds: [], approverGroupId: 'group-mixed',
  }));
  const exception = db.document('securityExceptions/exception-mixed');
  const approval = db.document(
    `securityExceptions/exception-mixed/approvals/${exception.currentApprovalId}`,
  );
  assert.deepEqual(approval.approverUserIds, ['manager-2']);
});

test('renewal creates a new version without mutating the original record', async () => {
  const db = fakeDatabase(seed({
    'securityExceptions/exception-1': {
      reference: 'SECX-1', title: 'Legacy control', requirementOrControl: 'MFA',
      scope: 'Gateway', riskDescription: 'Exposure', compensatingControls: [],
      requesterId: 'user-1', requesterName: 'user-1', requesterEmail: 'user-1@arptc.cd',
      confidentiality: 'confidential', status: 'active', revision: 4,
      renewalNumber: 1,
    },
  }));
  const result = await execute(db, user, input(C.renewException, {
    exceptionId: 'exception-1', expectedRevision: 4,
    newExceptionId: 'exception-2',
    businessJustification: 'Migration extended.',
    requestedStartAt: '2026-08-10T00:00:00Z',
    requestedEndAt: '2026-09-10T00:00:00Z',
    reviewAt: '2026-08-25T00:00:00Z',
  }));
  assert.equal(result.exceptionId, 'exception-2');
  assert.equal(db.document('securityExceptions/exception-2').renewalNumber, 2);
  assert.equal(db.document('securityExceptions/exception-2').selfServiceVisible, true);
  assert.equal(db.document('securityExceptions/exception-2').requester.userId, 'user-1');
  assert.equal(db.document('securityExceptions/exception-1').revision, 4);
});

test('renewal must extend the current exception period', async () => {
  const db = fakeDatabase(seed({
    'securityExceptions/exception-1': {
      requesterId: 'user-1', status: 'active', revision: 1,
      requestedEndAt: '2026-09-01T00:00:00Z',
    },
  }));
  await assert.rejects(
    execute(db, user, input(C.renewException, {
      exceptionId: 'exception-1', expectedRevision: 1,
      businessJustification: 'No extension.',
      requestedStartAt: '2026-08-01T00:00:00Z',
      requestedEndAt: '2026-08-20T00:00:00Z',
      reviewAt: '2026-08-10T00:00:00Z',
    })),
    (error) => error.code === 'failed-precondition' && /extend/.test(error.message),
  );
});

test('compliance uses trusted asset assignment and writes a minimal safe projection', async () => {
  const db = fakeDatabase(seed());
  const result = await execute(db, manager1, input(C.assessCompliance, {
    assessmentId: 'assessment-1',
    assetId: 'asset-1',
    assetTag: 'FORGED-TAG',
    assetName: 'Forged asset name',
    assignedUserId: 'admin-1',
    assignedUserName: 'Forged User',
    checks: [{
      control: 'patch_status', result: 'non_compliant',
      summary: 'Critical patches missing', evidenceIds: ['evidence-1'],
    }],
    remediationRequestId: 'request-1',
    evidenceIds: ['evidence-1'],
  }));
  const assessment = db.document('assetComplianceAssessments/assessment-1');
  assert.equal(assessment.assetTag, 'ASSET-001');
  assert.equal(assessment.assignedUserId, 'user-1');
  assert.equal(result.result, 'non_compliant');
  const projection = db.document(`assetComplianceSelfService/${result.projectionId}`);
  assert.equal(projection.assignedUserId, 'user-1');
  assert.equal(projection.status, 'action_required');
  assert.equal(Object.hasOwn(projection, 'checks'), false);
  assert.equal(Object.hasOwn(projection, 'evidenceIds'), false);
});

test('non-compliant assessments require remediation tracking', async () => {
  const db = fakeDatabase(seed());
  await assert.rejects(
    execute(db, manager1, input(C.assessCompliance, {
      assetId: 'asset-1', assetTag: 'A', assetName: 'Laptop',
      checks: [{ control: 'patch_status', result: 'non_compliant' }],
    })),
    (error) => error.code === 'failed-precondition',
  );
});

test('access review correction, decision, and revocation completion are isolated', async () => {
  const db = fakeDatabase(seed());
  await execute(db, manager1, input(C.createReviewCampaign, {
    campaignId: 'campaign-1', title: 'Quarterly access review',
    scope: 'ERP privileged access', systemId: 'erp', systemName: 'ERP',
    ownerUserId: 'manager-1',
    startsAt: '2026-08-01T00:00:00Z', dueAt: '2026-08-31T00:00:00Z',
    allowSelfServiceCorrection: true,
    reviewerUserIds: ['manager-2'], departmentIds: ['dept-1'],
  }));
  await execute(db, manager1, input(C.activateReviewCampaign, {
    campaignId: 'campaign-1', expectedRevision: 0,
  }));
  await execute(db, manager1, input(C.createReviewItem, {
    itemId: 'item-1', campaignId: 'campaign-1', subjectUserId: 'user-1',
    currentAccess: 'administrator', currentRole: 'ERP_ADMIN',
    departmentId: 'dept-1', departmentName: 'IT',
    reviewerUserId: 'manager-2', dueAt: '2026-08-20T00:00:00Z',
  }));
  const initialItem = db.document('accessReviewItems/item-1');
  assert.equal(initialItem.selfServiceVisible, true);
  assert.equal(initialItem.subjectUser.userId, 'user-1');
  assert.equal(initialItem.lifecycleState, 'active');
  assert.equal(initialItem.status, 'pending');
  assert.equal(initialItem.revision, 0);
  assert.equal(initialItem.updatedAt, 'server-time');
  await assert.rejects(
    execute(db, admin, input(C.requestAccessCorrection, {
      itemId: 'item-1', type: 'correction', reason: 'Not my record.',
    })),
    (error) => error.code === 'permission-denied',
  );
  await execute(db, user, input(C.requestAccessCorrection, {
    itemId: 'item-1', type: 'revocation', reason: 'Access is no longer needed.',
  }));
  const correctionPaths = db.pathsWithPrefix(
    'accessReviewItems/item-1/correctionRequests/',
  );
  assert.equal(correctionPaths.length, 1);
  assert.equal(db.document(correctionPaths[0]).requestedBy, 'user-1');
  assert.equal(db.document(correctionPaths[0]).requesterId, 'user-1');
  assert.equal(db.document(correctionPaths[0]).subjectUser.userId, 'user-1');
  assert.equal(db.document(correctionPaths[0]).selfServiceVisible, true);
  await assert.rejects(
    execute(db, manager1, input(C.decideReviewItem, {
      itemId: 'item-1', expectedRevision: 0, decision: 'revoke',
      justification: 'Remove access.', assignedToUserId: 'manager-1',
      taskDueAt: '2026-08-10T00:00:00Z',
    })),
    (error) => error.code === 'permission-denied',
  );
  const decision = await execute(db, manager2, input(C.decideReviewItem, {
    itemId: 'item-1', expectedRevision: 0, decision: 'revoke',
    justification: 'Remove access.', assignedToUserId: 'manager-1',
    taskDueAt: '2026-08-10T00:00:00Z',
  }));
  await execute(db, manager1, input(C.completeRevocationTask, {
    taskId: decision.revocationTaskId, expectedRevision: 0,
    completionEvidenceId: 'evidence-revoke-1', comment: 'Access removed.',
  }));
  assert.equal(db.document('accessReviewItems/item-1').completionStatus, 'completed');
  assert.equal(db.document('accessReviewItems/item-1').selfServiceVisible, true);
  assert.equal(db.document('accessReviewItems/item-1').subjectUser.userId, 'user-1');
  assert.equal(db.document(`accessRevocationTasks/${decision.revocationTaskId}`).status, 'completed');
  await execute(db, manager1, input(C.completeReviewCampaign, {
    campaignId: 'campaign-1', expectedRevision: 1,
  }));
  assert.equal(db.document('accessReviewCampaigns/campaign-1').status, 'completed');
});

function exceptionPayload(exceptionId) {
  return {
    exceptionId,
    title: 'Temporary legacy access', requirementOrControl: 'MFA-01',
    businessJustification: 'Migration window.', scope: 'Legacy gateway',
    riskDescription: 'Credential exposure.',
    compensatingControls: [{ id: 'control-1', description: 'Daily review', effective: true }],
    requestedStartAt: '2026-08-01T00:00:00Z',
    requestedEndAt: '2026-08-10T00:00:00Z',
    reviewAt: '2026-08-05T00:00:00Z',
  };
}

function actor(uid, role) {
  return { uid, role, displayName: uid, email: `${uid}@arptc.cd` };
}

let counter = 0;
function input(command, payload, key) {
  counter += 1;
  return validateSecurityComplianceCommand({
    command,
    idempotencyKey: key || `security-test-${counter.toString().padStart(8, '0')}`,
    payload,
  }, command);
}

function execute(db, actorValue, command) {
  return executeSecurityComplianceCommand({
    db, fieldValue, timestamp, actor: actorValue, command,
  });
}

function seed(extra = {}) {
  return {
    'agents/user-1': agent('user-1', 'USER'),
    'agents/admin-1': agent('admin-1', 'ADMIN'),
    'agents/manager-1': agent('manager-1', 'MANAGER'),
    'agents/manager-2': agent('manager-2', 'MANAGER'),
    'assets/asset-1': {
      assetTag: 'ASSET-001', name: 'Trusted laptop',
      assignedUserId: 'user-1', assignedUserName: 'User One',
    },
    ...extra,
  };
}

function agent(uid, role) {
  return {
    email: `${uid}@arptc.cd`, firstName: uid, isActive: true,
    modulePermissions: { ticketing: role },
  };
}

function fakeDatabase(initial) {
  const documents = new Map(Object.entries(initial).map(([path, value]) => [path, clone(value)]));
  return {
    collection: (path) => collection(path),
    runTransaction: async (callback) => callback(transaction()),
    document: (path) => clone(documents.get(path)),
    countPrefix: (prefix) => [...documents.keys()].filter((path) => path.startsWith(prefix)).length,
    pathsWithPrefix: (prefix) => [...documents.keys()].filter((path) => path.startsWith(prefix)),
  };

  function collection(path) {
    return {
      path,
      doc: (id) => reference(`${path}/${id}`),
      where: (field, operator, value) => query(path, [{ field, operator, value }]),
    };
  }

  function reference(path) {
    return {
      path,
      id: path.split('/').at(-1),
      collection: (name) => collection(`${path}/${name}`),
    };
  }

  function query(path, filters, maximum = Infinity) {
    return {
      _query: true, path, filters, maximum,
      where: (field, operator, value) => query(path, [...filters, { field, operator, value }], maximum),
      limit: (value) => query(path, filters, value),
    };
  }

  function transaction() {
    let wrote = false;
    return {
      get: async (target) => {
        if (wrote) throw new Error('Firestore transactions require reads before writes.');
        return target._query ? querySnapshot(target) : snapshot(target.path);
      },
      create: (ref, value) => {
        wrote = true;
        if (documents.has(ref.path)) throw new Error(`already exists: ${ref.path}`);
        documents.set(ref.path, clone(value));
      },
      set: (ref, value, options) => {
        wrote = true;
        const existing = options && options.merge ? documents.get(ref.path) || {} : {};
        documents.set(ref.path, clone({ ...existing, ...value }));
      },
      update: (ref, value) => {
        wrote = true;
        if (!documents.has(ref.path)) throw new Error(`missing: ${ref.path}`);
        documents.set(ref.path, clone({ ...documents.get(ref.path), ...value }));
      },
    };
  }

  function snapshot(path) {
    const value = documents.get(path);
    return {
      exists: value !== undefined,
      id: path.split('/').at(-1),
      data: () => clone(value),
      get: (field) => clone(value && value[field]),
    };
  }

  function querySnapshot(target) {
    const depth = target.path.split('/').length + 1;
    const docs = [...documents.entries()]
      .filter(([path]) => path.startsWith(`${target.path}/`) && path.split('/').length === depth)
      .filter(([, value]) => target.filters.every(({ field, operator, value: expected }) => {
        if (operator === '!=') return value[field] !== expected;
        if (operator === '==') return value[field] === expected;
        throw new Error(`unsupported operator ${operator}`);
      }))
      .slice(0, target.maximum)
      .map(([path]) => snapshot(path));
    return { docs, empty: docs.length === 0 };
  }
}

function clone(value) {
  if (value === undefined) return undefined;
  if (value instanceof Date) return new Date(value);
  if (Array.isArray(value)) return value.map(clone);
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.entries(value).map(([key, item]) => [key, clone(item)]));
  }
  return value;
}
