'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');
const {
  bootstrapInitialPasswordChange,
  completeInitialPasswordChange,
  validateReplacementPassword,
} = require('../src/initial_password_service');

test('replacement password must differ from the temporary password', () => {
  assert.throws(
    () => validateReplacementPassword('Arptc@1234'),
    (error) => error.code === 'invalid-argument',
  );
  assert.throws(
    () => validateReplacementPassword('short'),
    (error) => error.code === 'invalid-argument',
  );
  assert.equal(validateReplacementPassword('MyOwn@1234'), 'MyOwn@1234');
});

test('bootstrap locks a legacy profile before trusting its Auth email', async () => {
  const events = [];
  const harness = createHarness({
    email: 'agent@example.com',
    isActive: true,
  }, events);

  const result = await bootstrapInitialPasswordChange({
    ...harness.dependencies,
    uid: 'agent-uid',
    email: 'agent@example.com',
  });

  assert.deepEqual(result, { passwordChangeRequired: true });
  assert.equal(harness.agent.mustChangePassword, true);
  assert.deepEqual(events.map((event) => event.type), [
    'agent-update',
    'auth-update',
  ]);
  assert.deepEqual(events[1].data, { emailVerified: true });
});

test('completion changes Auth password before unlocking the profile', async () => {
  const events = [];
  const harness = createHarness({
    emailLower: 'agent@example.com',
    isActive: true,
    mustChangePassword: true,
  }, events);

  const result = await completeInitialPasswordChange({
    ...harness.dependencies,
    uid: 'agent-uid',
    email: 'agent@example.com',
    newPassword: 'Private@456',
  });

  assert.deepEqual(result, { completed: true, alreadyCompleted: false });
  assert.equal(harness.agent.mustChangePassword, false);
  assert.deepEqual(events.map((event) => event.type), [
    'auth-update',
    'agent-update',
  ]);
  assert.deepEqual(events[0].data, {
    password: 'Private@456',
    emailVerified: true,
  });
});

test('bootstrap rejects an agent profile belonging to another email', async () => {
  const harness = createHarness({
    email: 'someone-else@example.com',
    isActive: true,
  });

  await assert.rejects(
    bootstrapInitialPasswordChange({
      ...harness.dependencies,
      uid: 'agent-uid',
      email: 'agent@example.com',
    }),
    (error) => error.code === 'permission-denied',
  );
});

function createHarness(initialAgent, events = []) {
  const agent = { ...initialAgent };
  const agentRef = {
    async get() {
      return {
        exists: true,
        data: () => ({ ...agent }),
      };
    },
    async update(data) {
      events.push({ type: 'agent-update', data });
      Object.assign(agent, data);
    },
  };
  return {
    agent,
    dependencies: {
      auth: {
        async updateUser(uid, data) {
          assert.equal(uid, 'agent-uid');
          events.push({ type: 'auth-update', data });
        },
      },
      db: {
        collection(name) {
          assert.equal(name, 'agents');
          return {
            doc(uid) {
              assert.equal(uid, 'agent-uid');
              return agentRef;
            },
          };
        },
      },
      fieldValue: {
        serverTimestamp: () => 'SERVER_TIMESTAMP',
      },
    },
  };
}
