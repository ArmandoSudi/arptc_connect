const ITSM_CANONICAL_MODULE_KEY = 'ticketing';
const ITSM_MODULE_ALIASES = Object.freeze([
  'ticketing',
  'itsm',
  'it_service_management',
  'itservicemanagement',
  'support',
  'incident',
  'incidents',
  'incident_management',
  'incidentmanagement',
  'ticket',
  'tickets',
]);

const ITSM_ROLES = Object.freeze({
  none: 'NONE',
  user: 'USER',
  manager: 'MANAGER',
  admin: 'ADMIN',
});

class ItsmCommandError extends Error {
  constructor(code, message, details) {
    super(message);
    this.name = 'ItsmCommandError';
    this.code = code;
    this.details = details;
  }
}

function normalizeString(value) {
  return value === null || value === undefined ? '' : String(value).trim();
}

function normalizeModuleKey(value) {
  return normalizeString(value)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
}

function normalizeRole(value) {
  const role = normalizeString(value).toUpperCase();
  return Object.values(ITSM_ROLES).includes(role) ? role : ITSM_ROLES.none;
}

function normalizedPermissions(agent) {
  const permissions =
    agent && agent.modulePermissions && typeof agent.modulePermissions === 'object'
      ? agent.modulePermissions
      : {};

  return Object.fromEntries(
    Object.entries(permissions).map(([key, value]) => [
      normalizeModuleKey(key),
      value,
    ]),
  );
}

function resolveItsmRole(agent) {
  const permissions = normalizedPermissions(agent);
  if (Object.prototype.hasOwnProperty.call(
    permissions,
    ITSM_CANONICAL_MODULE_KEY,
  )) {
    return normalizeRole(permissions[ITSM_CANONICAL_MODULE_KEY]);
  }

  for (const alias of ITSM_MODULE_ALIASES.slice(1)) {
    if (Object.prototype.hasOwnProperty.call(permissions, alias)) {
      return normalizeRole(permissions[alias]);
    }
  }
  return ITSM_ROLES.none;
}

function requireAuthentication(auth) {
  if (!auth || !normalizeString(auth.uid)) {
    throw new ItsmCommandError(
      'unauthenticated',
      'You must be signed in to perform this ITSM command.',
    );
  }
  // Firebase-issued tokens contain this claim. Test doubles and legacy custom
  // tokens that omit it remain compatible, but an explicit unverified token is
  // never allowed to execute an ITSM command.
  if (auth.token && auth.token.email_verified === false) {
    throw new ItsmCommandError(
      'permission-denied',
      'Verify your email address before using IT Service Management.',
    );
  }
  return auth;
}

function requireActiveAgent(agent) {
  if (!agent) {
    throw new ItsmCommandError(
      'permission-denied',
      'No active agent profile is associated with this account.',
    );
  }
  if (agent.isActive !== true) {
    throw new ItsmCommandError(
      'permission-denied',
      'This agent account is inactive or incomplete.',
    );
  }
  return agent;
}

function requireRole(role, allowedRoles) {
  if (!allowedRoles.includes(role)) {
    throw new ItsmCommandError(
      'permission-denied',
      'Your ITSM role does not allow this command.',
      { role, allowedRoles },
    );
  }
}

function actorFrom(auth, agent, role) {
  const token = auth.token || {};
  const email = normalizeString(agent.email || token.email).toLowerCase();
  const displayName = [
    agent.firstName,
    agent.name,
    agent.postName,
  ]
    .map(normalizeString)
    .filter(Boolean)
    .join(' ');

  return Object.freeze({
    uid: normalizeString(auth.uid),
    email,
    displayName: displayName || normalizeString(token.name),
    role,
  });
}

function isOwnedByActor(record, actor) {
  if (!record || !actor) {
    return false;
  }

  const actorIds = new Set(
    [
      record.createdByUserId,
      record.affectedUserId,
      record.requesterUserId,
      record.requestedByUserId,
      record.ownerUserId,
    ]
      .map(normalizeString)
      .filter(Boolean),
  );
  if (actorIds.has(actor.uid)) {
    return true;
  }

  const actorEmails = new Set(
    [
      record.createdByEmail,
      record.affectedUserEmail,
      record.requesterEmail,
      record.requestedByEmail,
      record.ownerEmail,
    ]
      .map((value) => normalizeString(value).toLowerCase())
      .filter(Boolean),
  );
  return Boolean(actor.email) && actorEmails.has(actor.email);
}

module.exports = {
  ITSM_CANONICAL_MODULE_KEY,
  ITSM_MODULE_ALIASES,
  ITSM_ROLES,
  ItsmCommandError,
  actorFrom,
  isOwnedByActor,
  normalizeModuleKey,
  normalizeRole,
  normalizeString,
  requireActiveAgent,
  requireAuthentication,
  requireRole,
  resolveItsmRole,
};
