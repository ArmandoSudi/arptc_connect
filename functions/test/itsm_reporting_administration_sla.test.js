'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  addBusinessMinutes,
  businessMinutesBetween,
  evaluateSlaState,
  initializeSlaState,
} = require('../src/itsm_reporting_administration_sla');

test('business time skips weekends and holidays in the configured time zone', () => {
  const policy = validPolicy();
  const friday = new Date('2026-08-14T15:00:00Z'); // 16:00 Kinshasa.
  const due = addBusinessMinutes(friday, 120, policy);
  // Monday is configured as a holiday, so the second hour lands Tuesday.
  assert.equal(due.toISOString(), '2026-08-18T08:00:00.000Z');
  assert.equal(businessMinutesBetween(friday, due, policy), 120);
});

test('SLA initialization calculates response, warning and resolution milestones', () => {
  const state = initializeSlaState({
    policy: validPolicy(),
    startedAt: new Date('2026-08-10T07:00:00Z'),
  });
  assert.equal(state.responseWarningAt.toISOString(), '2026-08-10T07:30:00.000Z');
  assert.equal(state.responseDueAt.toISOString(), '2026-08-10T08:00:00.000Z');
  assert.equal(state.resolutionDueAt.toISOString(), '2026-08-10T09:00:00.000Z');
});

test('SLA evaluation warns, breaches and emits deterministic escalation events', () => {
  const policy = validPolicy();
  const state = initializeSlaState({
    policy,
    startedAt: new Date('2026-08-10T07:00:00Z'),
  });
  const warning = evaluateSlaState({
    workItem: { status: 'open', slaState: state },
    policy,
    now: new Date('2026-08-10T07:31:00Z'),
  });
  assert.equal(warning.state.status, 'at_risk');
  assert(warning.events.includes('sla.at_risk'));
  assert(warning.events.includes('sla.manager_escalation'));

  const breached = evaluateSlaState({
    workItem: { status: 'open', slaState: warning.state },
    policy,
    now: new Date('2026-08-10T08:01:00Z'),
  });
  assert.equal(breached.state.status, 'breached');
  assert(breached.events.includes('sla.breached'));
  assert.equal(
    breached.events.filter((event) => event === 'sla.manager_escalation').length,
    0,
  );
});

test('pause and resume shift unresolved due dates by business time', () => {
  const policy = validPolicy();
  const state = initializeSlaState({
    policy,
    startedAt: new Date('2026-08-10T07:00:00Z'),
  });
  const paused = evaluateSlaState({
    workItem: { status: 'awaiting_user', slaState: state },
    policy,
    now: new Date('2026-08-10T07:15:00Z'),
  });
  assert.equal(paused.state.status, 'paused');
  const resumed = evaluateSlaState({
    workItem: { status: 'open', slaState: paused.state },
    policy,
    now: new Date('2026-08-10T07:45:00Z'),
  });
  assert.equal(resumed.state.responseDueAt.toISOString(), '2026-08-10T08:30:00.000Z');
  assert(resumed.events.includes('sla.resumed'));
});

test('completed resolution is marked met when within the pinned deadline', () => {
  const policy = validPolicy();
  const state = initializeSlaState({
    policy,
    startedAt: new Date('2026-08-10T07:00:00Z'),
  });
  const result = evaluateSlaState({
    workItem: {
      status: 'resolved',
      respondedAt: new Date('2026-08-10T07:20:00Z'),
      resolvedAt: new Date('2026-08-10T08:30:00Z'),
      slaState: state,
    },
    policy,
    now: new Date('2026-08-10T08:30:00Z'),
  });
  assert.equal(result.state.status, 'met');
  assert(result.events.includes('sla.met'));
});

function validPolicy() {
  return {
    name: { en: 'Incident SLA', fr: 'SLA incident' },
    workItemType: 'incident',
    priority: 'P2',
    serviceId: 'network',
    responseTargetMinutes: 60,
    resolutionTargetMinutes: 120,
    fulfilmentTargetMinutes: null,
    timeZone: 'Africa/Kinshasa',
    weeklyWindows: {
      1: [{ start: '08:00', end: '17:00' }],
      2: [{ start: '08:00', end: '17:00' }],
      3: [{ start: '08:00', end: '17:00' }],
      4: [{ start: '08:00', end: '17:00' }],
      5: [{ start: '08:00', end: '17:00' }],
    },
    holidays: ['2026-08-17'],
    pauseStates: ['awaiting_user'],
    warningThreshold: 0.5,
    escalationTargets: [{
      eventName: 'sla.manager_escalation',
      assignmentGroupId: 'network-team',
      atPercent: 25,
    }],
  };
}
