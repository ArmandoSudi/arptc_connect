const assert = require('node:assert/strict');
const test = require('node:test');

const {
  COMMAND_ALLOWED_ROLES,
  ITSM_COMMANDS,
  validateCommandEnvelope,
} = require('../src/itsm_command_validation');
const {
  ITSM_ROLES,
  ItsmCommandError,
} = require('../src/itsm_permissions');

test('validates and freezes a workflow transition command', () => {
  const command = validateCommandEnvelope(
    {
      command: ITSM_COMMANDS.transitionWorkItem,
      idempotencyKey: 'command-1234',
      entityType: 'incident_ticket',
      entityId: 'INC-1',
      payload: {
        transitionId: 'incident.assign',
        toState: 'assigned',
        expectedRevision: 2,
        reason: 'Assigned by service desk.',
      },
    },
    ITSM_COMMANDS.transitionWorkItem,
  );

  assert.equal(command.entityType, 'incident');
  assert.equal(command.payload.expectedRevision, 2);
  assert.equal(Object.isFrozen(command), true);
  assert.equal(Object.isFrozen(command.payload), true);
});

test('denies unknown commands and endpoint command mismatches', () => {
  assertInvalid(() =>
    validateCommandEnvelope({
      command: 'workflow.delete_everything',
      idempotencyKey: 'command-1234',
      entityType: 'incident',
      entityId: 'INC-1',
      payload: {},
    }),
  );

  assertInvalid(() =>
    validateCommandEnvelope(
      {
        command: ITSM_COMMANDS.indexAuditEvent,
        idempotencyKey: 'command-1234',
        entityType: 'incident',
        entityId: 'INC-1',
        payload: {
          auditEventId: 'audit-1',
        },
      },
      ITSM_COMMANDS.transitionWorkItem,
    ),
  );
});

test('audit indexing accepts only an authoritative audit event ID', () => {
  const command = validateCommandEnvelope({
    command: ITSM_COMMANDS.indexAuditEvent,
    idempotencyKey: 'audit-event-1234',
    entityType: 'service_request',
    entityId: 'REQ-1',
    payload: { auditEventId: 'audit-1' },
  });
  assert.equal(command.payload.auditEventId, 'audit-1');

  assertInvalid(() =>
    validateCommandEnvelope({
      command: ITSM_COMMANDS.indexAuditEvent,
      idempotencyKey: 'audit-event-1234',
      entityType: 'service_request',
      entityId: 'REQ-1',
      payload: {
        auditEventId: 'audit-1',
        actorUid: 'forged-user',
      },
    }),
  );
});

test('approval rejection requires a reason', () => {
  assertInvalid(() =>
    validateCommandEnvelope({
      command: ITSM_COMMANDS.decideApproval,
      idempotencyKey: 'approval-1234',
      entityType: 'change_request',
      entityId: 'CHG-1',
      payload: {
        approvalId: 'approval-1',
        decision: 'rejected',
        comment: '',
      },
    }),
  );
});

test('notification validation fixes module role targeting to ticketing MANAGER', () => {
  const command = validateCommandEnvelope({
    command: ITSM_COMMANDS.createNotificationEvent,
    idempotencyKey: 'notification-1234',
    entityType: 'incident',
    entityId: 'INC-1',
    payload: {
      eventType: 'incident.created',
      title: 'New incident',
      body: 'An incident needs triage.',
      route: '/services/itsm/support/incidents/INC-1',
      target: {
        type: 'MODULE_ROLE',
        moduleKey: 'support',
        roles: ['manager'],
      },
    },
  });

  assert.deepEqual(command.payload.target, {
    type: 'MODULE_ROLE',
    moduleKey: 'ticketing',
    roles: ['MANAGER'],
  });
});

test('allows ADMIN only through the self-service transition boundary', () => {
  assert.equal(
    COMMAND_ALLOWED_ROLES[ITSM_COMMANDS.transitionWorkItem].includes(
      ITSM_ROLES.admin,
    ),
    true,
  );
  for (const command of [
    ITSM_COMMANDS.decideApproval,
    ITSM_COMMANDS.indexAuditEvent,
    ITSM_COMMANDS.maintainWorkItemIndex,
    ITSM_COMMANDS.processSla,
    ITSM_COMMANDS.createNotificationEvent,
  ]) {
    assert.equal(COMMAND_ALLOWED_ROLES[command].includes(ITSM_ROLES.admin), false);
  }
});

test('notification validation rejects global and unknown events', () => {
  for (const payload of [
    {
      eventType: 'incident.created',
      title: 'Global',
      body: 'Not permitted',
      target: { type: 'ALL' },
    },
    {
      eventType: 'custom.arbitrary_event',
      title: 'Unknown',
      body: 'Not permitted',
      target: {
        type: 'MODULE_ROLE',
        roles: ['MANAGER'],
      },
    },
  ]) {
    assertInvalid(() =>
      validateCommandEnvelope({
        command: ITSM_COMMANDS.createNotificationEvent,
        idempotencyKey: 'notification-denied-1234',
        entityType: 'incident',
        entityId: 'INC-1',
        payload,
      }),
    );
  }
});

function assertInvalid(callback) {
  assert.throws(
    callback,
    (error) =>
      error instanceof ItsmCommandError &&
      error.code === 'invalid-argument',
  );
}
