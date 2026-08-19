'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  ORGANIZATION_COMMANDS,
  auditOrganizationArchitecture,
  createInitialAgentPlacement,
  executeOrganizationCommand,
  refreshAgentProjections,
} = require('../src/organization_service');

const actor = { uid: 'manager-1' };
const fieldValue = { serverTimestamp: () => 'server-time' };
const timestamp = {
  fromDate: (value) => new Date(value),
  now: () => new Date('2026-08-11T08:00:00.000Z'),
};

test('command dispatcher rejects missing actors and unsupported commands before any database write', async () => {
  const db = fakeDatabase();
  await assert.rejects(
    () => executeOrganizationCommand({
      db,
      fieldValue,
      timestamp,
      command: ORGANIZATION_COMMANDS.createOrganization,
      payload: { commandId: 'missing-actor', code: 'ORG', name: 'Organization' },
      actor: null,
    }),
    hasCode('unauthenticated'),
  );
  await assert.rejects(
    () => executeOrganizationCommand({
      db,
      fieldValue,
      timestamp,
      command: 'deleteOrganizationPermanently',
      payload: { commandId: 'unsupported-command' },
      actor,
    }),
    hasCode('invalid-argument'),
  );
  assert.deepEqual(db.allPaths(), []);
});

test('creates a transactional Department -> Service -> Bureau hierarchy and rejects invalid parents and duplicate codes atomically', async () => {
  const db = fakeDatabase();
  const organization = await execute(db, ORGANIZATION_COMMANDS.createOrganization, {
    code: ' arptc ',
    name: 'ARPTC',
    description: 'National regulator',
  }, 'create-org');
  const organizationId = organization.organizationId;

  assert.equal(db.document(`organizations/${organizationId}`).status, 'ACTIVE');
  assert.equal(
    db.document('organizationCodeLocks/ARPTC').organizationId,
    organizationId,
  );

  const department = await execute(db, ORGANIZATION_COMMANDS.createOrganizationUnit, {
    organizationId,
    type: 'DEPARTMENT',
    code: 'D-IT',
    name: 'Information Technology',
  }, 'create-department');
  const service = await execute(db, ORGANIZATION_COMMANDS.createOrganizationUnit, {
    organizationId,
    type: 'SERVICE',
    parentUnitId: department.organizationUnitId,
    code: 'S-OPS',
    name: 'IT Operations',
  }, 'create-service');
  const bureau = await execute(db, ORGANIZATION_COMMANDS.createOrganizationUnit, {
    organizationId,
    type: 'BUREAU',
    parentUnitId: service.organizationUnitId,
    code: 'B-HD',
    name: 'Help Desk',
  }, 'create-bureau');

  assert.deepEqual(
    db.document(`organizationUnits/${bureau.organizationUnitId}`).pathUnitIds,
    [department.organizationUnitId, service.organizationUnitId, bureau.organizationUnitId],
  );
  assert.deepEqual(
    db.document(`organizationUnits/${bureau.organizationUnitId}`).pathNames,
    ['Information Technology', 'IT Operations', 'Help Desk'],
  );

  const beforeInvalid = db.allPaths();
  await assert.rejects(
    () => execute(db, ORGANIZATION_COMMANDS.createOrganizationUnit, {
      organizationId,
      type: 'BUREAU',
      parentUnitId: department.organizationUnitId,
      code: 'B-SKIP',
      name: 'Skipped Level',
    }, 'invalid-skipped-parent'),
    hasCode('failed-precondition'),
  );
  assert.deepEqual(db.allPaths(), beforeInvalid);

  const otherOrganization = await execute(
    db,
    ORGANIZATION_COMMANDS.createOrganization,
    { code: 'OTHER', name: 'Other Organization' },
    'create-other-org',
  );
  const beforeCrossOrganization = db.allPaths();
  await assert.rejects(
    () => execute(db, ORGANIZATION_COMMANDS.createOrganizationUnit, {
      organizationId: otherOrganization.organizationId,
      type: 'SERVICE',
      parentUnitId: department.organizationUnitId,
      code: 'S-CROSS',
      name: 'Cross Organization Service',
    }, 'invalid-cross-org-parent'),
    hasCode('failed-precondition'),
  );
  assert.deepEqual(db.allPaths(), beforeCrossOrganization);

  const beforeDuplicate = db.allPaths();
  await assert.rejects(
    () => execute(db, ORGANIZATION_COMMANDS.createOrganizationUnit, {
      organizationId,
      type: 'SERVICE',
      parentUnitId: department.organizationUnitId,
      code: 'S-OPS',
      name: 'Duplicate Operations',
    }, 'duplicate-unit-code'),
    hasCode('already-exists'),
  );
  assert.deepEqual(db.allPaths(), beforeDuplicate);
  assert.equal(db.documentsMatching(/^organizationAuditEvents\//).length, 5);
});

test('updates organization code locks and propagates a unit rename through bounded hierarchy, assignment, agent, and directory projections', async () => {
  const db = fakeDatabase({
    ...organizationSeed(),
    'organizationCodeLocks/ARPTC': {
      organizationId: 'org-arptc',
      code: 'ARPTC',
    },
    'organizationUnitCodeLocks/org-arptc:D-IT': {
      organizationId: 'org-arptc',
      unitId: 'department-it',
      code: 'D-IT',
    },
    'agents/agent-1': {
      ...placedAgent('agent-1'),
      primaryAssignmentId: 'member-primary',
    },
    'agentDirectory/agent-1': {
      displayName: 'Aline Mbuyi Kanku',
      organizationId: 'org-arptc',
      primaryOrganizationUnitId: 'bureau-helpdesk',
      primaryOrganizationUnitName: 'Help Desk',
      organizationPathNames: [
        'Information Technology',
        'IT Operations',
        'Help Desk',
      ],
    },
    'organizationAssignments/member-primary': assignmentDocument({
      agentId: 'agent-1',
      unitId: 'bureau-helpdesk',
    }),
  });

  await execute(db, ORGANIZATION_COMMANDS.updateOrganization, {
    organizationId: 'org-arptc',
    code: 'ARPTC-CONNECT',
    name: 'ARPTC Connect',
    description: 'Updated regulator metadata',
    status: 'ACTIVE',
  }, 'update-organization');
  assert.equal(
    db.document('organizationCodeLocks/ARPTC').organizationId,
    'org-arptc',
  );
  assert.equal(
    db.document('organizationCodeLocks/ARPTC-CONNECT').organizationId,
    'org-arptc',
  );
  assert.equal(
    db.document('agents/agent-1').organizationName,
    'ARPTC Connect',
  );
  assert.equal(
    db.document('agentDirectory/agent-1').organizationName,
    'ARPTC Connect',
  );

  await execute(db, ORGANIZATION_COMMANDS.updateOrganizationUnit, {
    organizationId: 'org-arptc',
    organizationUnitId: 'department-it',
    code: 'D-DIGITAL',
    name: 'Digital Technologies',
    description: 'Technology department',
    status: 'ACTIVE',
  }, 'rename-department');

  assert.equal(
    db.document('organizationUnitCodeLocks/org-arptc:D-IT').unitId,
    'department-it',
  );
  assert.equal(
    db.document('organizationUnitCodeLocks/org-arptc:D-DIGITAL').unitId,
    'department-it',
  );
  assert.deepEqual(
    db.document('organizationUnits/bureau-helpdesk').pathNames,
    ['Digital Technologies', 'IT Operations', 'Help Desk'],
  );
  assert.deepEqual(
    db.document('organizationAssignments/member-primary').pathNames,
    ['Information Technology', 'IT Operations', 'Help Desk'],
  );
  assert.equal(db.document('agents/agent-1').department, 'Digital Technologies');
  assert.deepEqual(
    db.document('agentDirectory/agent-1').organizationPathNames,
    ['Digital Technologies', 'IT Operations', 'Help Desk'],
  );
  assert.deepEqual(eventTypes(db), [
    'ORGANIZATION_UPDATED',
    'ORGANIZATION_UNIT_UPDATED',
  ]);
});

test('moves a bounded unit subtree, refreshes active agent scopes, and preserves assignment history', async () => {
  const agent = {
    ...placedAgent('agent-1'),
    primaryAssignmentId: 'assignment-1',
  };
  const db = fakeDatabase({
    ...organizationSeed(),
    'organizationUnits/department-administration': unitDocument({
      id: 'department-administration',
      type: 'DEPARTMENT',
      code: 'D-ADM',
      name: 'Administration',
      pathUnitIds: ['department-administration'],
      pathNames: ['Administration'],
    }),
    'agents/agent-1': agent,
    'agentDirectory/agent-1': { displayName: 'Aline Mbuyi Kanku' },
    'agentAuthorizationIndex/agent-1': {
      organizationId: 'org-arptc',
      primaryUnitId: 'bureau-helpdesk',
      isActive: true,
      scopeKeys: agent.scopeKeys,
      moduleRoleKeys: ['ticketing:MANAGER'],
      scopeRoleKeys: agent.scopeKeys.map(
        (scope) => `${scope}|ticketing:MANAGER`,
      ),
      schemaVersion: 2,
    },
    'organizationAssignments/assignment-1': assignmentDocument({
      agentId: 'agent-1',
      unitId: 'bureau-helpdesk',
    }),
  });

  const result = await execute(db, ORGANIZATION_COMMANDS.moveOrganizationUnit, {
    organizationId: 'org-arptc',
    organizationUnitId: 'service-operations',
    parentUnitId: 'department-administration',
    reason: 'Operations now reports to Administration',
  }, 'move-operations-service');

  assert.equal(result.descendantCount, 1);
  assert.equal(result.affectedAgentCount, 1);
  assert.deepEqual(
    db.document('organizationUnits/service-operations').pathUnitIds,
    ['department-administration', 'service-operations'],
  );
  assert.deepEqual(
    db.document('organizationUnits/bureau-helpdesk').pathUnitIds,
    [
      'department-administration',
      'service-operations',
      'bureau-helpdesk',
    ],
  );
  assert.equal(
    db.document('agents/agent-1').departmentId,
    'department-administration',
  );
  assert.ok(db.document('agentAuthorizationIndex/agent-1').scopeKeys.includes(
    'unit:department-administration',
  ));
  assert.deepEqual(
    db.document('organizationAssignments/assignment-1').pathUnitIds,
    ['department-it', 'service-operations', 'bureau-helpdesk'],
  );
  assert.equal(eventTypes(db).at(-1), 'ORGANIZATION_UNIT_MOVED');

  await assert.rejects(
    () => execute(db, ORGANIZATION_COMMANDS.moveOrganizationUnit, {
      organizationId: 'org-arptc',
      organizationUnitId: 'service-operations',
      parentUnitId: 'bureau-helpdesk',
      reason: 'Invalid cycle',
    }, 'move-cycle'),
    hasCode('failed-precondition'),
  );
});

test('archives a dependency-free unit and then its organization while retaining append-only audit evidence', async () => {
  const department = organizationSeed()['organizationUnits/department-it'];
  const db = fakeDatabase({
    'organizations/org-arptc': organizationSeed()['organizations/org-arptc'],
    'organizationUnits/department-it': department,
    'organizationUnitCodeLocks/org-arptc:D-IT': {
      organizationId: 'org-arptc',
      unitId: 'department-it',
      code: 'D-IT',
    },
  });

  await execute(db, ORGANIZATION_COMMANDS.archiveOrganizationUnit, {
    organizationId: 'org-arptc',
    organizationUnitId: 'department-it',
    reason: 'Structure retired',
  }, 'archive-empty-unit');
  assert.equal(db.document('organizationUnits/department-it').status, 'ARCHIVED');
  assert.equal(
    db.document('organizationUnitCodeLocks/org-arptc:D-IT').unitId,
    'department-it',
  );

  await execute(db, ORGANIZATION_COMMANDS.archiveOrganization, {
    organizationId: 'org-arptc',
    reason: 'Organization retired',
  }, 'archive-empty-organization');
  assert.equal(db.document('organizations/org-arptc').status, 'ARCHIVED');
  assert.deepEqual(eventTypes(db), [
    'ORGANIZATION_UNIT_ARCHIVED',
    'ORGANIZATION_ARCHIVED',
  ]);
});

test('initial agent creation writes the private profile, immutable assignment, safe directory, authorization projection, and audit atomically', async () => {
  const db = fakeDatabase(organizationSeed());
  const commandPayload = { email: 'aline@arptc.cd' };
  const input = {
    db,
    fieldValue,
    timestamp,
    agentId: 'agent-new',
    agent: agentProfile({ modulePermissions: { ticketing: 'MANAGER', news: 'NONE' } }),
    organizationId: 'org-arptc',
    unitId: 'bureau-helpdesk',
    startsAt: new Date('2026-08-01T00:00:00.000Z'),
    reason: 'Initial placement',
    actorUid: actor.uid,
    commandId: 'create-agent-new',
    commandPayload,
  };
  const result = await createInitialAgentPlacement(input);
  const replay = await createInitialAgentPlacement(input);

  const assignment = db.document(`organizationAssignments/${result.assignmentId}`);
  const privateAgent = db.document('agents/agent-new');
  const directory = db.document('agentDirectory/agent-new');
  const authorization = db.document('agentAuthorizationIndex/agent-new');

  assert.equal(assignment.status, 'ACTIVE');
  assert.equal(assignment.assignmentType, 'MEMBER');
  assert.equal(assignment.isPrimary, true);
  assert.equal(assignment.unitId, 'bureau-helpdesk');
  assert.equal(privateAgent.primaryAssignmentId, result.assignmentId);
  assert.equal(privateAgent.sex, 'female');
  assert.equal(privateAgent.departmentId, 'department-it');
  assert.equal(privateAgent.serviceId, 'service-operations');
  assert.equal(privateAgent.bureauId, 'bureau-helpdesk');
  assert.equal(directory.displayName, 'Aline Mbuyi Kanku');
  assert.equal(directory.modulePermissions, undefined);
  assert.deepEqual(authorization.moduleRoleKeys, ['ticketing:MANAGER']);
  assert.ok(authorization.scopeRoleKeys.includes(
    'unit:bureau-helpdesk|ticketing:MANAGER',
  ));
  assert.equal(
    db.documentsMatching(/^organizationAuditEvents\//)[0].eventType,
    'AGENT_CREATED_AND_ASSIGNED',
  );
  assert.equal(replay.replayed, true);
  assert.equal(replay.assignmentId, result.assignmentId);
  assert.equal(db.pathsMatching(/^organizationAssignments\//).length, 1);
  assert.equal(db.pathsMatching(/^organizationAuditEvents\//).length, 1);

  const invalidDb = fakeDatabase({
    ...organizationSeed(),
    'organizationUnits/bureau-helpdesk': {
      ...organizationSeed()['organizationUnits/bureau-helpdesk'],
      status: 'INACTIVE',
    },
  });
  await assert.rejects(
    () => createInitialAgentPlacement({
      db: invalidDb,
      fieldValue,
      timestamp,
      agentId: 'agent-invalid',
      agent: agentProfile(),
      organizationId: 'org-arptc',
      unitId: 'bureau-helpdesk',
      actorUid: actor.uid,
      commandId: 'create-agent-invalid',
      commandPayload: { email: 'invalid@arptc.cd' },
    }),
    hasCode('failed-precondition'),
  );
  assert.equal(invalidDb.document('agents/agent-invalid'), undefined);
  assert.equal(invalidDb.pathsMatching(/^organizationAssignments\//).length, 0);
});

test('initial agent creation can atomically appoint the agent as permanent unit head', async () => {
  const db = fakeDatabase(organizationSeed());
  const input = {
    db,
    fieldValue,
    timestamp,
    agentId: 'agent-department-head',
    agent: agentProfile(),
    organizationId: 'org-arptc',
    unitId: 'department-it',
    startsAt: new Date('2026-08-01T00:00:00.000Z'),
    reason: 'Department leadership appointment',
    assignAsHead: true,
    actorUid: actor.uid,
    commandId: 'create-department-head',
    commandPayload: {
      email: 'department.head@arptc.cd',
      assignAsHead: true,
    },
  };

  const result = await createInitialAgentPlacement(input);
  const replay = await createInitialAgentPlacement(input);
  const unit = db.document('organizationUnits/department-it');
  const leadership = db.document(
    `organizationAssignments/${result.leadershipAssignmentId}`,
  );

  assert.equal(unit.headUserId, 'agent-department-head');
  assert.equal(unit.headAssignmentId, result.leadershipAssignmentId);
  assert.equal(leadership.assignmentType, 'HEAD');
  assert.equal(leadership.isPrimary, false);
  assert.equal(leadership.unitType, 'DEPARTMENT');
  assert.equal(replay.leadershipAssignmentId, result.leadershipAssignmentId);
  assert.equal(db.pathsMatching(/^organizationAssignments\//).length, 2);
  assert.equal(db.pathsMatching(/^organizationAuditEvents\//).length, 1);
});

test('refreshes safe directory and authorization projections from requested private profile updates', async () => {
  const db = fakeDatabase({
    ...organizationSeed(),
    'agents/agent-1': placedAgent('agent-1'),
    'agentDirectory/agent-1': { displayName: 'Old Name' },
    'agentAuthorizationIndex/agent-1': { moduleRoleKeys: [] },
  });

  const input = {
    db,
    fieldValue,
    agentId: 'agent-1',
    actorUid: actor.uid,
    commandId: 'update-agent-1',
    commandPayload: { uid: 'agent-1', firstName: 'Grace' },
    updates: {
      firstName: 'Grace',
      name: 'Kabongo',
      postName: '',
      sex: 'female',
      email: 'grace.kabongo@arptc.cd',
      modulePermissions: { news: 'REVIEWER', ticketing: 'USER' },
    },
  };
  const first = await refreshAgentProjections(input);
  const replay = await refreshAgentProjections(input);

  assert.equal(db.document('agentDirectory/agent-1').displayName, 'Grace Kabongo');
  assert.equal(
    db.document('agentDirectory/agent-1').email,
    'grace.kabongo@arptc.cd',
  );
  assert.deepEqual(
    db.document('agentAuthorizationIndex/agent-1').moduleRoleKeys.sort(),
    ['news:REVIEWER', 'ticketing:USER'],
  );
  assert.equal(
    db.document('agentAuthorizationIndex/agent-1').scopeRoleKeys.length,
    8,
  );
  assert.equal(db.document('agents/agent-1').firstName, 'Grace');
  assert.equal(db.document('agents/agent-1').sex, 'female');
  assert.equal(first.replayed, false);
  assert.equal(replay.replayed, true);
  assert.equal(db.pathsMatching(/^organizationAuditEvents\//).length, 1);
  assert.equal(
    db.document('agents/agent-1').email,
    'grace.kabongo@arptc.cd',
  );
});

test('job titles remain descriptive and cannot create leadership authority', async () => {
  const db = fakeDatabase({
    ...organizationSeed(),
    'agents/agent-1': {
      ...placedAgent('agent-1'),
      primaryAssignmentId: 'member-primary',
    },
    'organizationAssignments/member-primary': assignmentDocument({
      agentId: 'agent-1',
      unitId: 'bureau-helpdesk',
    }),
  });

  await refreshAgentProjections({
    db,
    fieldValue,
    agentId: 'agent-1',
    actorUid: actor.uid,
    commandId: 'job-title-not-authority',
    commandPayload: { uid: 'agent-1', jobTitle: 'Head of Bureau' },
    updates: { jobTitle: 'Head of Bureau' },
  });

  assert.equal(db.document('agents/agent-1').jobTitle, 'Head of Bureau');
  assert.equal(
    db.document('organizationUnits/bureau-helpdesk').headAssignmentId,
    null,
  );
  assert.equal(
    db.documentsMatching(/^organizationAssignments\//)
      .filter((assignment) => assignment.assignmentType === 'HEAD').length,
    0,
  );
});

test('initial assignment and transfer preserve assignment history and refresh every current-placement projection', async () => {
  const db = fakeDatabase({
    ...organizationSeed(),
    ...secondServiceSeed(),
    'agents/agent-1': agentProfile(),
  });
  const assigned = await execute(db, ORGANIZATION_COMMANDS.assignAgentOrganization, {
    organizationId: 'org-arptc',
    organizationUnitId: 'bureau-helpdesk',
    agentId: 'agent-1',
    startsAt: '2026-08-01T00:00:00.000Z',
    reason: 'Initial organization assignment',
  }, 'assign-agent');

  assert.equal(
    db.document(`organizationAssignments/${assigned.assignmentId}`).status,
    'ACTIVE',
  );
  assert.equal(db.document('agents/agent-1').bureauId, 'bureau-helpdesk');

  const transferred = await execute(db, ORGANIZATION_COMMANDS.transferAgentOrganization, {
    organizationId: 'org-arptc',
    organizationUnitId: 'service-security',
    agentId: 'agent-1',
    startsAt: '2026-08-11T08:00:00.000Z',
    reason: 'Transfer to security',
  }, 'transfer-agent');

  const oldAssignment = db.document(`organizationAssignments/${assigned.assignmentId}`);
  const newAssignment = db.document(
    `organizationAssignments/${transferred.assignmentId}`,
  );
  const privateAgent = db.document('agents/agent-1');
  const directory = db.document('agentDirectory/agent-1');
  const authorization = db.document('agentAuthorizationIndex/agent-1');

  assert.equal(oldAssignment.status, 'ENDED');
  assert.deepEqual(oldAssignment.endsAt, new Date('2026-08-11T08:00:00.000Z'));
  assert.equal(newAssignment.status, 'ACTIVE');
  assert.equal(newAssignment.unitId, 'service-security');
  assert.equal(privateAgent.primaryAssignmentId, transferred.assignmentId);
  assert.equal(privateAgent.serviceId, 'service-security');
  assert.equal(privateAgent.bureauId, '');
  assert.equal(directory.primaryOrganizationUnitName, 'Cybersecurity');
  assert.equal(authorization.primaryUnitId, 'service-security');
  assert.deepEqual(authorization.scopeKeys, [
    'org:org-arptc',
    'unit:department-it',
    'unit:service-security',
  ]);
  assert.deepEqual(
    eventTypes(db),
    ['AGENT_ORGANIZATION_ASSIGNED', 'AGENT_ORGANIZATION_TRANSFERRED'],
  );

  await assert.rejects(
    () => execute(db, ORGANIZATION_COMMANDS.assignAgentOrganization, {
      organizationId: 'org-arptc',
      organizationUnitId: 'bureau-helpdesk',
      agentId: 'agent-1',
      reason: 'Invalid second initial placement',
    }, 'assign-already-assigned'),
    hasCode('failed-precondition'),
  );
});

test('transfer can atomically place and appoint an agent at the selected hierarchy level', async () => {
  const db = fakeDatabase({
    ...organizationSeed(),
    ...secondServiceSeed(),
    'organizationUnits/service-operations': {
      ...organizationSeed()['organizationUnits/service-operations'],
      headUserId: 'agent-1',
      headAssignmentId: 'old-service-head',
    },
    'agents/agent-1': {
      ...placedAgent('agent-1'),
      primaryAssignmentId: 'member-primary',
    },
    'organizationAssignments/member-primary': assignmentDocument({
      agentId: 'agent-1',
      unitId: 'bureau-helpdesk',
    }),
    'organizationAssignments/old-service-head': assignmentDocument({
      agentId: 'agent-1',
      unitId: 'service-operations',
      assignmentType: 'HEAD',
      isPrimary: false,
      unitType: 'SERVICE',
      unitName: 'IT Operations',
      pathUnitIds: ['department-it', 'service-operations'],
    }),
  });

  const result = await execute(
    db,
    ORGANIZATION_COMMANDS.transferAgentOrganization,
    {
      organizationId: 'org-arptc',
      organizationUnitId: 'service-security',
      agentId: 'agent-1',
      startsAt: '2026-08-11T08:00:00.000Z',
      reason: 'Appointed to lead Cybersecurity',
      assignAsHead: true,
    },
    'transfer-service-head',
  );

  const target = db.document('organizationUnits/service-security');
  const leadership = db.document(
    `organizationAssignments/${result.leadershipAssignmentId}`,
  );
  assert.equal(target.headUserId, 'agent-1');
  assert.equal(target.headAssignmentId, result.leadershipAssignmentId);
  assert.equal(leadership.assignmentType, 'HEAD');
  assert.equal(leadership.unitId, 'service-security');
  assert.equal(db.document('organizationAssignments/member-primary').status, 'ENDED');
  assert.equal(db.document('organizationAssignments/old-service-head').status, 'ENDED');
  assert.equal(db.document('organizationUnits/service-operations').headUserId, null);
  assert.equal(db.document('organizationUnits/service-operations').headAssignmentId, null);
  assert.equal(db.document('agents/agent-1').primaryOrganizationUnitId, 'service-security');
});

test('leadership conflict rejects a transfer without changing placement history', async () => {
  const db = fakeDatabase({
    ...organizationSeed(),
    ...secondServiceSeed(),
    'organizationUnits/service-security': {
      ...secondServiceSeed()['organizationUnits/service-security'],
      headUserId: 'existing-head',
      headAssignmentId: 'existing-head-assignment',
    },
    'agents/agent-1': {
      ...placedAgent('agent-1'),
      primaryAssignmentId: 'member-primary',
    },
    'organizationAssignments/member-primary': assignmentDocument({
      agentId: 'agent-1',
      unitId: 'bureau-helpdesk',
    }),
  });

  await assert.rejects(
    () => execute(
      db,
      ORGANIZATION_COMMANDS.transferAgentOrganization,
      {
        organizationId: 'org-arptc',
        organizationUnitId: 'service-security',
        agentId: 'agent-1',
        startsAt: '2026-08-11T08:00:00.000Z',
        reason: 'Conflicting leadership appointment',
        assignAsHead: true,
      },
      'transfer-head-conflict',
    ),
    hasCode('failed-precondition'),
  );

  assert.equal(db.document('organizationAssignments/member-primary').status, 'ACTIVE');
  assert.equal(db.document('agents/agent-1').primaryOrganizationUnitId, 'bureau-helpdesk');
  assert.equal(db.pathsMatching(/^organizationAuditEvents\//).length, 0);
});

test('rejects corrupt assignment pointers, future placements, and backdated transfers without partial writes', async () => {
  const corruptDb = fakeDatabase({
    ...organizationSeed(),
    ...secondServiceSeed(),
    'agents/agent-1': {
      ...placedAgent('agent-1'),
      primaryAssignmentId: 'assignment-agent-2',
    },
    'organizationAssignments/assignment-agent-2': assignmentDocument({
      agentId: 'agent-2',
      unitId: 'bureau-helpdesk',
    }),
  });
  await assert.rejects(
    () => execute(corruptDb, ORGANIZATION_COMMANDS.transferAgentOrganization, {
      organizationId: 'org-arptc',
      organizationUnitId: 'service-security',
      agentId: 'agent-1',
      startsAt: '2026-08-11T08:00:00.000Z',
      reason: 'Must not end another agent assignment',
    }, 'corrupt-transfer'),
    hasCode('failed-precondition'),
  );
  assert.equal(
    corruptDb.document('organizationAssignments/assignment-agent-2').status,
    'ACTIVE',
  );

  const futureDb = fakeDatabase({
    ...organizationSeed(),
    'agents/unplaced': agentProfile(),
  });
  await assert.rejects(
    () => execute(futureDb, ORGANIZATION_COMMANDS.assignAgentOrganization, {
      organizationId: 'org-arptc',
      organizationUnitId: 'bureau-helpdesk',
      agentId: 'unplaced',
      startsAt: '2026-08-12T08:00:00.000Z',
      reason: 'Future assignment',
    }, 'future-assignment'),
    hasCode('invalid-argument'),
  );
  assert.equal(futureDb.pathsMatching(/^organizationAssignments\//).length, 0);

  const backdatedDb = fakeDatabase({
    ...organizationSeed(),
    ...secondServiceSeed(),
    'agents/agent-1': {
      ...placedAgent('agent-1'),
      primaryAssignmentId: 'current-assignment',
    },
    'organizationAssignments/current-assignment': {
      ...assignmentDocument({
        agentId: 'agent-1',
        unitId: 'bureau-helpdesk',
      }),
      startsAt: new Date('2026-08-10T00:00:00.000Z'),
    },
  });
  await assert.rejects(
    () => execute(backdatedDb, ORGANIZATION_COMMANDS.transferAgentOrganization, {
      organizationId: 'org-arptc',
      organizationUnitId: 'service-security',
      agentId: 'agent-1',
      startsAt: '2026-08-09T00:00:00.000Z',
      reason: 'Backdated transfer',
    }, 'backdated-transfer'),
    hasCode('failed-precondition'),
  );
  assert.equal(
    backdatedDb.document('organizationAssignments/current-assignment').status,
    'ACTIVE',
  );
});

test('permanent and acting leadership coexist in separate slots, reject duplicate slots, and end independently', async () => {
  const db = fakeDatabase({
    ...organizationSeed(),
    'agents/permanent-head': placedAgent('permanent-head'),
    'agents/acting-head': placedAgent('acting-head'),
    'agents/other-head': placedAgent('other-head'),
  });
  const permanent = await execute(db, ORGANIZATION_COMMANDS.setOrganizationUnitHead, {
    organizationId: 'org-arptc',
    organizationUnitId: 'service-operations',
    agentId: 'permanent-head',
    startsAt: '2026-08-01T00:00:00.000Z',
    reason: 'Permanent appointment',
  }, 'set-permanent-head');
  const acting = await execute(db, ORGANIZATION_COMMANDS.setOrganizationUnitHead, {
    organizationId: 'org-arptc',
    organizationUnitId: 'service-operations',
    agentId: 'acting-head',
    isActing: true,
    startsAt: '2026-08-10T00:00:00.000Z',
    endsAt: '2026-09-10T00:00:00.000Z',
    reason: 'Temporary replacement',
  }, 'set-acting-head');

  const unit = db.document('organizationUnits/service-operations');
  assert.equal(unit.headAssignmentId, permanent.assignmentId);
  assert.equal(unit.actingHeadAssignmentId, acting.assignmentId);
  assert.equal(
    db.document(`organizationAssignments/${permanent.assignmentId}`).isActing,
    false,
  );
  assert.equal(
    db.document(`organizationAssignments/${acting.assignmentId}`).isActing,
    true,
  );

  await assert.rejects(
    () => execute(db, ORGANIZATION_COMMANDS.setOrganizationUnitHead, {
      organizationId: 'org-arptc',
      organizationUnitId: 'service-operations',
      agentId: 'other-head',
      reason: 'Duplicate permanent appointment',
    }, 'duplicate-permanent-head'),
    hasCode('failed-precondition'),
  );
  await assert.rejects(
    () => execute(db, ORGANIZATION_COMMANDS.setOrganizationUnitHead, {
      organizationId: 'org-arptc',
      organizationUnitId: 'service-operations',
      agentId: 'other-head',
      isActing: true,
      startsAt: '2026-08-10T00:00:00.000Z',
      endsAt: '2026-09-10T00:00:00.000Z',
      reason: 'Duplicate acting appointment',
    }, 'duplicate-acting-head'),
    hasCode('failed-precondition'),
  );

  await execute(db, ORGANIZATION_COMMANDS.endOrganizationUnitHead, {
    organizationId: 'org-arptc',
    assignmentId: acting.assignmentId,
    reason: 'Acting period ended',
  }, 'end-acting-head');
  assert.equal(
    db.document('organizationUnits/service-operations').headAssignmentId,
    permanent.assignmentId,
  );
  assert.equal(
    db.document('organizationUnits/service-operations').actingHeadAssignmentId,
    null,
  );
  assert.equal(
    db.document(`organizationAssignments/${acting.assignmentId}`).status,
    'ENDED',
  );

  await execute(db, ORGANIZATION_COMMANDS.endOrganizationUnitHead, {
    organizationId: 'org-arptc',
    assignmentId: permanent.assignmentId,
    reason: 'Permanent mandate ended',
  }, 'end-permanent-head');
  assert.equal(
    db.document('organizationUnits/service-operations').headAssignmentId,
    null,
  );
});

test('archival rejects active child, assignment, and organization dependencies without partial writes', async () => {
  const activeAssignment = assignmentDocument({
    agentId: 'agent-1',
    unitId: 'bureau-helpdesk',
    unitType: 'BUREAU',
    unitName: 'Help Desk',
    pathUnitIds: ['department-it', 'service-operations', 'bureau-helpdesk'],
  });
  const db = fakeDatabase({
    ...organizationSeed(),
    'organizationAssignments/assignment-active': activeAssignment,
  });

  await assert.rejects(
    () => execute(db, ORGANIZATION_COMMANDS.archiveOrganizationUnit, {
      organizationId: 'org-arptc',
      organizationUnitId: 'department-it',
      reason: 'Department retired',
    }, 'archive-parent-with-child'),
    hasCode('failed-precondition'),
  );
  await assert.rejects(
    () => execute(db, ORGANIZATION_COMMANDS.archiveOrganizationUnit, {
      organizationId: 'org-arptc',
      organizationUnitId: 'bureau-helpdesk',
      reason: 'Bureau retired',
    }, 'archive-unit-with-assignment'),
    hasCode('failed-precondition'),
  );
  await assert.rejects(
    () => execute(db, ORGANIZATION_COMMANDS.archiveOrganization, {
      organizationId: 'org-arptc',
      reason: 'Organization retired',
    }, 'archive-org-with-dependencies'),
    hasCode('failed-precondition'),
  );

  assert.equal(db.document('organizations/org-arptc').status, 'ACTIVE');
  assert.equal(db.document('organizationUnits/department-it').status, 'ACTIVE');
  assert.equal(db.document('organizationUnits/bureau-helpdesk').status, 'ACTIVE');
  assert.equal(db.pathsMatching(/^organizationCommandReceipts\//).length, 0);
  assert.equal(db.pathsMatching(/^organizationAuditEvents\//).length, 0);
});

test('organization archival rejects a drifted active agent even without an assignment', async () => {
  const db = fakeDatabase({
    'organizations/org-arptc': organizationSeed()['organizations/org-arptc'],
    'organizationDirectory/org-arptc':
      organizationSeed()['organizationDirectory/org-arptc'],
    'agents/unplaced-active-agent': {
      ...agentProfile(),
      organizationId: 'org-arptc',
    },
  });
  await assert.rejects(
    () => execute(db, ORGANIZATION_COMMANDS.archiveOrganization, {
      organizationId: 'org-arptc',
      reason: 'Must not archive around an active agent',
    }, 'archive-with-unplaced-agent'),
    hasCode('failed-precondition'),
  );
  assert.equal(db.document('organizations/org-arptc').status, 'ACTIVE');
});

test('deactivation ends all active memberships and leadership, clears head projections, and disables directory and authorization access', async () => {
  const db = fakeDatabase({
    ...organizationSeed(),
    'organizationUnits/service-operations': {
      ...organizationSeed()['organizationUnits/service-operations'],
      headUserId: 'agent-1',
      headAssignmentId: 'head-permanent',
      actingHeadUserId: 'agent-1',
      actingHeadAssignmentId: 'head-acting',
      actingHeadEndsAt: new Date('2026-09-01T00:00:00.000Z'),
    },
    'agents/agent-1': {
      ...placedAgent('agent-1'),
      primaryAssignmentId: 'member-primary',
    },
    'agentDirectory/agent-1': { isActive: true, organizationId: 'org-arptc' },
    'agentAuthorizationIndex/agent-1': {
      isActive: true,
      organizationId: 'org-arptc',
    },
    'organizationAssignments/member-primary': assignmentDocument({
      agentId: 'agent-1',
      unitId: 'bureau-helpdesk',
      unitType: 'BUREAU',
      unitName: 'Help Desk',
      pathUnitIds: ['department-it', 'service-operations', 'bureau-helpdesk'],
    }),
    'organizationAssignments/head-permanent': assignmentDocument({
      agentId: 'agent-1',
      unitId: 'service-operations',
      assignmentType: 'HEAD',
      isPrimary: false,
      isActing: false,
      unitName: 'IT Operations',
      pathUnitIds: ['department-it', 'service-operations'],
    }),
    'organizationAssignments/head-acting': assignmentDocument({
      agentId: 'agent-1',
      unitId: 'service-operations',
      assignmentType: 'HEAD',
      isPrimary: false,
      isActing: true,
      unitName: 'IT Operations',
      pathUnitIds: ['department-it', 'service-operations'],
    }),
  });
  const effectiveAt = '2026-08-11T08:00:00.000Z';
  const result = await execute(db, ORGANIZATION_COMMANDS.deactivateAgentAccount, {
    organizationId: 'org-arptc',
    agentId: 'agent-1',
    effectiveAt,
    reason: 'End of employment',
  }, 'deactivate-agent');

  assert.equal(result.endedAssignmentCount, 3);
  for (const id of ['member-primary', 'head-permanent', 'head-acting']) {
    const assignment = db.document(`organizationAssignments/${id}`);
    assert.equal(assignment.status, 'ENDED');
    assert.deepEqual(assignment.endsAt, new Date(effectiveAt));
    assert.equal(assignment.endedBy, actor.uid);
  }
  const agent = db.document('agents/agent-1');
  assert.equal(agent.isActive, false);
  assert.equal(agent.primaryAssignmentId, '');
  assert.equal(db.document('agentDirectory/agent-1').isActive, false);
  assert.equal(db.document('agentAuthorizationIndex/agent-1').isActive, false);
  const unit = db.document('organizationUnits/service-operations');
  assert.equal(unit.headAssignmentId, null);
  assert.equal(unit.actingHeadAssignmentId, null);
  assert.equal(eventTypes(db).at(-1), 'AGENT_DEACTIVATED');

  const replayWithNewCommand = await execute(
    db,
    ORGANIZATION_COMMANDS.deactivateAgentAccount,
    {
      organizationId: 'org-arptc',
      agentId: 'agent-1',
      effectiveAt,
      reason: 'Retry after deactivation',
    },
    'deactivate-agent-new-command',
  );
  assert.equal(replayWithNewCommand.alreadyInactive, true);
  assert.equal(eventTypes(db).at(-1), 'AGENT_DEACTIVATION_REPLAYED');
});

test('command receipts make exact retries replay-safe without duplicate domain or audit writes', async () => {
  const db = fakeDatabase();
  const payload = {
    code: 'ARPTC',
    name: 'ARPTC',
    description: 'National regulator',
  };
  const first = await execute(
    db,
    ORGANIZATION_COMMANDS.createOrganization,
    payload,
    'idempotent-create-org',
  );
  const second = await execute(
    db,
    ORGANIZATION_COMMANDS.createOrganization,
    payload,
    'idempotent-create-org',
  );

  assert.equal(first.replayed, false);
  assert.equal(second.replayed, true);
  assert.equal(second.organizationId, first.organizationId);
  assert.equal(db.pathsMatching(/^organizations\//).length, 1);
  assert.equal(db.pathsMatching(/^organizationAuditEvents\//).length, 1);
  assert.equal(db.pathsMatching(/^organizationCommandReceipts\//).length, 1);
  assert.deepEqual(
    db.document('organizationCommandReceipts/idempotent-create-org').result,
    { organizationId: first.organizationId },
  );
});

test('architecture audit is bounded and reports duplicate assignments, invalid paths, missing projections, and stale agent projections without writing', async () => {
  const db = fakeDatabase({
    ...organizationSeed(),
    'organizationUnits/service-invalid': {
      organizationId: 'org-arptc',
      type: 'SERVICE',
      status: 'ACTIVE',
      pathUnitIds: ['department-missing', 'service-invalid'],
    },
    'organizationAssignments/primary-1': assignmentDocument({
      agentId: 'agent-1',
      unitId: 'bureau-helpdesk',
    }),
    'organizationAssignments/primary-2': assignmentDocument({
      agentId: 'agent-1',
      unitId: 'bureau-helpdesk',
    }),
    'organizationAssignments/head-1': assignmentDocument({
      agentId: 'head-1',
      unitId: 'service-operations',
      assignmentType: 'HEAD',
      isPrimary: false,
    }),
    'organizationAssignments/head-2': assignmentDocument({
      agentId: 'head-2',
      unitId: 'service-operations',
      assignmentType: 'HEAD',
      isPrimary: false,
    }),
    'agents/agent-1': {
      ...placedAgent('agent-1'),
      primaryAssignmentId: 'stale-assignment',
    },
    'agents/agent-without-assignment': {
      ...agentProfile(),
      organizationId: 'org-arptc',
    },
    'agentDirectory/agent-1': { organizationId: 'org-arptc' },
  });
  const pathsBefore = db.allPaths();

  const result = await auditOrganizationArchitecture({
    db,
    payload: { organizationId: 'org-arptc', limit: 20 },
  });

  assert.equal(result.dryRun, true);
  assert.equal(result.truncated, false);
  assert.deepEqual(result.scanned, {
    units: 4,
    assignments: 4,
    agents: 2,
    directory: 1,
    authorization: 0,
    organizationDirectory: 1,
  });
  assert.ok(result.issues.some((issue) =>
    issue.type === 'DUPLICATE_PRIMARY_ASSIGNMENT' && issue.key === 'agent-1'));
  assert.ok(result.issues.some((issue) =>
    issue.type === 'DUPLICATE_PERMANENT_HEAD' &&
    issue.key === 'service-operations'));
  assert.ok(result.issues.some((issue) =>
    issue.type === 'INVALID_UNIT_PATH' && issue.unitId === 'service-invalid'));
  assert.ok(result.issues.some((issue) =>
    issue.type === 'STALE_AGENT_PROJECTION' && issue.agentId === 'agent-1'));
  assert.ok(result.issues.some((issue) =>
    issue.type === 'MISSING_PRIMARY_ASSIGNMENT' &&
    issue.agentId === 'agent-without-assignment'));
  assert.ok(result.issues.some((issue) =>
    issue.type === 'MISSING_DIRECTORY_PROJECTION' &&
    issue.agentId === 'agent-without-assignment'));
  assert.equal(
    result.issues.filter((issue) =>
      issue.type === 'MISSING_AUTHORIZATION_PROJECTION').length,
    2,
  );
  assert.equal(result.issueCount, result.issues.length);
  assert.deepEqual(db.allPaths(), pathsBefore);

  await assert.rejects(
    () => auditOrganizationArchitecture({
      db,
      payload: { organizationId: 'org-arptc', limit: 101 },
    }),
    hasCode('invalid-argument'),
  );
});

test('architecture repair rebuilds projections only from one valid primary assignment', async () => {
  const db = fakeDatabase({
    ...organizationSeed(),
    'organizationAssignments/primary-1': assignmentDocument({
      agentId: 'agent-1',
      unitId: 'bureau-helpdesk',
    }),
    'agents/agent-1': {
      ...placedAgent('agent-1'),
      primaryAssignmentId: 'stale-assignment',
      organizationPathNames: ['Stale path'],
    },
    'agents/unplaced-agent': {
      ...agentProfile({ email: 'unplaced@arptc.cd' }),
      organizationId: 'org-arptc',
    },
  });

  const result = await execute(
    db,
    ORGANIZATION_COMMANDS.auditOrganizationArchitecture,
    {
      organizationId: 'org-arptc',
      limit: 20,
      repair: true,
      reason: 'Rebuild trusted projections after hierarchy cutover',
    },
    'repair-architecture',
  );

  assert.equal(result.dryRun, false);
  assert.equal(result.repairedCount, 1);
  assert.deepEqual(result.repairedAgentIds, ['agent-1']);
  assert.deepEqual(result.skippedAgentIds, ['unplaced-agent']);
  assert.equal(db.document('agents/agent-1').primaryAssignmentId, 'primary-1');
  assert.equal(
    db.document('agents/agent-1').primaryOrganizationUnitId,
    'bureau-helpdesk',
  );
  assert.equal(db.document('agentDirectory/agent-1').displayName, 'Aline Mbuyi Kanku');
  assert.equal(db.document('agentAuthorizationIndex/agent-1').schemaVersion, 2);
  assert.equal(db.document('agentDirectory/unplaced-agent'), undefined);
  assert.ok(result.issues.some((issue) =>
    issue.type === 'MISSING_PRIMARY_ASSIGNMENT' &&
    issue.agentId === 'unplaced-agent'));
  assert.equal(
    eventTypes(db).at(-1),
    'ORGANIZATION_ARCHITECTURE_PROJECTIONS_REPAIRED',
  );
});

test('architecture audit follows stable pages beyond 100 records and repairs the safe organization directory projection', async () => {
  const manyUnits = Object.fromEntries(
    Array.from({ length: 125 }, (_, index) => {
      const id = `department-${String(index).padStart(3, '0')}`;
      return [`organizationUnits/${id}`, unitDocument({
        id,
        type: 'DEPARTMENT',
        code: `D-${index}`,
        name: `Department ${index}`,
        pathUnitIds: [id],
        pathNames: [`Department ${index}`],
      })];
    }),
  );
  const db = fakeDatabase({
    ...organizationSeed(),
    ...manyUnits,
  });
  const paged = await auditOrganizationArchitecture({
    db,
    payload: { organizationId: 'org-arptc', limit: 20 },
  });
  assert.equal(paged.scanned.units, 128);
  assert.equal(paged.truncated, false);

  const directoryDb = fakeDatabase({
    ...organizationSeed(),
    'organizationDirectory/org-arptc': {
      name: 'Stale organization name',
      nameLower: 'stale organization name',
      status: 'INACTIVE',
    },
  });
  const before = await auditOrganizationArchitecture({
    db: directoryDb,
    payload: { organizationId: 'org-arptc', limit: 20 },
  });
  assert.ok(before.issues.some((issue) =>
    issue.type === 'ORGANIZATION_DIRECTORY_PROJECTION_DRIFT'));
  const after = await execute(
    directoryDb,
    ORGANIZATION_COMMANDS.auditOrganizationArchitecture,
    {
      organizationId: 'org-arptc',
      limit: 20,
      repair: true,
      reason: 'Repair safe directory projection',
    },
    'repair-organization-directory',
  );
  assert.equal(
    directoryDb.document('organizationDirectory/org-arptc').name,
    'ARPTC',
  );
  assert.ok(!after.issues.some((issue) =>
    issue.type === 'ORGANIZATION_DIRECTORY_PROJECTION_DRIFT'));
});

test('architecture repair receipt replay and collision checks run before projection writes', async () => {
  const payload = {
    organizationId: 'org-arptc',
    limit: 20,
    repair: true,
    reason: 'Repair safe directory projection',
    commandId: 'repair-before-writes',
  };
  const completedDb = fakeDatabase({
    ...organizationSeed(),
    'organizationDirectory/org-arptc': {
      name: 'Stale organization name',
      nameLower: 'stale organization name',
      status: 'INACTIVE',
    },
  });
  const completed = await executeOrganizationCommand({
    db: completedDb,
    fieldValue,
    timestamp,
    command: ORGANIZATION_COMMANDS.auditOrganizationArchitecture,
    payload,
    actor,
  });
  const receipt = completedDb.document(
    'organizationCommandReceipts/repair-before-writes',
  );

  const replayDb = fakeDatabase({
    ...organizationSeed(),
    'organizationDirectory/org-arptc': {
      name: 'Drift introduced after completion',
      nameLower: 'drift introduced after completion',
      status: 'INACTIVE',
    },
    'organizationCommandReceipts/repair-before-writes': receipt,
  });
  const replay = await executeOrganizationCommand({
    db: replayDb,
    fieldValue,
    timestamp,
    command: ORGANIZATION_COMMANDS.auditOrganizationArchitecture,
    payload,
    actor,
  });
  assert.equal(completed.replayed, false);
  assert.equal(replay.replayed, true);
  assert.equal(
    replayDb.document('organizationDirectory/org-arptc').name,
    'Drift introduced after completion',
  );
  assert.equal(replayDb.pathsMatching(/^organizationAuditEvents\//).length, 0);

  await assert.rejects(
    () => executeOrganizationCommand({
      db: replayDb,
      fieldValue,
      timestamp,
      command: ORGANIZATION_COMMANDS.auditOrganizationArchitecture,
      payload: { ...payload, reason: 'Different command payload' },
      actor,
    }),
    hasCode('failed-precondition'),
  );
  assert.equal(
    replayDb.document('organizationDirectory/org-arptc').name,
    'Drift introduced after completion',
  );
});

test('command receipts reject reuse by another actor, command, or payload', async () => {
  const db = fakeDatabase();
  const payload = {
    commandId: 'shared-command-id',
    code: 'ARPTC',
    name: 'ARPTC',
  };
  const created = await executeOrganizationCommand({
    db,
    fieldValue,
    timestamp,
    command: ORGANIZATION_COMMANDS.createOrganization,
    payload,
    actor,
  });

  for (const attempted of [
    { command: ORGANIZATION_COMMANDS.createOrganization, payload, actor: { uid: 'manager-2' } },
    {
      command: ORGANIZATION_COMMANDS.archiveOrganization,
      payload: {
        commandId: payload.commandId,
        organizationId: created.organizationId,
        reason: 'Conflicting command reuse',
      },
      actor,
    },
    {
      command: ORGANIZATION_COMMANDS.createOrganization,
      payload: { ...payload, name: 'Different organization' },
      actor,
    },
  ]) {
    await assert.rejects(
      () => executeOrganizationCommand({
        db,
        fieldValue,
        timestamp,
        ...attempted,
      }),
      hasCode('failed-precondition'),
    );
  }
});

test('deactivation safely processes exactly 100 active assignments', async () => {
  const seed = {
    ...organizationSeed(),
    'agents/agent-1': {
      ...placedAgent('agent-1'),
      primaryAssignmentId: 'assignment-0',
    },
    'agentDirectory/agent-1': { isActive: true },
    'agentAuthorizationIndex/agent-1': { isActive: true },
  };
  for (let index = 0; index < 100; index += 1) {
    seed[`organizationAssignments/assignment-${index}`] = assignmentDocument({
      agentId: 'agent-1',
      unitId: 'bureau-helpdesk',
    });
  }
  const db = fakeDatabase(seed);

  const result = await execute(db, ORGANIZATION_COMMANDS.deactivateAgentAccount, {
    organizationId: 'org-arptc',
    agentId: 'agent-1',
    reason: 'End of service',
  }, 'deactivate-100');

  assert.equal(result.endedAssignmentCount, 100);
  assert.equal(db.document('organizationAssignments/assignment-99').status, 'ENDED');
});

test('ending stale leadership cannot clear a newer unit projection', async () => {
  const db = fakeDatabase({
    ...organizationSeed(),
    'organizationUnits/service-operations': {
      ...organizationSeed()['organizationUnits/service-operations'],
      headUserId: 'new-head',
      headAssignmentId: 'new-head-assignment',
    },
    'organizationAssignments/stale-head-assignment': assignmentDocument({
      agentId: 'old-head',
      unitId: 'service-operations',
      assignmentType: 'HEAD',
      isPrimary: false,
      unitType: 'SERVICE',
      unitName: 'IT Operations',
      pathUnitIds: ['department-it', 'service-operations'],
    }),
  });

  await assert.rejects(
    () => execute(db, ORGANIZATION_COMMANDS.endOrganizationUnitHead, {
      organizationId: 'org-arptc',
      assignmentId: 'stale-head-assignment',
      reason: 'Stale command',
    }, 'end-stale-head'),
    hasCode('failed-precondition'),
  );
  assert.equal(
    db.document('organizationUnits/service-operations').headAssignmentId,
    'new-head-assignment',
  );
  assert.equal(
    db.document('organizationAssignments/stale-head-assignment').status,
    'ACTIVE',
  );
});

test('acting leadership must end strictly after it starts', async () => {
  const db = fakeDatabase({
    ...organizationSeed(),
    'agents/acting-head': placedAgent('acting-head'),
  });

  for (const endsAt of [
    '2026-08-10T00:00:00.000Z',
    '2026-08-09T23:59:59.000Z',
  ]) {
    await assert.rejects(
      () => execute(db, ORGANIZATION_COMMANDS.setOrganizationUnitHead, {
        organizationId: 'org-arptc',
        organizationUnitId: 'service-operations',
        agentId: 'acting-head',
        isActing: true,
        startsAt: '2026-08-10T00:00:00.000Z',
        endsAt,
        reason: 'Invalid acting period',
      }, `invalid-acting-${endsAt}`),
      hasCode('invalid-argument'),
    );
  }
});

function execute(db, command, payload, commandId) {
  return executeOrganizationCommand({
    db,
    fieldValue,
    timestamp,
    command,
    payload: { ...payload, commandId },
    actor,
  });
}

function hasCode(code) {
  return (error) => error && error.code === code;
}

function eventTypes(db) {
  return db.documentsMatching(/^organizationAuditEvents\//)
    .map((event) => event.eventType);
}

function agentProfile(overrides = {}) {
  return {
    firstName: 'Aline',
    name: 'Mbuyi',
    postName: 'Kanku',
    sex: 'female',
    email: 'aline.mbuyi@arptc.cd',
    jobTitle: 'Support analyst',
    isActive: true,
    modulePermissions: { ticketing: 'MANAGER' },
    ...overrides,
  };
}

function placedAgent(id) {
  return {
    ...agentProfile({ email: `${id}@arptc.cd` }),
    organizationSchemaVersion: 2,
    organizationId: 'org-arptc',
    organizationName: 'ARPTC',
    primaryOrganizationUnitId: 'bureau-helpdesk',
    primaryOrganizationUnitName: 'Help Desk',
    primaryOrganizationUnitType: 'BUREAU',
    organizationAncestorUnitIds: ['department-it', 'service-operations'],
    organizationPathUnitIds: [
      'department-it',
      'service-operations',
      'bureau-helpdesk',
    ],
    organizationPathNames: [
      'Information Technology',
      'IT Operations',
      'Help Desk',
    ],
    scopeKeys: [
      'org:org-arptc',
      'unit:department-it',
      'unit:service-operations',
      'unit:bureau-helpdesk',
    ],
    departmentId: 'department-it',
    department: 'Information Technology',
    serviceId: 'service-operations',
    service: 'IT Operations',
    bureauId: 'bureau-helpdesk',
    bureau: 'Help Desk',
  };
}

function organizationSeed() {
  return {
    'organizations/org-arptc': {
      code: 'ARPTC',
      name: 'ARPTC',
      nameLower: 'arptc',
      description: 'National regulator',
      status: 'ACTIVE',
      schemaVersion: 2,
    },
    'organizationDirectory/org-arptc': {
      name: 'ARPTC',
      nameLower: 'arptc',
      status: 'ACTIVE',
    },
    'organizationUnits/department-it': unitDocument({
      id: 'department-it',
      type: 'DEPARTMENT',
      code: 'D-IT',
      name: 'Information Technology',
      pathUnitIds: ['department-it'],
      pathNames: ['Information Technology'],
    }),
    'organizationUnits/service-operations': unitDocument({
      id: 'service-operations',
      type: 'SERVICE',
      code: 'S-OPS',
      name: 'IT Operations',
      parentUnitId: 'department-it',
      parentUnitType: 'DEPARTMENT',
      pathUnitIds: ['department-it', 'service-operations'],
      pathNames: ['Information Technology', 'IT Operations'],
    }),
    'organizationUnits/bureau-helpdesk': unitDocument({
      id: 'bureau-helpdesk',
      type: 'BUREAU',
      code: 'B-HD',
      name: 'Help Desk',
      parentUnitId: 'service-operations',
      parentUnitType: 'SERVICE',
      pathUnitIds: [
        'department-it',
        'service-operations',
        'bureau-helpdesk',
      ],
      pathNames: [
        'Information Technology',
        'IT Operations',
        'Help Desk',
      ],
    }),
  };
}

function secondServiceSeed() {
  return {
    'organizationUnits/service-security': unitDocument({
      id: 'service-security',
      type: 'SERVICE',
      code: 'S-SEC',
      name: 'Cybersecurity',
      parentUnitId: 'department-it',
      parentUnitType: 'DEPARTMENT',
      pathUnitIds: ['department-it', 'service-security'],
      pathNames: ['Information Technology', 'Cybersecurity'],
    }),
  };
}

function unitDocument({
  id,
  type,
  code,
  name,
  parentUnitId = null,
  parentUnitType = null,
  pathUnitIds,
  pathNames,
}) {
  return {
    organizationId: 'org-arptc',
    organizationName: 'ARPTC',
    type,
    code,
    name,
    nameLower: name.toLowerCase(),
    description: '',
    parentUnitId,
    parentUnitType,
    ancestorUnitIds: pathUnitIds.slice(0, -1),
    pathUnitIds,
    pathNames,
    depth: pathUnitIds.length - 1,
    scopeKeys: [
      'org:org-arptc',
      ...pathUnitIds.map((pathId) => `unit:${pathId}`),
    ],
    status: 'ACTIVE',
    headUserId: null,
    headAssignmentId: null,
    actingHeadUserId: null,
    actingHeadAssignmentId: null,
    actingHeadEndsAt: null,
    schemaVersion: 2,
    _idForTest: id,
  };
}

function assignmentDocument({
  agentId,
  unitId,
  assignmentType = 'MEMBER',
  isPrimary = true,
  isActing = false,
  unitType = 'BUREAU',
  unitName = 'Help Desk',
  pathUnitIds = ['department-it', 'service-operations', 'bureau-helpdesk'],
  pathNames = [
    'Information Technology',
    'IT Operations',
    'Help Desk',
  ].slice(0, pathUnitIds.length),
}) {
  return {
    organizationId: 'org-arptc',
    agentId,
    unitId,
    unitType,
    unitName,
    ancestorUnitIds: pathUnitIds.slice(0, -1),
    pathUnitIds,
    pathNames,
    scopeKeys: [
      'org:org-arptc',
      ...pathUnitIds.map((pathId) => `unit:${pathId}`),
    ],
    assignmentType,
    isPrimary,
    isActing,
    status: 'ACTIVE',
    startsAt: new Date('2026-08-01T00:00:00.000Z'),
    endsAt: null,
    reason: 'Test assignment',
  };
}

function fakeDatabase(seed = {}) {
  const documents = new Map(
    Object.entries(seed).map(([path, value]) => [path, clone(value)]),
  );
  let generatedId = 0;

  class Reference {
    constructor(path) {
      this.path = path;
      this.id = path.split('/').at(-1);
    }
    collection(name) {
      return new Collection(`${this.path}/${name}`);
    }
    async get() {
      return documentSnapshot(this);
    }
  }

  class Query {
    constructor(path, filters = [], maximum = null, cursor = null) {
      this.path = path;
      this.filters = filters;
      this.maximum = maximum;
      this.cursor = cursor;
    }
    where(field, operator, value) {
      return new Query(
        this.path,
        [...this.filters, { field, operator, value }],
        this.maximum,
        this.cursor,
      );
    }
    limit(value) {
      return new Query(this.path, this.filters, value, this.cursor);
    }
    orderBy() {
      return this;
    }
    startAfter(value) {
      return new Query(
        this.path,
        this.filters,
        this.maximum,
        typeof value === 'string' ? value : value && value.id,
      );
    }
    async get() {
      return querySnapshot(this);
    }
  }

  class Collection extends Query {
    constructor(path) {
      super(path);
    }
    doc(id) {
      const resolvedId = id || `generated-${++generatedId}`;
      return new Reference(`${this.path}/${resolvedId}`);
    }
  }

  function documentSnapshot(reference, source = documents) {
    const value = source.get(reference.path);
    return {
      id: reference.id,
      ref: reference,
      exists: value !== undefined,
      data: () => clone(value),
      get: (field) => value && clone(value[field]),
    };
  }

  function querySnapshot(query, source = documents) {
    const collectionDepth = query.path.split('/').length;
    const docs = [...source.entries()]
      .filter(([path]) => {
        const segments = path.split('/');
        return segments.length === collectionDepth + 1 &&
          segments.slice(0, collectionDepth).join('/') === query.path;
      })
      .filter(([, value]) => query.filters.every((filter) => {
        const actual = value && value[filter.field];
        if (filter.operator === '==') return actual === filter.value;
        if (filter.operator === 'array-contains') {
          return Array.isArray(actual) && actual.includes(filter.value);
        }
        throw new Error(`Unsupported fake query operator: ${filter.operator}`);
      }))
      .sort(([left], [right]) => left.localeCompare(right))
      .filter(([path]) => !query.cursor || path.split('/').at(-1) > query.cursor)
      .slice(0, query.maximum === null ? undefined : query.maximum)
      .map(([path]) => documentSnapshot(new Reference(path), source));
    return {
      docs,
      size: docs.length,
      empty: docs.length === 0,
    };
  }

  return {
    collection(name) {
      return new Collection(name);
    },
    document(path) {
      return clone(documents.get(path));
    },
    allPaths() {
      return [...documents.keys()].sort();
    },
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
      let hasWrites = false;
      const queueWrite = (write) => {
        hasWrites = true;
        writes.push(write);
      };
      const transaction = {
        get: async (target) => {
          if (hasWrites) {
            throw new Error(
              'Firestore transactions require all reads to be executed before all writes',
            );
          }
          return target instanceof Query
            ? querySnapshot(target)
            : documentSnapshot(target);
        },
        create: (reference, value) => queueWrite({
          kind: 'create',
          reference,
          value,
        }),
        set: (reference, value, options) => queueWrite({
          kind: 'set',
          reference,
          value,
          options,
        }),
        update: (reference, value) => queueWrite({
          kind: 'update',
          reference,
          value,
        }),
        delete: (reference) => queueWrite({ kind: 'delete', reference }),
      };
      const result = await callback(transaction);
      const next = new Map(
        [...documents.entries()].map(([path, value]) => [path, clone(value)]),
      );
      for (const write of writes) {
        const path = write.reference.path;
        if (write.kind === 'create') {
          if (next.has(path)) throw new Error(`Document already exists: ${path}`);
          next.set(path, clone(write.value));
        } else if (write.kind === 'update') {
          if (!next.has(path)) throw new Error(`Document does not exist: ${path}`);
          next.set(path, { ...next.get(path), ...clone(write.value) });
        } else if (write.kind === 'set') {
          next.set(path, write.options && write.options.merge
            ? { ...(next.get(path) || {}), ...clone(write.value) }
            : clone(write.value));
        } else if (write.kind === 'delete') {
          next.delete(path);
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
