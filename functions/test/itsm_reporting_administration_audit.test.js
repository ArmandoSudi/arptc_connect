'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  auditEventsToCsv,
  canExportAuditEvent,
  matchesFilters,
  normalizeAuditEvent,
  requireAuditExportRole,
} = require('../src/itsm_reporting_administration_audit');

test('audit aliases normalize to the canonical append-only shape', () => {
  const event = normalizeAuditEvent('event-1', {
    targetEntityType: 'incident',
    targetEntityId: 'INC-1',
    actorUserId: 'manager-1',
    actorRole: 'MANAGER',
    previousValues: { status: 'open' },
    newValues: { status: 'assigned' },
    confidentiality: 'INTERNAL',
    createdAt: '2026-08-10T10:00:00Z',
  });
  assert.equal(event.entityType, 'incident');
  assert.equal(event.entityId, 'INC-1');
  assert.equal(event.actor.userId, 'manager-1');
  assert.deepEqual(event.before, { status: 'open' });
  assert.equal(event.confidentiality, 'internal');
});

test('ADMIN never exports restricted audit and MANAGER needs explicit authorization', () => {
  const restricted = normalizeAuditEvent('event-1', {
    isRestricted: true,
    authorizedManagerIds: ['manager-1'],
  });
  assert.equal(canExportAuditEvent(restricted, { role: 'ADMIN', userId: 'admin-1' }), false);
  assert.equal(canExportAuditEvent(restricted, { role: 'MANAGER', userId: 'manager-2' }), false);
  assert.equal(canExportAuditEvent(restricted, { role: 'MANAGER', userId: 'manager-1' }), true);
  assert.throws(() => requireAuditExportRole('USER'), /Only ITSM MANAGER and ADMIN/);
});

test('audit filters are normalized and applied without broadening scope', () => {
  const event = normalizeAuditEvent('event-1', {
    module: 'ticketing', entityType: 'incident', entityId: 'INC-1',
    action: 'assigned', actor: { userId: 'manager-1' },
    confidentiality: 'internal',
  });
  assert.equal(matchesFilters(event, {
    module: 'TICKETING', entityType: 'INCIDENT', actorUserId: 'manager-1',
  }), true);
  assert.equal(matchesFilters(event, { entityId: 'INC-2' }), false);
});

test('CSV output escapes formulas, quotes and newlines', () => {
  const event = normalizeAuditEvent('=danger', {
    action: 'updated',
    entityType: 'incident',
    entityId: 'INC-1',
    comment: 'A "quoted"\ncomment',
    occurredAt: '2026-08-10T10:00:00Z',
  });
  const csv = auditEventsToCsv([event]);
  assert(csv.includes("'=danger"));
  assert(csv.includes('""quoted""'));
  assert(csv.endsWith('\r\n'));
});
