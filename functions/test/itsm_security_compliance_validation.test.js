'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  SECURITY_COMPLIANCE_ALLOWED_ROLES,
  SECURITY_COMPLIANCE_COMMANDS: C,
  validateSecurityComplianceCommand,
} = require('../src/itsm_security_compliance_validation');

function command(name, payload) {
  return validateSecurityComplianceCommand({
    command: name,
    idempotencyKey: `test-${name}-12345678`,
    payload,
  }, name);
}

test('all commands have an explicit role policy', () => {
  assert.deepEqual(
    Object.keys(SECURITY_COMPLIANCE_ALLOWED_ROLES).sort(),
    Object.values(C).sort(),
  );
  assert.deepEqual(SECURITY_COMPLIANCE_ALLOWED_ROLES[C.createFinding], ['MANAGER']);
  assert.deepEqual(
    SECURITY_COMPLIANCE_ALLOWED_ROLES[C.createException],
    ['USER', 'MANAGER', 'ADMIN'],
  );
  assert.equal(Object.isFrozen(SECURITY_COMPLIANCE_ALLOWED_ROLES), true);
});

test('finding creation normalizes and freezes strict payloads', () => {
  const value = command(C.createFinding, {
    title: ' Critical patch ',
    description: 'Patch missing.',
    source: 'scanner',
    severity: 'HIGH',
    risk: 'critical',
    affectedAssetIds: ['asset-1', 'asset-1'],
  });
  assert.equal(value.payload.title, 'Critical patch');
  assert.equal(value.payload.severity, 'high');
  assert.deepEqual(value.payload.affectedAssetIds, ['asset-1']);
  assert.equal(value.payload.confidentiality, 'restricted');
  assert.equal(Object.isFrozen(value.payload), true);
});

test('unknown and client-forged fields are rejected', () => {
  assert.throws(
    () => command(C.assignFinding, {
      findingId: 'f-1',
      expectedRevision: 0,
      ownerUserId: 'manager-1',
      actorRole: 'MANAGER',
    }),
    /unknown field actorRole/,
  );
  assert.throws(
    () => validateSecurityComplianceCommand({
      command: C.assignFinding,
      idempotencyKey: 'valid-key-1234',
      payload: {},
      uid: 'forged',
    }),
    /unknown field uid/,
  );
});

test('exception validation requires bounded dates and controls', () => {
  const value = command(C.createException, {
    title: 'Temporary legacy access',
    requirementOrControl: 'MFA-01',
    businessJustification: 'Migration window.',
    scope: 'Legacy gateway',
    riskDescription: 'Credential exposure.',
    compensatingControls: [{
      id: 'control-1',
      description: 'Daily access review',
      effective: true,
    }],
    requestedStartAt: '2026-08-01T00:00:00Z',
    requestedEndAt: '2026-08-10T00:00:00Z',
    reviewAt: '2026-08-05T00:00:00Z',
  });
  assert.equal(value.payload.compensatingControls[0].effective, true);
  assert(value.payload.requestedStartAt instanceof Date);
});

test('compliance checks reject duplicate controls and unknown results', () => {
  const base = {
    assetId: 'asset-1',
    assetTag: 'ARPTC-1',
    assetName: 'Laptop',
  };
  assert.throws(() => command(C.assessCompliance, {
    ...base,
    checks: [
      { control: 'patch_status', result: 'compliant' },
      { control: 'patch_status', result: 'unknown' },
    ],
  }), /duplicate patch_status/);
  assert.throws(() => command(C.assessCompliance, {
    ...base,
    checks: [{ control: 'patch_status', result: 'unsafe' }],
  }), /must be one of/);
});

test('access review decisions validate task inputs without accepting roles', () => {
  const value = command(C.decideReviewItem, {
    itemId: 'item-1',
    expectedRevision: 0,
    decision: 'modify',
    justification: 'Reduce privileged access.',
    assignedToUserId: 'manager-2',
    targetAccess: 'read-only',
    taskDueAt: '2026-08-04T00:00:00Z',
  });
  assert.equal(value.payload.decision, 'modify');
  assert.equal(Object.hasOwn(value.payload, 'actorRole'), false);
});

test('endpoint command mismatch and weak idempotency keys are rejected', () => {
  assert.throws(() => validateSecurityComplianceCommand({
    command: C.closeFinding,
    idempotencyKey: 'short',
    payload: {},
  }, C.closeFinding), /idempotencyKey/);
  assert.throws(() => validateSecurityComplianceCommand({
    command: C.closeFinding,
    idempotencyKey: 'strong-key-12345',
    payload: { findingId: 'f-1', expectedRevision: 0, comment: 'ok' },
  }, C.assignFinding), /cannot execute/);
});

test('dates require explicit ISO-8601 date-time syntax', () => {
  const base = {
    title: 'Temporary access',
    requirementOrControl: 'MFA-01',
    businessJustification: 'Migration.',
    scope: 'Legacy gateway',
    riskDescription: 'Credential exposure.',
    compensatingControls: [{ id: 'c-1', description: 'Daily review' }],
    requestedEndAt: '2026-08-10T00:00:00Z',
    reviewAt: '2026-08-05T00:00:00Z',
  };
  for (const unsafe of ['August 1, 2026', '2026-08-01', '08/01/2026']) {
    assert.throws(
      () => command(C.createException, {
        ...base,
        requestedStartAt: unsafe,
      }),
      /ISO-8601/,
    );
  }
  assert.equal(
    command(C.createException, {
      ...base,
      requestedStartAt: '2026-08-01T10:00:00+02:00',
    }).payload.requestedStartAt.toISOString(),
    '2026-08-01T08:00:00.000Z',
  );
});
