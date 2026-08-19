const assert = require('node:assert/strict');
const test = require('node:test');

const {
  ITSM_ROLES,
  ItsmCommandError,
  actorFrom,
  isOwnedByActor,
  requireActiveAgent,
  requireAuthentication,
  requireRole,
  resolveItsmRole,
} = require('../src/itsm_permissions');

test('authentication rejects a missing Firebase principal', () => {
  assert.throws(
    () => requireAuthentication(null),
    (error) =>
      error instanceof ItsmCommandError &&
      error.code === 'unauthenticated',
  );
  assert.equal(requireAuthentication({ uid: 'agent-1' }).uid, 'agent-1');
  assert.throws(
    () => requireAuthentication({
      uid: 'agent-1',
      token: { email_verified: false },
    }),
    (error) =>
      error instanceof ItsmCommandError &&
      error.code === 'permission-denied',
  );
});

test('commands require an explicitly active UID agent profile', () => {
  assert.doesNotThrow(() => requireActiveAgent({ isActive: true }));

  for (const agent of [null, {}, { isActive: false }]) {
    assert.throws(
      () => requireActiveAgent(agent),
      (error) =>
        error instanceof ItsmCommandError &&
        error.code === 'permission-denied',
    );
  }
});

test('ticketing is canonical and aliases are fallback-only', () => {
  assert.equal(
    resolveItsmRole({
      modulePermissions: { ticketing: 'ADMIN', itsm: 'MANAGER' },
    }),
    ITSM_ROLES.admin,
  );
  assert.equal(
    resolveItsmRole({
      modulePermissions: { 'IT Service Management': 'manager' },
    }),
    ITSM_ROLES.manager,
  );
  assert.equal(resolveItsmRole({ modulePermissions: {} }), ITSM_ROLES.none);
});

test('role checks keep ADMIN read-only and permit operational MANAGER access', () => {
  assert.doesNotThrow(() =>
    requireRole(ITSM_ROLES.manager, [ITSM_ROLES.manager]),
  );
  assert.throws(
    () => requireRole(ITSM_ROLES.admin, [ITSM_ROLES.manager]),
    (error) =>
      error instanceof ItsmCommandError &&
      error.code === 'permission-denied',
  );
});

test('ownership supports UID and normalized email compatibility', () => {
  const actor = actorFrom(
    { uid: 'auth-1', token: { email: 'USER@ARPTC.CD' } },
    { firstName: 'A', name: 'User', modulePermissions: {} },
    ITSM_ROLES.user,
  );

  assert.equal(
    isOwnedByActor({ createdByUserId: 'auth-1' }, actor),
    true,
  );
  assert.equal(
    isOwnedByActor({ affectedUserEmail: 'user@arptc.cd' }, actor),
    true,
  );
  assert.equal(
    isOwnedByActor({ createdByUserId: 'someone-else' }, actor),
    false,
  );
});
