'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  CHANGES_COMMAND_ALLOWED_ROLES,
  ITSM_CHANGES_COMMANDS,
  validateChangesCommand,
} = require('../src/itsm_changes_validation');

test('self-service and operational commands expose the intended role boundaries', () => {
  for (const command of [
    ITSM_CHANGES_COMMANDS.initializeDraft,
    ITSM_CHANGES_COMMANDS.saveDraft,
    ITSM_CHANGES_COMMANDS.submit,
    ITSM_CHANGES_COMMANDS.cancel,
  ]) {
    assert.deepEqual(CHANGES_COMMAND_ALLOWED_ROLES[command], [
      'USER',
      'MANAGER',
      'ADMIN',
    ]);
  }
  for (const command of [
    ITSM_CHANGES_COMMANDS.assess,
    ITSM_CHANGES_COMMANDS.requestApproval,
    ITSM_CHANGES_COMMANDS.decideApproval,
    ITSM_CHANGES_COMMANDS.saveCabMeeting,
    ITSM_CHANGES_COMMANDS.schedule,
    ITSM_CHANGES_COMMANDS.startImplementation,
    ITSM_CHANGES_COMMANDS.recordImplementationResult,
    ITSM_CHANGES_COMMANDS.recordPostImplementationReview,
    ITSM_CHANGES_COMMANDS.close,
  ]) {
    assert.deepEqual(CHANGES_COMMAND_ALLOWED_ROLES[command], ['MANAGER']);
  }
});

test('draft validation accepts all change types and returns deeply frozen data', () => {
  for (const changeType of ['standard', 'normal', 'emergency']) {
    const command = validateChangesCommand({
      command: ITSM_CHANGES_COMMANDS.initializeDraft,
      idempotencyKey: `draft-${changeType}-1234`,
      payload: {
        workflowDefinitionId: 'change-workflow',
        changeType,
        title: 'Upgrade network core',
        description: 'Replace the edge firmware.',
        justification: 'Security support ends soon.',
      },
    });
    assert.equal(command.payload.changeType, changeType);
    assert.equal(Object.isFrozen(command), true);
    assert.equal(Object.isFrozen(command.payload), true);
  }
});

test('unknown actor, role, risk, status, and timestamp fields are rejected', () => {
  for (const forbidden of [
    ['actorUserId', 'spoofed'],
    ['actorRole', 'MANAGER'],
    ['risk', 'low'],
    ['status', 'approved'],
    ['createdAt', '2026-08-01T00:00:00.000Z'],
  ]) {
    assert.throws(
      () => validateChangesCommand({
        command: ITSM_CHANGES_COMMANDS.initializeDraft,
        idempotencyKey: `forbidden-${forbidden[0]}-1234`,
        payload: {
          workflowDefinitionId: 'change-workflow',
          changeType: 'normal',
          title: 'Change',
          description: 'Description',
          justification: 'Justification',
          [forbidden[0]]: forbidden[1],
        },
      }),
      (error) => error.code === 'invalid-argument' &&
        /unsupported fields/.test(error.message),
    );
  }
});

test('assessment requires plans, owner, service, and bounded values', () => {
  const command = validAssessment();
  assert.equal(command.payload.expectedDowntimeMinutes, 60);
  assert.deepEqual(command.payload.affectedServiceIds, ['email']);
  assert.equal(command.payload.impact, 'high');

  assert.throws(
    () => validAssessment({ affectedServiceIds: [] }),
    (error) => error.code === 'invalid-argument' && /at least one/.test(error.message),
  );
  assert.throws(
    () => validAssessment({ expectedDowntimeMinutes: 999999 }),
    (error) => error.code === 'invalid-argument',
  );
});

test('approval decisions require a supported decision and mandatory comment', () => {
  const approved = validateChangesCommand({
    command: ITSM_CHANGES_COMMANDS.decideApproval,
    idempotencyKey: 'approval-decision-1234',
    payload: {
      changeId: 'change-1',
      approvalId: 'approval-1',
      expectedRevision: 3,
      decision: 'approved',
      comment: 'Approved with monitoring.',
      conditions: ['Monitor the service for two hours.'],
    },
  });
  assert.equal(approved.payload.decision, 'approved');
  assert.throws(
    () => validateChangesCommand({
      command: ITSM_CHANGES_COMMANDS.decideApproval,
      idempotencyKey: 'approval-invalid-1234',
      payload: {
        changeId: 'change-1',
        approvalId: 'approval-1',
        expectedRevision: 3,
        decision: 'rubber_stamp',
        comment: 'No.',
      },
    }),
    (error) => error.code === 'invalid-argument',
  );
});

test('CAB and implementation windows are ordered and bounded', () => {
  const meeting = validateChangesCommand({
    command: ITSM_CHANGES_COMMANDS.saveCabMeeting,
    idempotencyKey: 'cab-meeting-1234',
    payload: {
      changeId: 'change-1',
      expectedRevision: 3,
      approvalGroupId: 'cab-network',
      title: 'Network CAB',
      agenda: 'Review network changes.',
      participantUserIds: ['manager-1'],
      scheduledStartAt: '2026-08-05T09:00:00.000Z',
      scheduledEndAt: '2026-08-05T10:00:00.000Z',
    },
  });
  assert.equal(meeting.payload.scheduledStartAt, '2026-08-05T09:00:00.000Z');

  assert.throws(
    () => validateChangesCommand({
      command: ITSM_CHANGES_COMMANDS.schedule,
      idempotencyKey: 'bad-window-1234',
      payload: {
        changeId: 'change-1',
        expectedRevision: 4,
        plannedStartAt: '2026-08-06T11:00:00.000Z',
        plannedEndAt: '2026-08-06T10:00:00.000Z',
        expectedDowntimeMinutes: 30,
      },
    }),
    (error) => error.code === 'invalid-argument' && /end must be after/.test(error.message),
  );
});

test('deduplicates bounded identifiers and rejects endpoint command confusion', () => {
  const assessment = validAssessment({
    affectedCiIds: ['ci-1', 'ci-1', 'ci-2'],
  });
  assert.deepEqual(assessment.payload.affectedCiIds, ['ci-1', 'ci-2']);
  assert.throws(
    () => validateChangesCommand({
      command: ITSM_CHANGES_COMMANDS.submit,
      idempotencyKey: 'wrong-endpoint-1234',
      payload: { changeId: 'change-1', expectedRevision: 0 },
    }, ITSM_CHANGES_COMMANDS.cancel),
    (error) => error.code === 'invalid-argument',
  );
});

function validAssessment(overrides = {}) {
  return validateChangesCommand({
    command: ITSM_CHANGES_COMMANDS.assess,
    idempotencyKey: `assessment-${Math.random().toString(16).slice(2)}-1234`,
    payload: {
      changeId: 'change-1',
      expectedRevision: 2,
      ownerUserId: 'manager-2',
      affectedServiceIds: ['email'],
      affectedCiIds: [],
      affectedAssetIds: [],
      relatedIncidentIds: [],
      relatedRequestIds: [],
      impact: 'high',
      urgency: 'medium',
      complexity: 'medium',
      expectedDowntimeMinutes: 60,
      implementationPlan: 'Deploy in two controlled waves.',
      testPlan: 'Run smoke and rollback tests.',
      communicationPlan: 'Notify affected departments.',
      rollbackPlan: 'Restore the previous release.',
      ...overrides,
    },
  });
}
