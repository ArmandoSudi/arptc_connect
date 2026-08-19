'use strict';

const DEFAULT_INITIAL_PASSWORD = 'Arptc@1234';
const MINIMUM_PASSWORD_LENGTH = 8;

class InitialPasswordError extends Error {
  constructor(code, message) {
    super(message);
    this.name = 'InitialPasswordError';
    this.code = code;
  }
}

function validateReplacementPassword(value) {
  if (typeof value !== 'string' || value.length < MINIMUM_PASSWORD_LENGTH) {
    throw new InitialPasswordError(
      'invalid-argument',
      `The new password must contain at least ${MINIMUM_PASSWORD_LENGTH} characters.`,
    );
  }
  if (value === DEFAULT_INITIAL_PASSWORD) {
    throw new InitialPasswordError(
      'invalid-argument',
      'Choose a password different from the temporary password.',
    );
  }
  return value;
}

async function bootstrapInitialPasswordChange({
  auth,
  db,
  fieldValue,
  uid,
  email,
}) {
  const identity = normalizeIdentity(uid, email);
  const agentRef = db.collection('agents').doc(identity.uid);
  const snapshot = await agentRef.get();
  const agent = requireActiveMatchingAgent(snapshot, identity);
  const passwordChangeRequired = agent.mustChangePassword !== false;

  // Write the guard before verifying legacy Auth identities. A partial failure
  // therefore leaves the account locked down rather than granting app access.
  if (passwordChangeRequired && agent.mustChangePassword !== true) {
    await agentRef.update({
      mustChangePassword: true,
      updatedAt: fieldValue.serverTimestamp(),
    });
  }

  await auth.updateUser(identity.uid, { emailVerified: true });
  return { passwordChangeRequired };
}

async function completeInitialPasswordChange({
  auth,
  db,
  fieldValue,
  uid,
  email,
  newPassword,
}) {
  const identity = normalizeIdentity(uid, email);
  const password = validateReplacementPassword(newPassword);
  const agentRef = db.collection('agents').doc(identity.uid);
  const snapshot = await agentRef.get();
  const agent = requireActiveMatchingAgent(snapshot, identity);

  if (agent.mustChangePassword !== true) {
    return { completed: true, alreadyCompleted: true };
  }

  // Change Auth first. If Firestore is temporarily unavailable, the profile
  // remains locked and the agent can safely retry with another new password.
  await auth.updateUser(identity.uid, {
    password,
    emailVerified: true,
  });
  await agentRef.update({
    mustChangePassword: false,
    passwordChangedAt: fieldValue.serverTimestamp(),
    updatedAt: fieldValue.serverTimestamp(),
  });

  return { completed: true, alreadyCompleted: false };
}

function normalizeIdentity(uid, email) {
  const normalizedUid = normalizeString(uid);
  const normalizedEmail = normalizeString(email).toLowerCase();
  if (!normalizedUid || !normalizedEmail) {
    throw new InitialPasswordError(
      'unauthenticated',
      'A signed-in agent account is required.',
    );
  }
  return { uid: normalizedUid, email: normalizedEmail };
}

function requireActiveMatchingAgent(snapshot, identity) {
  if (!snapshot.exists) {
    throw new InitialPasswordError(
      'not-found',
      'No agent profile is associated with this account.',
    );
  }
  const agent = snapshot.data() || {};
  if (agent.isActive !== true) {
    throw new InitialPasswordError(
      'permission-denied',
      'The agent account is not active.',
    );
  }
  const agentEmail = normalizeString(agent.emailLower || agent.email)
    .toLowerCase();
  if (!agentEmail || agentEmail !== identity.email) {
    throw new InitialPasswordError(
      'permission-denied',
      'The agent profile does not match the signed-in account.',
    );
  }
  return agent;
}

function normalizeString(value) {
  return typeof value === 'string' ? value.trim() : '';
}

module.exports = {
  DEFAULT_INITIAL_PASSWORD,
  InitialPasswordError,
  bootstrapInitialPasswordChange,
  completeInitialPasswordChange,
  validateReplacementPassword,
};
