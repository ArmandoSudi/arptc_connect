'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  createItsmReportingAdministrationCallableHandler,
  safeUnexpectedError,
} = require('../src/itsm_reporting_administration_handlers');
const {
  REPORTING_ADMINISTRATION_COMMANDS: C,
} = require('../src/itsm_reporting_administration_validation');

class HttpsError extends Error {
  constructor(code, message, details) {
    super(message); this.code = code; this.details = details;
  }
}

test('handler rejects unauthenticated calls before profile lookup', async () => {
  let profileRead = false;
  const handler = factory(C.requestAuditExport, async () => {
    profileRead = true; return managerAgent();
  });
  await assert.rejects(handler({ auth: null, data: {} }),
    (error) => error.code === 'unauthenticated');
  assert.equal(profileRead, false);
});

test('ADMIN is rejected from every configuration mutation endpoint', async () => {
  const handler = factory(C.createSlaPolicyDraft, async () => adminAgent());
  await assert.rejects(handler({
    auth: { uid: 'admin-1', token: {} },
    data: {
      command: C.createSlaPolicyDraft,
      idempotencyKey: 'admin-forgery-12345',
      payload: { draft: validSla() },
    },
  }), (error) => error.code === 'permission-denied');
});

test('USER cannot export audits and alias MANAGER passes trusted role resolution', async () => {
  const exportData = {
    command: C.requestAuditExport,
    idempotencyKey: 'audit-export-12345',
    payload: {
      startAt: '2026-08-01T00:00:00Z',
      endAt: '2026-08-02T00:00:00Z',
    },
  };
  await assert.rejects(factory(C.requestAuditExport, async () => userAgent())({
    auth: { uid: 'user-1', token: {} }, data: exportData,
  }), (error) => error.code === 'permission-denied');

  const { command: _, ...endpointData } = exportData;
  await assert.rejects(factory(C.requestAuditExport, async () => aliasManager())({
    auth: { uid: 'manager-1', token: {} }, data: endpointData,
  }), (error) => error.code === 'internal');
});

test('unknown registrations fail and unexpected errors are bounded', () => {
  assert.throws(() => factory('reporting.unknown', async () => managerAgent()),
    /unknown Reporting & Administration command/);
  const safe = safeUnexpectedError('command', {
    name: 'Failure', code: 'x', message: 'm'.repeat(3000), stack: 'line\n'.repeat(2000),
  });
  assert.equal(safe.errorMessage.length, 2000);
  assert(safe.errorStack.length <= 8000);
});

function factory(expectedCommand, findAgent) {
  return createItsmReportingAdministrationCallableHandler({
    expectedCommand,
    db: {},
    fieldValue: {},
    timestamp: {},
    findAgent,
    HttpsError,
    logger: { error: () => {} },
  });
}

function managerAgent() {
  return { isActive: true, firstName: 'Manager', modulePermissions: { ticketing: 'MANAGER' } };
}

function aliasManager() {
  return { isActive: true, firstName: 'Manager', modulePermissions: { support: 'MANAGER' } };
}

function adminAgent() {
  return { isActive: true, firstName: 'Admin', modulePermissions: { ticketing: 'ADMIN' } };
}

function userAgent() {
  return { isActive: true, firstName: 'User', modulePermissions: { ticketing: 'USER' } };
}

function validSla() {
  return {
    name: { en: 'Incident SLA', fr: 'SLA incident' },
    workItemType: 'incident',
    responseTargetMinutes: 60,
    resolutionTargetMinutes: 240,
    timeZone: 'Africa/Kinshasa',
    weeklyWindows: { 1: [{ start: '08:00', end: '17:00' }] },
    holidays: [], pauseStates: [], warningThreshold: 0.8, escalationTargets: [],
  };
}
