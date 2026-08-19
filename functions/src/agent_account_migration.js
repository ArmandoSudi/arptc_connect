'use strict';

const { createHash } = require('node:crypto');

class AgentAccountMigrationError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

async function migrateLegacyAgentAccount({
  db,
  auth,
  fieldValue,
  legacyAgentId,
  actorUid,
  defaultPassword,
}) {
  const legacyId = normalizeString(legacyAgentId);
  const managerId = normalizeString(actorUid);
  if (!legacyId || !managerId) {
    throw new AgentAccountMigrationError(
      'invalid-argument',
      'A legacy agent ID and manager identity are required.',
    );
  }

  const migrationRef = db
    .collection('agentIdentityMigrations')
    .doc(migrationDocumentId(legacyId));
  const priorMigration = await migrationRef.get();
  if (priorMigration.exists) {
    return completedMigrationResult(priorMigration.data() || {});
  }

  const legacyRef = db.collection('agents').doc(legacyId);
  const initialLegacySnapshot = await legacyRef.get();
  if (!initialLegacySnapshot.exists) {
    throw new AgentAccountMigrationError(
      'not-found',
      'The legacy agent profile no longer exists.',
    );
  }

  const initialLegacyData = initialLegacySnapshot.data() || {};
  const email = normalizedAgentEmail(initialLegacyData);
  if (!isValidEmail(email)) {
    throw new AgentAccountMigrationError(
      'failed-precondition',
      'The legacy agent profile must have a valid email address.',
    );
  }

  let authUser;
  let authAccountCreated = false;
  try {
    try {
      authUser = await auth.getUserByEmail(email);
    } catch (error) {
      if (error?.code !== 'auth/user-not-found') throw error;
      authUser = await auth.createUser({
        email,
        password: defaultPassword,
        displayName: displayNameFor(initialLegacyData),
        disabled: initialLegacyData.isActive === false,
      });
      authAccountCreated = true;
    }

    const canonicalRef = db.collection('agents').doc(authUser.uid);
    const initialCanonicalSnapshot = await canonicalRef.get();
    const initialCanonicalData = initialCanonicalSnapshot.data() || {};
    if (
      initialCanonicalSnapshot.exists &&
      normalizedAgentEmail(initialCanonicalData) !== email
    ) {
      throw new AgentAccountMigrationError(
        'already-exists',
        'This Firebase Auth account is already linked to another agent profile.',
      );
    }

    const result = await db.runTransaction(async (transaction) => {
      const migrationSnapshot = await transaction.get(migrationRef);
      if (migrationSnapshot.exists) {
        return completedMigrationResult(migrationSnapshot.data() || {});
      }

      const legacySnapshot = await transaction.get(legacyRef);
      if (!legacySnapshot.exists) {
        throw new AgentAccountMigrationError(
          'aborted',
          'The legacy agent profile changed during migration. Try again.',
        );
      }

      const legacyData = legacySnapshot.data() || {};
      const currentEmail = normalizedAgentEmail(legacyData);
      if (currentEmail !== email) {
        throw new AgentAccountMigrationError(
          'aborted',
          'The legacy agent email changed. Review the profile and try again.',
        );
      }

      const canonicalSnapshot = legacyId === authUser.uid
        ? legacySnapshot
        : await transaction.get(canonicalRef);
      const canonicalData = canonicalSnapshot.data() || {};
      if (
        canonicalSnapshot.exists &&
        normalizedAgentEmail(canonicalData) !== email
      ) {
        throw new AgentAccountMigrationError(
          'already-exists',
          'This Firebase Auth account is already linked to another agent profile.',
        );
      }

      const timestamp = fieldValue.serverTimestamp();
      const alreadyCanonical = legacyId === authUser.uid ||
        canonicalSnapshot.exists;
      const hasPlacement = hasCurrentOrganizationPlacement(canonicalData);
      transaction.set(
        canonicalRef,
        canonicalProfile({
          sourceData: { ...legacyData, ...canonicalData },
          canonicalData,
          email,
          legacyId,
          actorUid: managerId,
          timestamp,
        }),
      );

      if (legacyId !== authUser.uid) {
        transaction.delete(legacyRef);
      }
      if (!hasPlacement) {
        transaction.delete(db.collection('agentDirectory').doc(authUser.uid));
        transaction.delete(
          db.collection('agentAuthorizationIndex').doc(authUser.uid),
        );
      }
      transaction.set(migrationRef, {
        sourceAgentId: legacyId,
        targetAgentId: authUser.uid,
        migratedByUserId: managerId,
        migratedAt: timestamp,
        requiresOrganizationAssignment: !hasPlacement,
      });

      return {
        uid: authUser.uid,
        authAccountCreated,
        alreadyCanonical,
        requiresOrganizationAssignment: !hasPlacement,
      };
    });

    return result;
  } catch (error) {
    if (authAccountCreated && authUser?.uid) {
      try {
        await auth.deleteUser(authUser.uid);
      } catch (_) {
        // Firestore did not commit, so a later migration can safely retry.
      }
    }
    throw normalizeMigrationError(error);
  }
}

function canonicalProfile({
  sourceData,
  canonicalData,
  email,
  legacyId,
  actorUid,
  timestamp,
}) {
  const {
    id: _legacyEmbeddedId,
    direction: _legacyDirection,
    direction_ref: _legacyDirectionRef,
    departmentId: _legacyDepartmentId,
    department: _legacyDepartment,
    serviceId: _legacyServiceId,
    service: _legacyService,
    bureauId: _legacyBureauId,
    bureau: _legacyBureau,
    position: _legacyPosition,
    organizationSchemaVersion: _legacyOrganizationSchemaVersion,
    organizationId: _legacyOrganizationId,
    organizationName: _legacyOrganizationName,
    primaryOrganizationUnitId: _legacyPrimaryUnitId,
    primaryOrganizationUnitName: _legacyPrimaryUnitName,
    primaryOrganizationUnitType: _legacyPrimaryUnitType,
    primaryAssignmentId: _legacyPrimaryAssignmentId,
    organizationAncestorUnitIds: _legacyAncestorUnitIds,
    organizationPathUnitIds: _legacyPathUnitIds,
    organizationPathNames: _legacyPathNames,
    scopeKeys: _legacyScopeKeys,
    migration: _legacyMigration,
    ...retainedData
  } = sourceData;

  return {
    ...retainedData,
    ...currentPlacementProjection(canonicalData),
    email,
    emailLower: email,
    isActive: sourceData.isActive !== false,
    modulePermissions: normalizedPermissions(sourceData.modulePermissions),
    updatedAt: timestamp,
    migration: {
      sourceAgentId: legacyId,
      migratedByUserId: actorUid,
      migratedAt: timestamp,
    },
  };
}

function hasCurrentOrganizationPlacement(data) {
  return Number(data && data.organizationSchemaVersion) === 2 &&
    Boolean(normalizeString(data && data.organizationId)) &&
    Boolean(normalizeString(data && data.primaryOrganizationUnitId)) &&
    Boolean(normalizeString(data && data.primaryAssignmentId));
}

function currentPlacementProjection(data) {
  if (!hasCurrentOrganizationPlacement(data)) return {};
  return {
    organizationSchemaVersion: 2,
    organizationId: normalizeString(data.organizationId),
    organizationName: normalizeString(data.organizationName),
    primaryOrganizationUnitId: normalizeString(data.primaryOrganizationUnitId),
    primaryOrganizationUnitName: normalizeString(data.primaryOrganizationUnitName),
    primaryOrganizationUnitType: normalizeString(data.primaryOrganizationUnitType),
    primaryAssignmentId: normalizeString(data.primaryAssignmentId),
    organizationAncestorUnitIds: stringArray(data.organizationAncestorUnitIds),
    organizationPathUnitIds: stringArray(data.organizationPathUnitIds),
    organizationPathNames: stringArray(data.organizationPathNames),
    scopeKeys: stringArray(data.scopeKeys),
    departmentId: normalizeString(data.departmentId),
    department: normalizeString(data.department),
    serviceId: normalizeString(data.serviceId),
    service: normalizeString(data.service),
    bureauId: normalizeString(data.bureauId),
    bureau: normalizeString(data.bureau),
  };
}

function completedMigrationResult(data) {
  const uid = normalizeString(data.targetAgentId);
  if (!uid) {
    throw new AgentAccountMigrationError(
      'failed-precondition',
      'The previous migration receipt is invalid.',
    );
  }
  return {
    uid,
    authAccountCreated: false,
    alreadyCanonical: true,
    requiresOrganizationAssignment:
      data.requiresOrganizationAssignment !== false,
  };
}

function migrationDocumentId(legacyId) {
  return createHash('sha256').update(legacyId).digest('hex');
}

function normalizedPermissions(value) {
  return value && typeof value === 'object' && !Array.isArray(value)
    ? value
    : {};
}

function normalizedAgentEmail(data) {
  return normalizeString(data.emailLower || data.email).toLowerCase();
}

function displayNameFor(data) {
  return [data.firstName, data.name, data.postName]
    .map(normalizeString)
    .filter(Boolean)
    .join(' ');
}

function stringArray(value) {
  return Array.isArray(value) ? value.map(normalizeString).filter(Boolean) : [];
}

function normalizeString(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function isValidEmail(value) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

function normalizeMigrationError(error) {
  if (error instanceof AgentAccountMigrationError) return error;
  if (
    error &&
    ['invalid-argument', 'not-found', 'failed-precondition'].includes(error.code)
  ) {
    return new AgentAccountMigrationError(error.code, error.message);
  }
  return new AgentAccountMigrationError(
    'internal',
    'Unable to migrate the legacy agent profile.',
  );
}

module.exports = {
  AgentAccountMigrationError,
  migrateLegacyAgentAccount,
  migrationDocumentId,
};
