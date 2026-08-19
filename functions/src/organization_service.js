'use strict';

const { createHash } = require('node:crypto');
const { FieldPath } = require('firebase-admin/firestore');

const {
  OrganizationDomainError,
  buildAgentAuthorizationProjection,
  buildAgentDirectoryProjection,
  buildAgentOrganizationProjection,
  buildAssignmentDocument,
  buildOrganizationUnitProjection,
  normalizeCode,
  normalizeStatus,
  normalizeString,
  normalizeUnitType,
  validateOrganizationInput,
  validateUnitInput,
} = require('./organization_domain');

const ORGANIZATION_COMMANDS = Object.freeze({
  createOrganization: 'createOrganization',
  updateOrganization: 'updateOrganization',
  archiveOrganization: 'archiveOrganization',
  createOrganizationUnit: 'createOrganizationUnit',
  updateOrganizationUnit: 'updateOrganizationUnit',
  moveOrganizationUnit: 'moveOrganizationUnit',
  archiveOrganizationUnit: 'archiveOrganizationUnit',
  assignAgentOrganization: 'assignAgentOrganization',
  transferAgentOrganization: 'transferAgentOrganization',
  setOrganizationUnitHead: 'setOrganizationUnitHead',
  endOrganizationUnitHead: 'endOrganizationUnitHead',
  deactivateAgentAccount: 'deactivateAgentAccount',
  auditOrganizationArchitecture: 'auditOrganizationArchitecture',
});

const MAX_AUDIT_DOCUMENTS_PER_COLLECTION = 5000;
const AGENT_PLACEMENT_FIELDS = Object.freeze([
  'organizationSchemaVersion',
  'organizationId',
  'organizationName',
  'primaryOrganizationUnitId',
  'primaryOrganizationUnitName',
  'primaryOrganizationUnitType',
  'primaryAssignmentId',
  'organizationAncestorUnitIds',
  'organizationPathUnitIds',
  'organizationPathNames',
  'scopeKeys',
  'departmentId',
  'department',
  'serviceId',
  'service',
  'bureauId',
  'bureau',
]);
const DIRECTORY_PROJECTION_FIELDS = Object.freeze([
  'displayName',
  'displayNameLower',
  'firstName',
  'name',
  'postName',
  'email',
  'profilePictureUrl',
  'jobTitle',
  'organizationId',
  'organizationName',
  'primaryOrganizationUnitId',
  'primaryOrganizationUnitName',
  'primaryOrganizationUnitType',
  'departmentId',
  'serviceId',
  'bureauId',
  'organizationPathNames',
  'scopeKeys',
  'isActive',
]);
const AUTHORIZATION_PROJECTION_FIELDS = Object.freeze([
  'organizationId',
  'primaryUnitId',
  'scopeKeys',
  'moduleRoleKeys',
  'scopeRoleKeys',
  'isActive',
  'schemaVersion',
]);

async function executeOrganizationCommand({
  db,
  fieldValue,
  timestamp,
  command,
  payload,
  actor,
}) {
  const actorUid = normalizeString(actor && actor.uid);
  const data = payload && typeof payload === 'object' ? payload : {};
  if (!actorUid) {
    throw new OrganizationDomainError(
      'unauthenticated',
      'An authenticated actor is required.',
    );
  }
  switch (command) {
    case ORGANIZATION_COMMANDS.createOrganization:
      return createOrganization({ db, fieldValue, payload: data, actorUid });
    case ORGANIZATION_COMMANDS.updateOrganization:
      return updateOrganization({ db, fieldValue, payload: data, actorUid });
    case ORGANIZATION_COMMANDS.archiveOrganization:
      return archiveOrganization({ db, fieldValue, payload: data, actorUid });
    case ORGANIZATION_COMMANDS.createOrganizationUnit:
      return createOrganizationUnit({ db, fieldValue, payload: data, actorUid });
    case ORGANIZATION_COMMANDS.updateOrganizationUnit:
      return updateOrganizationUnit({ db, fieldValue, payload: data, actorUid });
    case ORGANIZATION_COMMANDS.moveOrganizationUnit:
      return moveOrganizationUnit({ db, fieldValue, payload: data, actorUid });
    case ORGANIZATION_COMMANDS.archiveOrganizationUnit:
      return archiveOrganizationUnit({ db, fieldValue, payload: data, actorUid });
    case ORGANIZATION_COMMANDS.assignAgentOrganization:
    case ORGANIZATION_COMMANDS.transferAgentOrganization:
      return assignAgentOrganization({
        db,
        fieldValue,
        timestamp,
        payload: data,
        actorUid,
        isTransfer: command === ORGANIZATION_COMMANDS.transferAgentOrganization,
      });
    case ORGANIZATION_COMMANDS.setOrganizationUnitHead:
      return setOrganizationUnitHead({
        db,
        fieldValue,
        timestamp,
        payload: data,
        actorUid,
      });
    case ORGANIZATION_COMMANDS.endOrganizationUnitHead:
      return endOrganizationUnitHead({
        db,
        fieldValue,
        payload: data,
        actorUid,
      });
    case ORGANIZATION_COMMANDS.deactivateAgentAccount:
      return deactivateAgentAccount({
        db,
        fieldValue,
        timestamp,
        payload: data,
        actorUid,
      });
    case ORGANIZATION_COMMANDS.auditOrganizationArchitecture:
      return auditOrganizationArchitecture({
        db,
        fieldValue,
        timestamp,
        payload: data,
        actorUid,
      });
    default:
      throw new OrganizationDomainError(
        'invalid-argument',
        `Unsupported organization command: ${normalizeString(command) || '(empty)'}.`,
      );
  }
}

async function createOrganization({ db, fieldValue, payload, actorUid }) {
  const input = validateOrganizationInput(payload);
  const organizationRef = db.collection('organizations').doc();
  const codeLockRef = db.collection('organizationCodeLocks').doc(input.code);
  return runCommandTransaction({
    db,
    fieldValue,
    payload,
    actorUid,
    command: ORGANIZATION_COMMANDS.createOrganization,
    organizationId: organizationRef.id,
    work: async (transaction, context) => {
      const codeLock = await transaction.get(codeLockRef);
      if (codeLock.exists) {
        throw new OrganizationDomainError(
          'already-exists',
          'An organization already uses this code.',
        );
      }
      transaction.create(codeLockRef, {
        organizationId: organizationRef.id,
        code: input.code,
        createdAt: context.now,
      });
      transaction.create(organizationRef, {
        ...input,
        status: 'ACTIVE',
        schemaVersion: 2,
        createdAt: context.now,
        createdBy: actorUid,
        updatedAt: context.now,
        updatedBy: actorUid,
        archivedAt: null,
        archivedBy: null,
      });
      transaction.create(
        db.collection('organizationDirectory').doc(organizationRef.id),
        {
          name: input.name,
          nameLower: input.nameLower,
          status: 'ACTIVE',
          updatedAt: context.now,
        },
      );
      context.audit({
        eventType: 'ORGANIZATION_CREATED',
        organizationId: organizationRef.id,
        after: { code: input.code, name: input.name, status: 'ACTIVE' },
      });
      return { organizationId: organizationRef.id };
    },
  });
}

async function updateOrganization({ db, fieldValue, payload, actorUid }) {
  const organizationId = requiredId(payload.organizationId, 'organization');
  const input = validateOrganizationInput(payload);
  const organizationRef = db.collection('organizations').doc(organizationId);
  return runCommandTransaction({
    db,
    fieldValue,
    payload,
    actorUid,
    command: ORGANIZATION_COMMANDS.updateOrganization,
    organizationId,
    work: async (transaction, context) => {
      const snapshot = await transaction.get(organizationRef);
      if (!snapshot.exists) throw notFound('Organization');
      const current = snapshot.data() || {};
      if (normalizeStatus(current.status) === 'ARCHIVED') {
        throw failedPrecondition('An archived organization cannot be edited.');
      }
      const renamed = input.name !== normalizeString(current.name);
      const agentSnapshot = renamed
        ? await transaction.get(db.collection('agents')
          .where('organizationId', '==', organizationId)
          .limit(101))
        : null;
      if (agentSnapshot && agentSnapshot.size > 100) {
        throw failedPrecondition(
          'This organization rename affects too many agents for an interactive update.',
        );
      }
      const currentCode = normalizeCode(current.code);
      if (input.code !== currentCode) {
        const nextLockRef = db.collection('organizationCodeLocks').doc(input.code);
        const nextLock = await transaction.get(nextLockRef);
        if (nextLock.exists &&
          normalizeString(nextLock.get('organizationId')) !== organizationId) {
          throw new OrganizationDomainError(
            'already-exists',
            'An organization already uses this code.',
          );
        }
        if (!nextLock.exists) {
          transaction.create(nextLockRef, {
            organizationId,
            code: input.code,
            createdAt: context.now,
          });
        }
      }
      const status = payload.status
        ? normalizeStatus(payload.status)
        : normalizeStatus(current.status);
      if (status === 'ARCHIVED') {
        throw failedPrecondition('Use the archive organization action.');
      }
      transaction.update(organizationRef, {
        ...input,
        status,
        updatedAt: context.now,
        updatedBy: actorUid,
      });
      transaction.set(
        db.collection('organizationDirectory').doc(organizationId),
        {
          name: input.name,
          nameLower: input.nameLower,
          status,
          updatedAt: context.now,
        },
        { merge: false },
      );
      if (agentSnapshot) {
        for (const agentDocument of agentSnapshot.docs) {
          transaction.set(agentDocument.ref, {
            organizationName: input.name,
            updatedAt: context.now,
          }, { merge: true });
          transaction.set(db.collection('agentDirectory').doc(agentDocument.id), {
            organizationName: input.name,
            updatedAt: context.now,
          }, { merge: true });
        }
      }
      context.audit({
        eventType: 'ORGANIZATION_UPDATED',
        organizationId,
        before: organizationSummary(current),
        after: { ...input, status },
      });
      return { organizationId };
    },
  });
}

async function archiveOrganization({ db, fieldValue, payload, actorUid }) {
  const organizationId = requiredId(payload.organizationId, 'organization');
  const reason = requiredReason(payload.reason);
  const organizationRef = db.collection('organizations').doc(organizationId);
  return runCommandTransaction({
    db,
    fieldValue,
    payload,
    actorUid,
    command: ORGANIZATION_COMMANDS.archiveOrganization,
    organizationId,
    work: async (transaction, context) => {
      const [organizationSnapshot, unitSnapshot, assignmentSnapshot, agentSnapshot] =
        await Promise.all([
          transaction.get(organizationRef),
          transaction.get(db.collection('organizationUnits')
            .where('organizationId', '==', organizationId)
            .where('status', '==', 'ACTIVE')
            .limit(1)),
          transaction.get(db.collection('organizationAssignments')
            .where('organizationId', '==', organizationId)
            .where('status', '==', 'ACTIVE')
            .limit(1)),
          transaction.get(db.collection('agents')
            .where('organizationId', '==', organizationId)
            .where('isActive', '==', true)
            .limit(1)),
        ]);
      if (!organizationSnapshot.exists) throw notFound('Organization');
      if (!unitSnapshot.empty || !assignmentSnapshot.empty || !agentSnapshot.empty) {
        throw failedPrecondition(
          'Archive units and end all active agents and assignments first.',
        );
      }
      transaction.update(organizationRef, {
        status: 'ARCHIVED',
        archivedAt: context.now,
        archivedBy: actorUid,
        updatedAt: context.now,
        updatedBy: actorUid,
      });
      transaction.set(
        db.collection('organizationDirectory').doc(organizationId),
        {
          name: normalizeString(organizationSnapshot.get('name')),
          nameLower: normalizeString(organizationSnapshot.get('nameLower')),
          status: 'ARCHIVED',
          updatedAt: context.now,
        },
        { merge: false },
      );
      context.audit({
        eventType: 'ORGANIZATION_ARCHIVED',
        organizationId,
        reason,
        before: organizationSummary(organizationSnapshot.data() || {}),
        after: { status: 'ARCHIVED' },
      });
      return { organizationId };
    },
  });
}

async function createOrganizationUnit({ db, fieldValue, payload, actorUid }) {
  const input = validateUnitInput(payload);
  const unitRef = db.collection('organizationUnits').doc();
  const organizationRef = db.collection('organizations').doc(input.organizationId);
  const parentRef = input.parentUnitId
    ? db.collection('organizationUnits').doc(input.parentUnitId)
    : null;
  const lockRef = unitCodeLockRef(db, input.organizationId, input.code);
  return runCommandTransaction({
    db,
    fieldValue,
    payload,
    actorUid,
    command: ORGANIZATION_COMMANDS.createOrganizationUnit,
    organizationId: input.organizationId,
    work: async (transaction, context) => {
      const organizationSnapshot = await transaction.get(organizationRef);
      const parentSnapshot = parentRef ? await transaction.get(parentRef) : null;
      const lockSnapshot = await transaction.get(lockRef);
      if (!organizationSnapshot.exists) throw notFound('Organization');
      if (parentRef && (!parentSnapshot || !parentSnapshot.exists)) {
        throw notFound('Parent organization unit');
      }
      if (lockSnapshot.exists) {
        throw new OrganizationDomainError(
          'already-exists',
          'An organization unit already uses this code.',
        );
      }
      const projection = buildOrganizationUnitProjection({
        unitId: unitRef.id,
        organization: {
          id: organizationSnapshot.id,
          ...(organizationSnapshot.data() || {}),
        },
        input,
        parent: parentSnapshot
          ? { id: parentSnapshot.id, ...(parentSnapshot.data() || {}) }
          : null,
      });
      transaction.create(lockRef, {
        organizationId: input.organizationId,
        unitId: unitRef.id,
        code: input.code,
        createdAt: context.now,
      });
      transaction.create(unitRef, {
        ...projection,
        createdAt: context.now,
        createdBy: actorUid,
        updatedAt: context.now,
        updatedBy: actorUid,
        archivedAt: null,
        archivedBy: null,
      });
      context.audit({
        eventType: 'ORGANIZATION_UNIT_CREATED',
        organizationId: input.organizationId,
        unitId: unitRef.id,
        after: unitSummary(projection),
      });
      return { organizationUnitId: unitRef.id };
    },
  });
}

async function updateOrganizationUnit({ db, fieldValue, payload, actorUid }) {
  const unitId = requiredId(payload.organizationUnitId || payload.unitId, 'unit');
  const unitRef = db.collection('organizationUnits').doc(unitId);
  return runCommandTransaction({
    db,
    fieldValue,
    payload,
    actorUid,
    command: ORGANIZATION_COMMANDS.updateOrganizationUnit,
    organizationId: normalizeString(payload.organizationId),
    work: async (transaction, context) => {
      const snapshot = await transaction.get(unitRef);
      if (!snapshot.exists) throw notFound('Organization unit');
      const current = { id: snapshot.id, ...(snapshot.data() || {}) };
      const organizationId = normalizeString(current.organizationId);
      const input = validateUnitInput({
        organizationId,
        type: current.type,
        parentUnitId: current.parentUnitId,
        code: payload.code,
        name: payload.name,
        description: payload.description,
      });
      if (normalizeStatus(current.status) === 'ARCHIVED') {
        throw failedPrecondition('An archived organization unit cannot be edited.');
      }
      const status = payload.status
        ? normalizeStatus(payload.status)
        : normalizeStatus(current.status);
      if (status === 'ARCHIVED') {
        throw failedPrecondition('Use the archive organization unit action.');
      }
      const currentCode = normalizeCode(current.code);
      let nextLockRef = null;
      let shouldCreateNextLock = false;
      if (input.code !== currentCode) {
        nextLockRef = unitCodeLockRef(db, organizationId, input.code);
        const nextLock = await transaction.get(nextLockRef);
        if (nextLock.exists &&
          normalizeString(nextLock.get('unitId')) !== unitId) {
          throw new OrganizationDomainError(
            'already-exists',
            'An organization unit already uses this code.',
          );
        }
        shouldCreateNextLock = !nextLock.exists;
      }
      const renamed = input.name !== normalizeString(current.name);
      const projectionReads = renamed
        ? await readBoundedRenameProjection(transaction, db, unitId)
        : { descendants: [], assignments: [], agents: new Map() };
      // Firestore transactions reject reads after their first write. The code
      // lock is therefore written only after all rename projections are read.
      if (shouldCreateNextLock) {
        transaction.create(nextLockRef, {
          organizationId,
          unitId,
          code: input.code,
          createdAt: context.now,
        });
      }
      transaction.update(unitRef, {
        code: input.code,
        name: input.name,
        nameLower: input.nameLower,
        description: input.description,
        status,
        pathNames: replacePathName(current, unitId, input.name),
        updatedAt: context.now,
        updatedBy: actorUid,
      });
      if (renamed) {
        applyRenameProjectionWrites({
          transaction,
          db,
          fieldValue,
          unitId,
          unitType: normalizeUnitType(current.type),
          unitName: input.name,
          actorUid,
          now: context.now,
          ...projectionReads,
        });
      }
      context.setOrganizationId(organizationId);
      context.audit({
        eventType: 'ORGANIZATION_UNIT_UPDATED',
        organizationId,
        unitId,
        before: unitSummary(current),
        after: unitSummary({ ...current, ...input, status }),
      });
      return { organizationUnitId: unitId };
    },
  });
}

async function moveOrganizationUnit({ db, fieldValue, payload, actorUid }) {
  const unitId = requiredId(payload.organizationUnitId || payload.unitId, 'unit');
  const parentUnitId = requiredId(payload.parentUnitId, 'parent unit');
  const reason = requiredReason(payload.reason);
  const unitRef = db.collection('organizationUnits').doc(unitId);
  const parentRef = db.collection('organizationUnits').doc(parentUnitId);
  return runCommandTransaction({
    db,
    fieldValue,
    payload,
    actorUid,
    command: ORGANIZATION_COMMANDS.moveOrganizationUnit,
    organizationId: normalizeString(payload.organizationId),
    work: async (transaction, context) => {
      const [unitSnapshot, parentSnapshot] = await Promise.all([
        transaction.get(unitRef),
        transaction.get(parentRef),
      ]);
      if (!unitSnapshot.exists) throw notFound('Organization unit');
      if (!parentSnapshot.exists) throw notFound('Parent organization unit');
      const current = { id: unitSnapshot.id, ...(unitSnapshot.data() || {}) };
      const parent = {
        id: parentSnapshot.id,
        ...(parentSnapshot.data() || {}),
      };
      const organizationId = normalizeString(current.organizationId);
      if (normalizeUnitType(current.type) === 'DEPARTMENT') {
        throw failedPrecondition('A department must remain a root unit.');
      }
      if (normalizeString(current.parentUnitId) === parentUnitId) {
        throw failedPrecondition('The organization unit already has this parent.');
      }
      if (array(parent.pathUnitIds).includes(unitId)) {
        throw failedPrecondition('An organization unit cannot move below itself.');
      }

      const organizationRef = db.collection('organizations').doc(organizationId);
      const [organizationSnapshot, descendantsSnapshot, recipientsSnapshot] =
        await Promise.all([
          transaction.get(organizationRef),
          transaction.get(db.collection('organizationUnits')
            .where('ancestorUnitIds', 'array-contains', unitId)
            .limit(101)),
          transaction.get(db.collection('agentAuthorizationIndex')
            .where('organizationId', '==', organizationId)
            .where('isActive', '==', true)
            .where('scopeKeys', 'array-contains', `unit:${unitId}`)
            .limit(101)),
        ]);
      if (!organizationSnapshot.exists) throw notFound('Organization');
      if (descendantsSnapshot.size > 100 || recipientsSnapshot.size > 100) {
        throw failedPrecondition(
          'This move affects too many records for an interactive update.',
        );
      }
      const organization = {
        id: organizationSnapshot.id,
        ...(organizationSnapshot.data() || {}),
      };
      const rootProjection = buildOrganizationUnitProjection({
        unitId,
        organization,
        input: {
          organizationId,
          type: current.type,
          code: current.code,
          name: current.name,
          description: current.description,
          parentUnitId,
        },
        parent,
      });
      const projectedUnits = new Map([[unitId, {
        ...current,
        ...rootProjection,
      }]]);
      const descendants = descendantsSnapshot.docs
        .map((snapshot) => ({ id: snapshot.id, ...(snapshot.data() || {}) }))
        .sort((left, right) => Number(left.depth) - Number(right.depth));
      for (const descendant of descendants) {
        const projectedParent = projectedUnits.get(
          normalizeString(descendant.parentUnitId),
        );
        if (!projectedParent) {
          throw failedPrecondition('The descendant hierarchy is incomplete.');
        }
        const projection = buildOrganizationUnitProjection({
          unitId: descendant.id,
          organization,
          input: {
            organizationId,
            type: descendant.type,
            code: descendant.code,
            name: descendant.name,
            description: descendant.description,
            parentUnitId: projectedParent.id,
          },
          parent: projectedParent,
        });
        projectedUnits.set(descendant.id, { ...descendant, ...projection });
      }

      const affectedAgentWrites = [];
      for (const recipient of recipientsSnapshot.docs) {
        const agentId = recipient.id;
        const agentRef = db.collection('agents').doc(agentId);
        const agentSnapshot = await transaction.get(agentRef);
        if (!agentSnapshot.exists) {
          throw failedPrecondition('An affected agent profile is missing.');
        }
        const agent = agentSnapshot.data() || {};
        const assignedUnitId = requiredId(
          agent.primaryOrganizationUnitId,
          'assigned unit',
        );
        const assignedUnit = projectedUnits.get(assignedUnitId);
        if (!assignedUnit) {
          throw failedPrecondition(
            'An affected agent has an inconsistent current placement.',
          );
        }
        const pathUnits = await readProjectedUnitPath({
          transaction,
          db,
          unit: assignedUnit,
          projectedUnits,
        });
        const placement = buildAgentOrganizationProjection({
          organization,
          unit: assignedUnit,
          pathUnits,
          assignmentId: requiredId(agent.primaryAssignmentId, 'assignment'),
        });
        affectedAgentWrites.push({
          agentId,
          agent,
          placement,
        });
      }

      // Firestore transactions require every read to complete before the first
      // write is queued, so projection writes start only after all agent paths
      // have been resolved.
      for (const [projectedId, projected] of projectedUnits) {
        transaction.update(
          db.collection('organizationUnits').doc(projectedId),
          {
            parentUnitId: projected.parentUnitId,
            parentUnitType: projected.parentUnitType,
            ancestorUnitIds: projected.ancestorUnitIds,
            pathUnitIds: projected.pathUnitIds,
            pathNames: projected.pathNames,
            depth: projected.depth,
            scopeKeys: projected.scopeKeys,
            updatedAt: context.now,
            updatedBy: actorUid,
          },
        );
      }
      for (const affectedAgent of affectedAgentWrites) {
        writeAgentProjections({
          transaction,
          db,
          ...affectedAgent,
          now: context.now,
        });
      }

      context.setOrganizationId(organizationId);
      context.audit({
        eventType: 'ORGANIZATION_UNIT_MOVED',
        organizationId,
        unitId,
        reason,
        before: {
          parentUnitId: normalizeString(current.parentUnitId) || null,
          pathUnitIds: array(current.pathUnitIds),
        },
        after: {
          parentUnitId,
          pathUnitIds: rootProjection.pathUnitIds,
        },
      });
      return {
        organizationUnitId: unitId,
        descendantCount: descendants.length,
        affectedAgentCount: recipientsSnapshot.size,
      };
    },
  });
}

async function archiveOrganizationUnit({ db, fieldValue, payload, actorUid }) {
  const unitId = requiredId(payload.organizationUnitId || payload.unitId, 'unit');
  const reason = requiredReason(payload.reason);
  const unitRef = db.collection('organizationUnits').doc(unitId);
  return runCommandTransaction({
    db,
    fieldValue,
    payload,
    actorUid,
    command: ORGANIZATION_COMMANDS.archiveOrganizationUnit,
    organizationId: normalizeString(payload.organizationId),
    work: async (transaction, context) => {
      const snapshot = await transaction.get(unitRef);
      if (!snapshot.exists) throw notFound('Organization unit');
      const current = snapshot.data() || {};
      const organizationId = normalizeString(current.organizationId);
      const [children, assignments] = await Promise.all([
        transaction.get(db.collection('organizationUnits')
          .where('organizationId', '==', organizationId)
          .where('parentUnitId', '==', unitId)
          .where('status', '==', 'ACTIVE')
          .limit(1)),
        transaction.get(db.collection('organizationAssignments')
          .where('unitId', '==', unitId)
          .where('status', '==', 'ACTIVE')
          .limit(1)),
      ]);
      if (!children.empty || !assignments.empty) {
        throw failedPrecondition(
          'Move or end all active child units, members, and leadership first.',
        );
      }
      transaction.update(unitRef, {
        status: 'ARCHIVED',
        archivedAt: context.now,
        archivedBy: actorUid,
        updatedAt: context.now,
        updatedBy: actorUid,
      });
      context.setOrganizationId(organizationId);
      context.audit({
        eventType: 'ORGANIZATION_UNIT_ARCHIVED',
        organizationId,
        unitId,
        reason,
        before: unitSummary(current),
        after: { status: 'ARCHIVED' },
      });
      return { organizationUnitId: unitId };
    },
  });
}

async function assignAgentOrganization({
  db,
  fieldValue,
  timestamp,
  payload,
  actorUid,
  isTransfer,
}) {
  const agentId = requiredId(payload.agentId, 'agent');
  const unitId = requiredId(payload.organizationUnitId || payload.unitId, 'unit');
  const organizationId = requiredId(payload.organizationId, 'organization');
  const reason = requiredReason(payload.reason);
  const assignAsHead = payload.assignAsHead === true;
  const startsAt = parseTimestamp(payload.startsAt, timestamp);
  assertNotFuture(startsAt, timestamp.now(), 'The assignment effective date');
  const assignmentRef = db.collection('organizationAssignments').doc();
  const leadershipAssignmentRef = assignAsHead
    ? db.collection('organizationAssignments').doc()
    : null;
  const agentRef = db.collection('agents').doc(agentId);
  const organizationRef = db.collection('organizations').doc(organizationId);
  const unitRef = db.collection('organizationUnits').doc(unitId);
  return runCommandTransaction({
    db,
    fieldValue,
    payload,
    actorUid,
    command: isTransfer
      ? ORGANIZATION_COMMANDS.transferAgentOrganization
      : ORGANIZATION_COMMANDS.assignAgentOrganization,
    organizationId,
    work: async (transaction, context) => {
      const [agentSnapshot, organizationSnapshot, unitSnapshot] = await Promise.all([
        transaction.get(agentRef),
        transaction.get(organizationRef),
        transaction.get(unitRef),
      ]);
      if (!agentSnapshot.exists) throw notFound('Agent');
      if (!organizationSnapshot.exists) throw notFound('Organization');
      if (!unitSnapshot.exists) throw notFound('Organization unit');
      const agent = agentSnapshot.data() || {};
      if (agent.isActive !== true) {
        throw failedPrecondition('An inactive agent cannot receive an assignment.');
      }
      const currentAssignmentId = normalizeString(agent.primaryAssignmentId);
      if (isTransfer && !currentAssignmentId) {
        throw failedPrecondition('The agent has no current assignment to transfer.');
      }
      if (!isTransfer && currentAssignmentId) {
        throw failedPrecondition('Use the transfer action for an assigned agent.');
      }
      const unit = { id: unitSnapshot.id, ...(unitSnapshot.data() || {}) };
      if (
        normalizeString(unit.organizationId) !== organizationId ||
        normalizeStatus(unit.status) !== 'ACTIVE'
      ) {
        throw failedPrecondition('The selected organization unit is not active.');
      }
      if (assignAsHead && normalizeString(unit.headAssignmentId)) {
        throw failedPrecondition(
          'The selected organization unit already has a permanent head.',
        );
      }
      const pathUnits = await readUnitPath(transaction, db, unit);
      const placement = buildAgentOrganizationProjection({
        organization: {
          id: organizationSnapshot.id,
          ...(organizationSnapshot.data() || {}),
        },
        unit,
        pathUnits,
        assignmentId: assignmentRef.id,
      });
      const assignment = buildAssignmentDocument({
        assignmentId: assignmentRef.id,
        agentId,
        unit,
        startsAt,
        reason,
        actorUid,
      });
      let currentAssignmentRef = null;
      let currentAssignmentData = null;
      if (currentAssignmentId) {
        currentAssignmentRef = db.collection('organizationAssignments')
          .doc(currentAssignmentId);
        const currentAssignment = await transaction.get(currentAssignmentRef);
        currentAssignmentData = currentAssignment.exists
          ? currentAssignment.data() || {}
          : {};
        if (!currentAssignment.exists ||
          normalizeString(currentAssignmentData.status) !== 'ACTIVE') {
          throw failedPrecondition('The current assignment projection is stale.');
        }
        if (
          normalizeString(currentAssignmentData.agentId) !== agentId ||
          normalizeString(currentAssignmentData.organizationId) !==
            normalizeString(agent.organizationId) ||
          normalizeString(currentAssignmentData.assignmentType) !== 'MEMBER' ||
          currentAssignmentData.isPrimary !== true
        ) {
          throw failedPrecondition(
            'The current assignment projection does not belong to this agent.',
          );
        }
        assertNotBefore(
          startsAt,
          currentAssignmentData.startsAt,
          'A transfer cannot take effect before the current assignment began.',
        );
      }

      const activeLeadership = isTransfer
        ? await transaction.get(
          db.collection('organizationAssignments')
            .where('organizationId', '==', organizationId)
            .where('agentId', '==', agentId)
            .where('assignmentType', '==', 'HEAD')
            .where('status', '==', 'ACTIVE')
            .limit(21),
        )
        : { docs: [], size: 0 };
      if (activeLeadership.size > 20) {
        throw failedPrecondition(
          'The agent has too many active leadership assignments to transfer safely.',
        );
      }
      const leadershipToEnd = [];
      for (const leadershipSnapshot of activeLeadership.docs) {
        const leadership = leadershipSnapshot.data() || {};
        assertNotBefore(
          startsAt,
          leadership.startsAt,
          'A transfer cannot take effect before a leadership assignment began.',
        );
        const leadershipUnitId = requiredId(leadership.unitId, 'leadership unit');
        const leadershipUnitRef = db.collection('organizationUnits')
          .doc(leadershipUnitId);
        const leadershipUnitSnapshot = await transaction.get(leadershipUnitRef);
        if (!leadershipUnitSnapshot.exists) {
          throw failedPrecondition('A current leadership unit no longer exists.');
        }
        const leadershipUnit = leadershipUnitSnapshot.data() || {};
        const projectedAssignmentId = normalizeString(
          leadership.isActing === true
            ? leadershipUnit.actingHeadAssignmentId
            : leadershipUnit.headAssignmentId,
        );
        if (projectedAssignmentId !== leadershipSnapshot.id) {
          throw failedPrecondition('A current leadership projection is stale.');
        }
        leadershipToEnd.push({
          assignmentRef: leadershipSnapshot.ref,
          assignmentId: leadershipSnapshot.id,
          isActing: leadership.isActing === true,
          unitRef: leadershipUnitRef,
        });
      }

      if (currentAssignmentRef) {
        transaction.update(currentAssignmentRef, {
          status: 'ENDED',
          endsAt: startsAt,
          endedAt: context.now,
          endedBy: actorUid,
          updatedAt: context.now,
          updatedBy: actorUid,
        });
      }
      for (const leadership of leadershipToEnd) {
        transaction.update(leadership.assignmentRef, {
          status: 'ENDED',
          endsAt: startsAt,
          endedAt: context.now,
          endedBy: actorUid,
          updatedAt: context.now,
          updatedBy: actorUid,
        });
        transaction.update(leadership.unitRef, leadership.isActing ? {
          actingHeadUserId: null,
          actingHeadAssignmentId: null,
          actingHeadEndsAt: null,
          updatedAt: context.now,
          updatedBy: actorUid,
        } : {
          headUserId: null,
          headAssignmentId: null,
          updatedAt: context.now,
          updatedBy: actorUid,
        });
      }
      transaction.create(assignmentRef, {
        ...assignment,
        createdAt: context.now,
        updatedAt: context.now,
        endedAt: null,
        endedBy: null,
      });
      if (leadershipAssignmentRef) {
        const leadershipAssignment = buildAssignmentDocument({
          assignmentId: leadershipAssignmentRef.id,
          agentId,
          unit,
          assignmentType: 'HEAD',
          isPrimary: false,
          isActing: false,
          startsAt,
          endsAt: null,
          reason,
          actorUid,
        });
        transaction.create(leadershipAssignmentRef, {
          ...leadershipAssignment,
          createdAt: context.now,
          updatedAt: context.now,
          endedAt: null,
          endedBy: null,
        });
        transaction.update(unitRef, {
          headUserId: agentId,
          headAssignmentId: leadershipAssignmentRef.id,
          updatedAt: context.now,
          updatedBy: actorUid,
        });
      }
      writeAgentProjections({
        transaction,
        db,
        fieldValue,
        agentId,
        agent,
        placement,
        now: context.now,
      });
      context.audit({
        eventType: currentAssignmentId
          ? 'AGENT_ORGANIZATION_TRANSFERRED'
          : 'AGENT_ORGANIZATION_ASSIGNED',
        organizationId,
        unitId,
        agentId,
        assignmentId: assignmentRef.id,
        reason,
        before: {
          primaryAssignmentId: currentAssignmentId || null,
          primaryOrganizationUnitId:
            normalizeString(agent.primaryOrganizationUnitId) || null,
        },
        after: {
          primaryAssignmentId: assignmentRef.id,
          primaryOrganizationUnitId: unitId,
          headAssignmentId: leadershipAssignmentRef?.id || null,
          endedLeadershipAssignmentIds:
            leadershipToEnd.map((leadership) => leadership.assignmentId),
        },
      });
      return {
        agentId,
        assignmentId: assignmentRef.id,
        leadershipAssignmentId: leadershipAssignmentRef?.id || null,
      };
    },
  });
}

async function setOrganizationUnitHead({
  db,
  fieldValue,
  timestamp,
  payload,
  actorUid,
}) {
  const agentId = requiredId(payload.agentId, 'agent');
  const unitId = requiredId(payload.organizationUnitId || payload.unitId, 'unit');
  const reason = requiredReason(payload.reason);
  const isActing = payload.isActing === true;
  const startsAt = parseTimestamp(payload.startsAt, timestamp);
  const endsAt = isActing ? parseTimestamp(payload.endsAt, timestamp) : null;
  const currentTime = timestamp.now();
  assertNotFuture(startsAt, currentTime, 'The leadership effective date');
  if (isActing) {
    assertAfter(
      endsAt,
      currentTime,
      'An acting leadership period must end in the future.',
    );
  }
  const assignmentRef = db.collection('organizationAssignments').doc();
  const unitRef = db.collection('organizationUnits').doc(unitId);
  const agentRef = db.collection('agents').doc(agentId);
  return runCommandTransaction({
    db,
    fieldValue,
    payload,
    actorUid,
    command: ORGANIZATION_COMMANDS.setOrganizationUnitHead,
    organizationId: normalizeString(payload.organizationId),
    work: async (transaction, context) => {
      const [unitSnapshot, agentSnapshot] = await Promise.all([
        transaction.get(unitRef),
        transaction.get(agentRef),
      ]);
      if (!unitSnapshot.exists) throw notFound('Organization unit');
      if (!agentSnapshot.exists) throw notFound('Agent');
      const unit = { id: unitSnapshot.id, ...(unitSnapshot.data() || {}) };
      const agent = agentSnapshot.data() || {};
      const organizationId = normalizeString(unit.organizationId);
      if (normalizeStatus(unit.status) !== 'ACTIVE' || agent.isActive !== true) {
        throw failedPrecondition('The unit and selected agent must be active.');
      }
      if (normalizeString(agent.organizationId) !== organizationId ||
        !array(agent.scopeKeys).includes(`unit:${unitId}`)) {
        throw failedPrecondition(
          'A unit head must belong to the unit or one of its descendants.',
        );
      }
      const existingProjectionId = normalizeString(
        isActing ? unit.actingHeadAssignmentId : unit.headAssignmentId,
      );
      if (existingProjectionId) {
        throw failedPrecondition(
          isActing
            ? 'This unit already has an acting head.'
            : 'This unit already has a permanent head.',
        );
      }
      const assignment = buildAssignmentDocument({
        assignmentId: assignmentRef.id,
        agentId,
        unit,
        assignmentType: 'HEAD',
        isPrimary: false,
        isActing,
        startsAt,
        endsAt,
        reason,
        actorUid,
      });
      transaction.create(assignmentRef, {
        ...assignment,
        createdAt: context.now,
        updatedAt: context.now,
        endedAt: null,
        endedBy: null,
      });
      transaction.update(unitRef, isActing ? {
        actingHeadUserId: agentId,
        actingHeadAssignmentId: assignmentRef.id,
        actingHeadEndsAt: endsAt,
        updatedAt: context.now,
        updatedBy: actorUid,
      } : {
        headUserId: agentId,
        headAssignmentId: assignmentRef.id,
        updatedAt: context.now,
        updatedBy: actorUid,
      });
      context.setOrganizationId(organizationId);
      context.audit({
        eventType: isActing
          ? 'ORGANIZATION_UNIT_ACTING_HEAD_ASSIGNED'
          : 'ORGANIZATION_UNIT_HEAD_ASSIGNED',
        organizationId,
        unitId,
        agentId,
        assignmentId: assignmentRef.id,
        reason,
        after: { isActing, startsAt, endsAt },
      });
      return { assignmentId: assignmentRef.id, unitId, agentId };
    },
  });
}

async function endOrganizationUnitHead({ db, fieldValue, payload, actorUid }) {
  const assignmentId = requiredId(payload.assignmentId, 'leadership assignment');
  const reason = requiredReason(payload.reason);
  const assignmentRef = db.collection('organizationAssignments').doc(assignmentId);
  return runCommandTransaction({
    db,
    fieldValue,
    payload,
    actorUid,
    command: ORGANIZATION_COMMANDS.endOrganizationUnitHead,
    organizationId: normalizeString(payload.organizationId),
    work: async (transaction, context) => {
      const assignmentSnapshot = await transaction.get(assignmentRef);
      if (!assignmentSnapshot.exists) throw notFound('Leadership assignment');
      const assignment = assignmentSnapshot.data() || {};
      if (normalizeString(assignment.assignmentType) !== 'HEAD' ||
        normalizeString(assignment.status) !== 'ACTIVE') {
        throw failedPrecondition('The leadership assignment is not active.');
      }
      const unitId = requiredId(assignment.unitId, 'unit');
      const unitRef = db.collection('organizationUnits').doc(unitId);
      const unitSnapshot = await transaction.get(unitRef);
      if (!unitSnapshot.exists) throw notFound('Organization unit');
      const isActing = assignment.isActing === true;
      const projectionField = isActing
        ? 'actingHeadAssignmentId'
        : 'headAssignmentId';
      if (normalizeString(unitSnapshot.get(projectionField)) !== assignmentId) {
        throw failedPrecondition(
          'This leadership assignment is no longer the active unit projection.',
        );
      }
      transaction.update(assignmentRef, {
        status: 'ENDED',
        endsAt: context.now,
        endedAt: context.now,
        endedBy: actorUid,
        updatedAt: context.now,
        updatedBy: actorUid,
      });
      transaction.update(unitRef, isActing ? {
        actingHeadUserId: null,
        actingHeadAssignmentId: null,
        actingHeadEndsAt: null,
        updatedAt: context.now,
        updatedBy: actorUid,
      } : {
        headUserId: null,
        headAssignmentId: null,
        updatedAt: context.now,
        updatedBy: actorUid,
      });
      const organizationId = normalizeString(assignment.organizationId);
      context.setOrganizationId(organizationId);
      context.audit({
        eventType: isActing
          ? 'ORGANIZATION_UNIT_ACTING_HEAD_ENDED'
          : 'ORGANIZATION_UNIT_HEAD_ENDED',
        organizationId,
        unitId,
        agentId: normalizeString(assignment.agentId),
        assignmentId,
        reason,
      });
      return { assignmentId, unitId };
    },
  });
}

async function deactivateAgentAccount({
  db,
  fieldValue,
  timestamp,
  payload,
  actorUid,
}) {
  const agentId = requiredId(payload.agentId || payload.uid, 'agent');
  const reason = requiredReason(payload.reason);
  const effectiveAt = parseTimestamp(payload.effectiveAt, timestamp);
  assertNotFuture(effectiveAt, timestamp.now(), 'The deactivation effective date');
  const agentRef = db.collection('agents').doc(agentId);
  return runCommandTransaction({
    db,
    fieldValue,
    payload,
    actorUid,
    command: ORGANIZATION_COMMANDS.deactivateAgentAccount,
    organizationId: normalizeString(payload.organizationId),
    work: async (transaction, context) => {
      const agentSnapshot = await transaction.get(agentRef);
      if (!agentSnapshot.exists) throw notFound('Agent');
      const agent = agentSnapshot.data() || {};
      if (agent.isActive !== true) {
        const organizationId = normalizeString(agent.organizationId);
        context.setOrganizationId(organizationId);
        context.audit({
          eventType: 'AGENT_DEACTIVATION_REPLAYED',
          organizationId,
          agentId,
          reason,
          before: { isActive: false },
          after: { isActive: false },
        });
        return { agentId, alreadyInactive: true };
      }
      const assignments = await transaction.get(
        db.collection('organizationAssignments')
          .where('agentId', '==', agentId)
          .where('status', '==', 'ACTIVE')
          .limit(101),
      );
      if (assignments.size > 100) {
        throw failedPrecondition(
          'The agent has too many active assignments for a safe deactivation.',
        );
      }
      for (const assignmentSnapshot of assignments.docs) {
        const assignment = assignmentSnapshot.data() || {};
        assertNotBefore(
          effectiveAt,
          assignment.startsAt,
          'Deactivation cannot precede an active assignment.',
        );
        transaction.update(assignmentSnapshot.ref, {
          status: 'ENDED',
          endsAt: effectiveAt,
          endedAt: context.now,
          endedBy: actorUid,
          updatedAt: context.now,
          updatedBy: actorUid,
        });
        if (normalizeString(assignment.assignmentType) === 'HEAD') {
          const unitRef = db.collection('organizationUnits')
            .doc(normalizeString(assignment.unitId));
          transaction.update(unitRef, assignment.isActing === true ? {
            actingHeadUserId: null,
            actingHeadAssignmentId: null,
            actingHeadEndsAt: null,
            updatedAt: context.now,
            updatedBy: actorUid,
          } : {
            headUserId: null,
            headAssignmentId: null,
            updatedAt: context.now,
            updatedBy: actorUid,
          });
        }
      }
      transaction.update(agentRef, {
        isActive: false,
        primaryAssignmentId: '',
        updatedAt: context.now,
      });
      transaction.set(db.collection('agentDirectory').doc(agentId), {
        isActive: false,
        updatedAt: context.now,
      }, { merge: true });
      transaction.set(db.collection('agentAuthorizationIndex').doc(agentId), {
        isActive: false,
        updatedAt: context.now,
      }, { merge: true });
      const organizationId = normalizeString(agent.organizationId);
      context.setOrganizationId(organizationId);
      context.audit({
        eventType: 'AGENT_DEACTIVATED',
        organizationId,
        agentId,
        reason,
        before: { isActive: true },
        after: { isActive: false, effectiveAt },
      });
      return { agentId, endedAssignmentCount: assignments.size };
    },
  });
}

async function createInitialAgentPlacement({
  db,
  fieldValue,
  timestamp,
  agentId,
  agent,
  organizationId,
  unitId,
  startsAt,
  reason,
  assignAsHead = false,
  actorUid,
  commandId,
  commandPayload,
}) {
  const effectiveStartsAt = parseTimestamp(startsAt, timestamp);
  assertNotFuture(
    effectiveStartsAt,
    timestamp.now(),
    'The initial assignment effective date',
  );
  const assignmentRef = db.collection('organizationAssignments').doc();
  const leadershipAssignmentRef = assignAsHead
    ? db.collection('organizationAssignments').doc()
    : null;
  const receiptRef = db.collection('organizationCommandReceipts')
    .doc(requiredId(commandId, 'command'));
  const command = 'createAgentAccount';
  const digest = payloadDigest(commandPayload);
  const organizationRef = db.collection('organizations').doc(organizationId);
  const unitRef = db.collection('organizationUnits').doc(unitId);
  return db.runTransaction(async (transaction) => {
    const [receiptSnapshot, organizationSnapshot, unitSnapshot] =
      await Promise.all([
        transaction.get(receiptRef),
      transaction.get(organizationRef),
      transaction.get(unitRef),
      ]);
    if (receiptSnapshot.exists) {
      return replayOrganizationCommandReceipt({
        receiptSnapshot,
        command,
        actorUid,
        digest,
      });
    }
    if (!organizationSnapshot.exists) throw notFound('Organization');
    if (!unitSnapshot.exists) throw notFound('Organization unit');
    const unit = { id: unitSnapshot.id, ...(unitSnapshot.data() || {}) };
    if (normalizeString(unit.organizationId) !== organizationId) {
      throw failedPrecondition('The selected unit belongs to another organization.');
    }
    if (normalizeStatus(unit.status) !== 'ACTIVE') {
      throw failedPrecondition('The selected organization unit is not active.');
    }
    if (assignAsHead && normalizeString(unit.headAssignmentId)) {
      throw failedPrecondition(
        'The selected organization unit already has a permanent head.',
      );
    }
    const pathUnits = await readUnitPath(transaction, db, unit);
    const placement = buildAgentOrganizationProjection({
      organization: {
        id: organizationSnapshot.id,
        ...(organizationSnapshot.data() || {}),
      },
      unit,
      pathUnits,
      assignmentId: assignmentRef.id,
    });
    const assignment = buildAssignmentDocument({
      assignmentId: assignmentRef.id,
      agentId,
      unit,
      startsAt: effectiveStartsAt,
      reason: reason || 'Initial organization placement',
      actorUid,
    });
    const now = fieldValue.serverTimestamp();
    transaction.create(db.collection('agents').doc(agentId), {
      ...agent,
      ...placement,
      createdAt: now,
      updatedAt: now,
    });
    transaction.create(assignmentRef, {
      ...assignment,
      createdAt: now,
      updatedAt: now,
      endedAt: null,
      endedBy: null,
    });
    if (leadershipAssignmentRef) {
      const leadershipAssignment = buildAssignmentDocument({
        assignmentId: leadershipAssignmentRef.id,
        agentId,
        unit,
        assignmentType: 'HEAD',
        isPrimary: false,
        isActing: false,
        startsAt: effectiveStartsAt,
        endsAt: null,
        reason: reason || 'Initial organization placement',
        actorUid,
      });
      transaction.create(leadershipAssignmentRef, {
        ...leadershipAssignment,
        createdAt: now,
        updatedAt: now,
        endedAt: null,
        endedBy: null,
      });
      transaction.update(unitRef, {
        headUserId: agentId,
        headAssignmentId: leadershipAssignmentRef.id,
        updatedAt: now,
        updatedBy: actorUid,
      });
    }
    writeAgentProjections({
      transaction,
      db,
      fieldValue,
      agentId,
      agent,
      placement,
      now,
      writePrivateAgent: false,
    });
    const auditRef = db.collection('organizationAuditEvents').doc();
    transaction.create(auditRef, {
      eventType: 'AGENT_CREATED_AND_ASSIGNED',
      actorUid,
      organizationId,
      unitId,
      agentId,
      assignmentId: assignmentRef.id,
      leadershipAssignmentId: leadershipAssignmentRef?.id || null,
      reason: assignment.reason,
      command,
      commandId,
      createdAt: now,
      schemaVersion: 2,
    });
    const result = {
      uid: agentId,
      assignmentId: assignmentRef.id,
      leadershipAssignmentId: leadershipAssignmentRef?.id || null,
      placement,
    };
    transaction.create(receiptRef, {
      command,
      actorUid,
      organizationId,
      result,
      payloadDigest: digest,
      createdAt: now,
    });
    return { ...result, replayed: false };
  });
}

async function refreshAgentProjections({
  db,
  fieldValue,
  agentId,
  updates,
  actorUid,
  commandId,
  commandPayload,
}) {
  const agentRef = db.collection('agents').doc(agentId);
  const command = 'updateAgentAccount';
  const digest = payloadDigest(commandPayload);
  const receiptRef = db.collection('organizationCommandReceipts')
    .doc(requiredId(commandId, 'command'));
  return db.runTransaction(async (transaction) => {
    const [receiptSnapshot, snapshot] = await Promise.all([
      transaction.get(receiptRef),
      transaction.get(agentRef),
    ]);
    if (receiptSnapshot.exists) {
      return replayOrganizationCommandReceipt({
        receiptSnapshot,
        command,
        actorUid,
        digest,
      });
    }
    if (!snapshot.exists) throw notFound('Agent');
    const current = snapshot.data() || {};
    const agent = { ...current, ...updates };
    const placement = organizationPlacementProjection(current);
    const now = fieldValue.serverTimestamp();
    transaction.set(agentRef, { ...updates, updatedAt: now }, { merge: true });
    writeAgentProjections({
      transaction,
      db,
      fieldValue,
      agentId,
      agent,
      placement,
      now,
    });
    const auditRef = db.collection('organizationAuditEvents').doc();
    const result = { uid: agentId, agentId };
    transaction.create(auditRef, {
      eventType: 'AGENT_PROFILE_UPDATED',
      actorUid,
      organizationId: normalizeString(current.organizationId),
      agentId,
      command,
      commandId,
      before: agentProfileAuditSummary(current),
      after: agentProfileAuditSummary(agent),
      createdAt: now,
      schemaVersion: 2,
    });
    transaction.create(receiptRef, {
      command,
      actorUid,
      organizationId: normalizeString(current.organizationId),
      result,
      payloadDigest: digest,
      createdAt: now,
    });
    return { ...result, replayed: false };
  });
}

async function readOrganizationCommandReceipt({
  db,
  commandId,
  command,
  actorUid,
  payload,
}) {
  const normalizedCommandId = requiredId(commandId, 'command');
  const snapshot = await db.collection('organizationCommandReceipts')
    .doc(normalizedCommandId).get();
  if (!snapshot.exists) return null;
  return replayOrganizationCommandReceipt({
    receiptSnapshot: snapshot,
    command,
    actorUid,
    digest: payloadDigest(payload),
  });
}

function replayOrganizationCommandReceipt({
  receiptSnapshot,
  command,
  actorUid,
  digest,
}) {
  const receipt = receiptSnapshot.data() || {};
  if (
    normalizeString(receipt.command) !== command ||
    normalizeString(receipt.actorUid) !== normalizeString(actorUid) ||
    normalizeString(receipt.payloadDigest) !== digest
  ) {
    throw failedPrecondition(
      'This command ID was already used for a different operation.',
    );
  }
  return { ...(receipt.result || {}), replayed: true };
}

function agentProfileAuditSummary(agent) {
  return {
    firstName: normalizeString(agent.firstName),
    name: normalizeString(agent.name),
    postName: normalizeString(agent.postName),
    sex: normalizeString(agent.sex).toLowerCase() || null,
    email: normalizeString(agent.email).toLowerCase(),
    jobTitle: normalizeString(agent.jobTitle),
    isActive: agent.isActive === true,
    modulePermissions: agent.modulePermissions || {},
  };
}

async function auditOrganizationArchitecture({
  db,
  fieldValue,
  timestamp,
  payload,
  actorUid,
}) {
  const organizationId = requiredId(payload.organizationId, 'organization');
  const pageSize = boundedLimit(payload.limit, 100);
  const repair = payload.repair === true || payload.dryRun === false;
  if (repair) {
    if (!fieldValue || !timestamp || !normalizeString(actorUid)) {
      throw new OrganizationDomainError(
        'failed-precondition',
        'Repair mode requires an authenticated organization command.',
      );
    }
    const replay = await readOrganizationCommandReceipt({
      db,
      commandId: payload.commandId,
      command: ORGANIZATION_COMMANDS.auditOrganizationArchitecture,
      actorUid,
      payload,
    });
    if (replay) return replay;
  }
  const state = await readOrganizationArchitectureState({
    db,
    organizationId,
    pageSize,
  });
  const report = buildOrganizationArchitectureReport({
    organizationId,
    pageSize,
    currentTime: timestamp ? timestamp.now() : new Date(),
    ...state,
  });
  if (!repair) return report;
  if (report.truncated) {
    throw failedPrecondition(
      'Repair is unavailable while the bounded architecture audit is truncated.',
    );
  }
  const reason = requiredReason(payload.reason);
  const repairedAgentIds = [];
  const skippedAgentIds = [];
  await repairOrganizationDirectoryProjection({
    db,
    fieldValue,
    organizationId,
  });
  for (const agentDocument of state.agents.docs) {
    const primaryAssignments = state.primaryAssignmentsByAgent
      .get(agentDocument.id) || [];
    if (primaryAssignments.length !== 1) {
      skippedAgentIds.push(agentDocument.id);
      continue;
    }
    try {
      await repairAgentOrganizationProjections({
        db,
        fieldValue,
        agentId: agentDocument.id,
        organizationId,
        assignmentId: primaryAssignments[0].id,
      });
      repairedAgentIds.push(agentDocument.id);
    } catch (error) {
      if (!(error instanceof OrganizationDomainError)) throw error;
      skippedAgentIds.push(agentDocument.id);
    }
  }

  const repairedState = await readOrganizationArchitectureState({
    db,
    organizationId,
    pageSize,
  });
  const repairedReport = buildOrganizationArchitectureReport({
    organizationId,
    pageSize,
    currentTime: timestamp.now(),
    ...repairedState,
  });
  const result = {
    ...repairedReport,
    dryRun: false,
    repairedCount: repairedAgentIds.length,
    repairedAgentIds,
    skippedAgentIds,
  };
  return runCommandTransaction({
    db,
    fieldValue,
    payload,
    actorUid,
    command: ORGANIZATION_COMMANDS.auditOrganizationArchitecture,
    organizationId,
    work: async (_transaction, context) => {
      context.audit({
        eventType: 'ORGANIZATION_ARCHITECTURE_PROJECTIONS_REPAIRED',
        organizationId,
        reason,
        before: { issueCount: report.issueCount },
        after: {
          issueCount: repairedReport.issueCount,
          repairedCount: repairedAgentIds.length,
          skippedCount: skippedAgentIds.length,
        },
      });
      return result;
    },
  });
}

async function readOrganizationArchitectureState({
  db,
  organizationId,
  pageSize,
}) {
  const organization = await db.collection('organizations').doc(organizationId).get();
  if (!organization.exists) throw notFound('Organization');
  const organizationDirectory = await db.collection('organizationDirectory')
    .doc(organizationId).get();
  const [units, assignments, agents, directory, authorization] = await Promise.all([
    readQueryPages(db.collection('organizationUnits')
      .where('organizationId', '==', organizationId), pageSize),
    readQueryPages(db.collection('organizationAssignments')
      .where('organizationId', '==', organizationId)
      .where('status', '==', 'ACTIVE'), pageSize),
    readQueryPages(db.collection('agents')
      .where('organizationId', '==', organizationId), pageSize),
    readQueryPages(db.collection('agentDirectory')
      .where('organizationId', '==', organizationId), pageSize),
    readQueryPages(db.collection('agentAuthorizationIndex')
      .where('organizationId', '==', organizationId), pageSize),
  ]);
  const primaryAssignmentsByAgent = new Map();
  for (const assignmentDocument of assignments.docs) {
    const assignment = assignmentDocument.data() || {};
    if (assignment.isPrimary === true && assignment.assignmentType === 'MEMBER') {
      const agentId = normalizeString(assignment.agentId);
      const current = primaryAssignmentsByAgent.get(agentId) || [];
      current.push(assignmentDocument);
      primaryAssignmentsByAgent.set(agentId, current);
    }
  }
  return {
    organization,
    organizationDirectory,
    units,
    assignments,
    agents,
    directory,
    authorization,
    primaryAssignmentsByAgent,
  };
}

function buildOrganizationArchitectureReport({
  organizationId,
  pageSize,
  currentTime,
  organization,
  organizationDirectory,
  units,
  assignments,
  agents,
  directory,
  authorization,
  primaryAssignmentsByAgent,
}) {
  const unitsById = new Map(units.docs.map((doc) => [doc.id, doc.data() || {}]));
  const assignmentsById = new Map(
    assignments.docs.map((doc) => [doc.id, doc.data() || {}]),
  );
  const agentsById = new Map(agents.docs.map((doc) => [doc.id, doc.data() || {}]));
  const directoryById = new Map(
    directory.docs.map((doc) => [doc.id, doc.data() || {}]),
  );
  const authorizationById = new Map(
    authorization.docs.map((doc) => [doc.id, doc.data() || {}]),
  );
  const activePrimaryByAgent = new Map();
  const activePermanentHeadsByUnit = new Map();
  const activeActingHeadsByUnit = new Map();
  const issues = [];
  const expectedOrganizationDirectory = {
    name: normalizeString(organization.get('name')),
    nameLower: normalizeString(organization.get('nameLower')),
    status: normalizeStatus(organization.get('status')),
  };
  if (!organizationDirectory.exists) {
    issues.push({
      type: 'MISSING_ORGANIZATION_DIRECTORY_PROJECTION',
      organizationId,
    });
  } else if (!projectionMatches(
    organizationDirectory.data() || {},
    expectedOrganizationDirectory,
    ['name', 'nameLower', 'status'],
  )) {
    issues.push({
      type: 'ORGANIZATION_DIRECTORY_PROJECTION_DRIFT',
      organizationId,
    });
  }
  for (const assignmentDoc of assignments.docs) {
    const assignment = assignmentDoc.data() || {};
    if (assignment.isPrimary === true && assignment.assignmentType === 'MEMBER') {
      pushDuplicate(activePrimaryByAgent, assignment.agentId, assignmentDoc.id, issues,
        'DUPLICATE_PRIMARY_ASSIGNMENT');
    }
    if (assignment.assignmentType === 'HEAD' && assignment.isActing !== true) {
      pushDuplicate(activePermanentHeadsByUnit, assignment.unitId, assignmentDoc.id,
        issues, 'DUPLICATE_PERMANENT_HEAD');
    }
    if (assignment.assignmentType === 'HEAD' && assignment.isActing === true) {
      pushDuplicate(activeActingHeadsByUnit, assignment.unitId, assignmentDoc.id,
        issues, 'DUPLICATE_ACTING_HEAD');
      if (assignment.endsAt &&
        timestampMilliseconds(assignment.endsAt) <= timestampMilliseconds(currentTime)) {
        issues.push({
          type: 'EXPIRED_ACTING_HEAD_ASSIGNMENT',
          unitId: normalizeString(assignment.unitId),
          assignmentIds: [assignmentDoc.id],
        });
      }
    }
    if (assignment.assignmentType === 'HEAD') {
      const unit = unitsById.get(normalizeString(assignment.unitId));
      const projectionField = assignment.isActing === true
        ? 'actingHeadAssignmentId'
        : 'headAssignmentId';
      if (!unit || normalizeString(unit[projectionField]) !== assignmentDoc.id) {
        issues.push({
          type: assignment.isActing === true
            ? 'UNPROJECTED_ACTING_HEAD_ASSIGNMENT'
            : 'UNPROJECTED_PERMANENT_HEAD_ASSIGNMENT',
          unitId: normalizeString(assignment.unitId),
          assignmentIds: [assignmentDoc.id],
        });
      }
    }
  }
  for (const unitDoc of units.docs) {
    const unit = unitDoc.data() || {};
    if (!isValidUnitProjection({
      unitId: unitDoc.id,
      unit,
      organizationId,
      unitsById,
    })) {
      issues.push({ type: 'INVALID_UNIT_PATH', unitId: unitDoc.id });
    }
    validateUnitHeadProjection({
      unitId: unitDoc.id,
      unit,
      assignmentsById,
      issues,
      acting: false,
    });
    validateUnitHeadProjection({
      unitId: unitDoc.id,
      unit,
      assignmentsById,
      issues,
      acting: true,
    });
  }
  for (const agentDoc of agents.docs) {
    const agent = agentDoc.data() || {};
    if (!activePrimaryByAgent.has(agentDoc.id)) {
      issues.push({ type: 'MISSING_PRIMARY_ASSIGNMENT', agentId: agentDoc.id });
    }
    if (!directoryById.has(agentDoc.id)) {
      issues.push({ type: 'MISSING_DIRECTORY_PROJECTION', agentId: agentDoc.id });
    }
    if (!authorizationById.has(agentDoc.id)) {
      issues.push({ type: 'MISSING_AUTHORIZATION_PROJECTION', agentId: agentDoc.id });
    }
    const assignment = activePrimaryByAgent.get(agentDoc.id);
    if (assignment && normalizeString(agent.primaryAssignmentId) !== assignment) {
      issues.push({ type: 'STALE_AGENT_PROJECTION', agentId: agentDoc.id });
    }
    const primaryAssignments = primaryAssignmentsByAgent.get(agentDoc.id) || [];
    if (primaryAssignments.length === 1) {
      try {
        const assignmentDocument = primaryAssignments[0];
        const assignmentData = assignmentDocument.data() || {};
        const unitId = normalizeString(assignmentData.unitId);
        const unit = unitsById.get(unitId);
        const pathUnits = unit && array(unit.pathUnitIds).map((pathId) => ({
          id: pathId,
          ...(unitsById.get(pathId) || {}),
        }));
        if (!unit || !pathUnits || pathUnits.some((entry) => !entry.organizationId)) {
          throw failedPrecondition('The primary assignment path is incomplete.');
        }
        const placement = buildAgentOrganizationProjection({
          organization: { id: organization.id, ...(organization.data() || {}) },
          unit: { id: unitId, ...unit },
          pathUnits,
          assignmentId: assignmentDocument.id,
        });
        if (!projectionMatches(agent, placement, AGENT_PLACEMENT_FIELDS)) {
          pushIssueOnce(issues, {
            type: 'STALE_AGENT_PROJECTION',
            agentId: agentDoc.id,
          });
        }
        const expectedDirectory = buildAgentDirectoryProjection({
          agentId: agentDoc.id,
          agent,
          placement,
        });
        const currentDirectory = directoryById.get(agentDoc.id);
        if (currentDirectory && !projectionMatches(
          currentDirectory,
          expectedDirectory,
          DIRECTORY_PROJECTION_FIELDS,
        )) {
          issues.push({ type: 'DIRECTORY_PROJECTION_DRIFT', agentId: agentDoc.id });
        }
        const expectedAuthorization = buildAgentAuthorizationProjection({
          agent,
          placement,
        });
        const currentAuthorization = authorizationById.get(agentDoc.id);
        if (currentAuthorization && !projectionMatches(
          currentAuthorization,
          expectedAuthorization,
          AUTHORIZATION_PROJECTION_FIELDS,
        )) {
          issues.push({
            type: 'AUTHORIZATION_PROJECTION_DRIFT',
            agentId: agentDoc.id,
          });
        }
      } catch (error) {
        if (!(error instanceof OrganizationDomainError)) throw error;
        issues.push({
          type: 'INVALID_PRIMARY_ASSIGNMENT_PATH',
          agentId: agentDoc.id,
          assignmentIds: primaryAssignments.map((entry) => entry.id),
        });
      }
    }
  }
  for (const directoryDocument of directory.docs) {
    if (!agentsById.has(directoryDocument.id)) {
      issues.push({ type: 'ORPHAN_DIRECTORY_PROJECTION', agentId: directoryDocument.id });
    }
  }
  for (const authorizationDocument of authorization.docs) {
    if (!agentsById.has(authorizationDocument.id)) {
      issues.push({
        type: 'ORPHAN_AUTHORIZATION_PROJECTION',
        agentId: authorizationDocument.id,
      });
    }
  }
  return {
    organizationId,
    dryRun: true,
    scanned: {
      units: units.size,
      assignments: assignments.size,
      agents: agents.size,
      directory: directory.size,
      authorization: authorization.size,
      organizationDirectory: organizationDirectory.exists ? 1 : 0,
    },
    truncated: [units, assignments, agents, directory, authorization]
      .some((snapshot) => snapshot.truncated === true),
    issueCount: issues.length,
    issues,
  };
}

async function repairOrganizationDirectoryProjection({
  db,
  fieldValue,
  organizationId,
}) {
  const organizationRef = db.collection('organizations').doc(organizationId);
  const directoryRef = db.collection('organizationDirectory').doc(organizationId);
  return db.runTransaction(async (transaction) => {
    const organization = await transaction.get(organizationRef);
    if (!organization.exists) throw notFound('Organization');
    transaction.set(directoryRef, {
      name: normalizeString(organization.get('name')),
      nameLower: normalizeString(organization.get('nameLower')),
      status: normalizeStatus(organization.get('status')),
      updatedAt: fieldValue.serverTimestamp(),
    }, { merge: false });
  });
}

async function readQueryPages(baseQuery, pageSize) {
  const docs = [];
  let cursor = null;
  let truncated = false;
  while (docs.length < MAX_AUDIT_DOCUMENTS_PER_COLLECTION) {
    const remaining = MAX_AUDIT_DOCUMENTS_PER_COLLECTION - docs.length;
    const limit = Math.min(pageSize, remaining);
    let query = baseQuery.orderBy(FieldPath.documentId()).limit(limit);
    if (cursor) query = query.startAfter(cursor);
    const snapshot = await query.get();
    docs.push(...snapshot.docs);
    if (snapshot.size < limit || snapshot.empty) break;
    cursor = snapshot.docs.at(-1);
  }
  if (docs.length === MAX_AUDIT_DOCUMENTS_PER_COLLECTION && cursor) {
    const overflow = await baseQuery
      .orderBy(FieldPath.documentId())
      .startAfter(cursor)
      .limit(1)
      .get();
    truncated = !overflow.empty;
  }
  return {
    docs,
    size: docs.length,
    empty: docs.length === 0,
    truncated,
  };
}

function isValidUnitProjection({ unitId, unit, organizationId, unitsById }) {
  if (normalizeString(unit.organizationId) !== organizationId) return false;
  const pathIds = array(unit.pathUnitIds).map(normalizeString);
  const pathNames = array(unit.pathNames).map(normalizeString);
  const ancestors = array(unit.ancestorUnitIds).map(normalizeString);
  if (
    pathIds.length === 0 ||
    pathIds.at(-1) !== unitId ||
    pathNames.length !== pathIds.length ||
    stableSerialize(ancestors) !== stableSerialize(pathIds.slice(0, -1)) ||
    Number(unit.depth) !== ancestors.length
  ) {
    return false;
  }
  const expectedScopeKeys = [
    `org:${organizationId}`,
    ...pathIds.map((id) => `unit:${id}`),
  ];
  if (stableSerialize(array(unit.scopeKeys)) !== stableSerialize(expectedScopeKeys)) {
    return false;
  }
  const pathUnits = pathIds.map((id) => ({ id, ...(unitsById.get(id) || {}) }));
  if (pathUnits.some((entry) => normalizeString(entry.organizationId) !== organizationId)) {
    return false;
  }
  if (stableSerialize(pathUnits.map((entry) => normalizeString(entry.name))) !==
    stableSerialize(pathNames)) {
    return false;
  }
  for (let index = 0; index < pathUnits.length; index += 1) {
    const current = pathUnits[index];
    const parent = index === 0 ? null : pathUnits[index - 1];
    if (normalizeString(current.parentUnitId) !== (parent ? parent.id : '')) {
      return false;
    }
    if (normalizeString(current.parentUnitType) !==
      (parent ? normalizeUnitType(parent.type) : '')) {
      return false;
    }
    const type = normalizeUnitType(current.type);
    const expectedParentType = type === 'DEPARTMENT'
      ? null
      : type === 'SERVICE'
        ? 'DEPARTMENT'
        : type === 'BUREAU'
          ? 'SERVICE'
          : parent && normalizeUnitType(parent.type);
    if ((parent ? normalizeUnitType(parent.type) : null) !== expectedParentType) {
      return false;
    }
  }
  return true;
}

function validateUnitHeadProjection({
  unitId,
  unit,
  assignmentsById,
  issues,
  acting,
}) {
  const assignmentField = acting ? 'actingHeadAssignmentId' : 'headAssignmentId';
  const userField = acting ? 'actingHeadUserId' : 'headUserId';
  const assignmentId = normalizeString(unit[assignmentField]);
  const userId = normalizeString(unit[userField]);
  if (!assignmentId && !userId) return;
  const assignment = assignmentsById.get(assignmentId);
  if (
    !assignmentId ||
    !userId ||
    !assignment ||
    normalizeString(assignment.status) !== 'ACTIVE' ||
    normalizeString(assignment.assignmentType) !== 'HEAD' ||
    assignment.isActing === true !== acting ||
    normalizeString(assignment.unitId) !== unitId ||
    normalizeString(assignment.agentId) !== userId
  ) {
    issues.push({
      type: acting
        ? 'STALE_ACTING_HEAD_PROJECTION'
        : 'STALE_PERMANENT_HEAD_PROJECTION',
      unitId,
      assignmentIds: assignmentId ? [assignmentId] : [],
    });
  }
}

function projectionMatches(actual, expected, fields) {
  return fields.every((field) =>
    stableSerialize(actual && actual[field]) ===
      stableSerialize(expected && expected[field]));
}

function pushIssueOnce(issues, issue) {
  if (!issues.some((existing) =>
    existing.type === issue.type &&
    normalizeString(existing.agentId) === normalizeString(issue.agentId) &&
    normalizeString(existing.unitId) === normalizeString(issue.unitId))) {
    issues.push(issue);
  }
}

async function repairAgentOrganizationProjections({
  db,
  fieldValue,
  agentId,
  organizationId,
  assignmentId,
}) {
  const agentRef = db.collection('agents').doc(agentId);
  const organizationRef = db.collection('organizations').doc(organizationId);
  const assignmentRef = db.collection('organizationAssignments').doc(assignmentId);
  return db.runTransaction(async (transaction) => {
    const [agentSnapshot, organizationSnapshot, assignmentSnapshot] =
      await Promise.all([
        transaction.get(agentRef),
        transaction.get(organizationRef),
        transaction.get(assignmentRef),
      ]);
    if (!agentSnapshot.exists || !organizationSnapshot.exists ||
      !assignmentSnapshot.exists) {
      throw failedPrecondition('A repair source document no longer exists.');
    }
    const agent = agentSnapshot.data() || {};
    const assignment = assignmentSnapshot.data() || {};
    if (
      normalizeString(assignment.organizationId) !== organizationId ||
      normalizeString(assignment.agentId) !== agentId ||
      normalizeString(assignment.assignmentType) !== 'MEMBER' ||
      assignment.isPrimary !== true ||
      normalizeString(assignment.status) !== 'ACTIVE'
    ) {
      throw failedPrecondition('The primary assignment is not repairable.');
    }
    const unitId = requiredId(assignment.unitId, 'assigned unit');
    const unitSnapshot = await transaction.get(
      db.collection('organizationUnits').doc(unitId),
    );
    if (!unitSnapshot.exists) throw notFound('Assigned organization unit');
    const unit = { id: unitSnapshot.id, ...(unitSnapshot.data() || {}) };
    const pathUnits = await readUnitPath(transaction, db, unit);
    const placement = buildAgentOrganizationProjection({
      organization: {
        id: organizationSnapshot.id,
        ...(organizationSnapshot.data() || {}),
      },
      unit,
      pathUnits,
      assignmentId,
    });
    const now = fieldValue.serverTimestamp();
    writeAgentProjections({
      transaction,
      db,
      agentId,
      agent,
      placement,
      now,
    });
    return { agentId };
  });
}

async function runCommandTransaction({
  db,
  fieldValue,
  payload,
  actorUid,
  command,
  organizationId,
  work,
}) {
  const commandId = requiredId(payload.commandId, 'command');
  const receiptRef = db.collection('organizationCommandReceipts').doc(commandId);
  const auditRef = db.collection('organizationAuditEvents').doc();
  return db.runTransaction(async (transaction) => {
    const receipt = await transaction.get(receiptRef);
    if (receipt.exists) {
      const receiptData = receipt.data() || {};
      if (
        normalizeString(receiptData.command) !== command ||
        normalizeString(receiptData.actorUid) !== actorUid ||
        normalizeString(receiptData.payloadDigest) !== payloadDigest(payload)
      ) {
        throw failedPrecondition(
          'This command ID was already used for a different operation.',
        );
      }
      return { ...(receiptData.result || {}), replayed: true };
    }
    const now = fieldValue.serverTimestamp();
    let resolvedOrganizationId = normalizeString(organizationId);
    let auditData = null;
    const context = {
      now,
      setOrganizationId(value) {
        resolvedOrganizationId = normalizeString(value);
      },
      audit(value) {
        auditData = value;
      },
    };
    const result = await work(transaction, context);
    if (!auditData) {
      throw new Error(`Organization command ${command} did not append an audit event.`);
    }
    transaction.create(auditRef, {
      ...auditData,
      commandId,
      command,
      actorUid,
      organizationId: normalizeString(
        auditData.organizationId || resolvedOrganizationId,
      ),
      createdAt: now,
      schemaVersion: 2,
    });
    transaction.create(receiptRef, {
      command,
      actorUid,
      organizationId: resolvedOrganizationId,
      result,
      payloadDigest: payloadDigest(payload),
      createdAt: now,
    });
    return { ...result, replayed: false };
  });
}

async function readUnitPath(transaction, db, unit) {
  const pathIds = array(unit.pathUnitIds);
  if (pathIds.length === 0 || pathIds.length > 20) {
    throw failedPrecondition('The selected organization unit path is invalid.');
  }
  const snapshots = [];
  for (const pathId of pathIds) {
    snapshots.push(await transaction.get(
      db.collection('organizationUnits').doc(pathId),
    ));
  }
  return snapshots.map((snapshot) => {
    if (!snapshot.exists) throw failedPrecondition('The organization path is incomplete.');
    return { id: snapshot.id, ...(snapshot.data() || {}) };
  });
}

async function readProjectedUnitPath({ transaction, db, unit, projectedUnits }) {
  const pathIds = array(unit.pathUnitIds);
  if (pathIds.length === 0 || pathIds.length > 20) {
    throw failedPrecondition('The selected organization unit path is invalid.');
  }
  const path = [];
  for (const pathId of pathIds) {
    const projected = projectedUnits.get(pathId);
    if (projected) {
      path.push(projected);
      continue;
    }
    const snapshot = await transaction.get(
      db.collection('organizationUnits').doc(pathId),
    );
    if (!snapshot.exists) {
      throw failedPrecondition('The organization path is incomplete.');
    }
    path.push({ id: snapshot.id, ...(snapshot.data() || {}) });
  }
  return path;
}

function writeAgentProjections({
  transaction,
  db,
  agentId,
  agent,
  placement,
  now,
  writePrivateAgent = true,
}) {
  if (writePrivateAgent) {
    transaction.set(db.collection('agents').doc(agentId), {
      ...organizationPlacementProjection(placement),
      updatedAt: now,
    }, { merge: true });
  }
  transaction.set(db.collection('agentDirectory').doc(agentId), {
    ...buildAgentDirectoryProjection({ agentId, agent, placement }),
    updatedAt: now,
  }, { merge: false });
  transaction.set(db.collection('agentAuthorizationIndex').doc(agentId), {
    ...buildAgentAuthorizationProjection({ agent, placement }),
    updatedAt: now,
  }, { merge: false });
}

function organizationPlacementProjection(data) {
  return {
    organizationSchemaVersion: Number(data.organizationSchemaVersion) || 2,
    organizationId: normalizeString(data.organizationId),
    organizationName: normalizeString(data.organizationName),
    primaryOrganizationUnitId: normalizeString(data.primaryOrganizationUnitId),
    primaryOrganizationUnitName:
      normalizeString(data.primaryOrganizationUnitName),
    primaryOrganizationUnitType:
      normalizeString(data.primaryOrganizationUnitType),
    primaryAssignmentId: normalizeString(data.primaryAssignmentId),
    organizationAncestorUnitIds: array(data.organizationAncestorUnitIds),
    organizationPathUnitIds: array(data.organizationPathUnitIds),
    organizationPathNames: array(data.organizationPathNames),
    scopeKeys: array(data.scopeKeys),
    departmentId: normalizeString(data.departmentId),
    department: normalizeString(data.department),
    serviceId: normalizeString(data.serviceId),
    service: normalizeString(data.service),
    bureauId: normalizeString(data.bureauId),
    bureau: normalizeString(data.bureau),
  };
}

function payloadDigest(payload) {
  const normalized = { ...(payload || {}) };
  delete normalized.commandId;
  return createHash('sha256')
    .update(stableSerialize(normalized))
    .digest('hex');
}

function stableSerialize(value) {
  if (value === null || value === undefined) return JSON.stringify(value ?? null);
  if (value instanceof Date) return JSON.stringify(value.toISOString());
  if (value && typeof value.toDate === 'function') {
    return JSON.stringify(value.toDate().toISOString());
  }
  if (Array.isArray(value)) {
    return `[${value.map(stableSerialize).join(',')}]`;
  }
  if (typeof value === 'object') {
    return `{${Object.keys(value).sort().map((key) =>
      `${JSON.stringify(key)}:${stableSerialize(value[key])}`).join(',')}}`;
  }
  return JSON.stringify(value);
}

async function readBoundedRenameProjection(transaction, db, unitId) {
  const [descendantSnapshot, assignmentSnapshot] = await Promise.all([
    transaction.get(db.collection('organizationUnits')
      .where('ancestorUnitIds', 'array-contains', unitId).limit(101)),
    transaction.get(db.collection('organizationAssignments')
      .where('pathUnitIds', 'array-contains', unitId)
      .where('status', '==', 'ACTIVE').limit(101)),
  ]);
  if (descendantSnapshot.size > 100 || assignmentSnapshot.size > 100) {
    throw failedPrecondition(
      'This rename affects too many records for an interactive update.',
    );
  }
  const agentIds = new Set(assignmentSnapshot.docs
    .filter((doc) => doc.get('isPrimary') === true)
    .map((doc) => normalizeString(doc.get('agentId')))
    .filter(Boolean));
  const agents = new Map();
  for (const agentId of agentIds) {
    const snapshot = await transaction.get(db.collection('agents').doc(agentId));
    if (snapshot.exists) agents.set(agentId, snapshot.data() || {});
  }
  return {
    descendants: descendantSnapshot.docs,
    assignments: assignmentSnapshot.docs,
    agents,
  };
}

function applyRenameProjectionWrites({
  transaction,
  db,
  unitId,
  unitType,
  unitName,
  actorUid,
  now,
  descendants,
  assignments,
  agents,
}) {
  for (const snapshot of descendants) {
    const data = snapshot.data() || {};
    transaction.update(snapshot.ref, {
      pathNames: replacePathName(data, unitId, unitName),
      updatedAt: now,
      updatedBy: actorUid,
    });
  }
  // Assignment path and unit names are immutable historical snapshots.
  for (const [agentId, agent] of agents.entries()) {
    const pathNames = replacePathName({
      pathUnitIds: agent.organizationPathUnitIds,
      pathNames: agent.organizationPathNames,
    }, unitId, unitName);
    const updates = {
      organizationPathNames: pathNames,
      [`${unitType.toLowerCase()}`]: unitName,
      updatedAt: now,
    };
    if (normalizeString(agent.primaryOrganizationUnitId) === unitId) {
      updates.primaryOrganizationUnitName = unitName;
    }
    transaction.set(db.collection('agents').doc(agentId), updates, { merge: true });
    transaction.set(db.collection('agentDirectory').doc(agentId), {
      organizationPathNames: pathNames,
      ...(normalizeString(agent.primaryOrganizationUnitId) === unitId
        ? { primaryOrganizationUnitName: unitName }
        : {}),
      updatedAt: now,
    }, { merge: true });
  }
}

function replacePathName(data, unitId, unitName) {
  const pathIds = array(data.pathUnitIds);
  const pathNames = [...array(data.pathNames)];
  const index = pathIds.indexOf(unitId);
  if (index < 0 || pathNames.length !== pathIds.length) {
    throw failedPrecondition('An organization path projection is inconsistent.');
  }
  pathNames[index] = unitName;
  return pathNames;
}

function unitCodeLockRef(db, organizationId, code) {
  return db.collection('organizationUnitCodeLocks')
    .doc(`${organizationId}:${normalizeCode(code)}`);
}

function parseTimestamp(value, timestamp) {
  if (value === undefined || value === null || value === '') {
    return timestamp.now();
  }
  if (value && typeof value.toDate === 'function') return value;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    throw new OrganizationDomainError('invalid-argument', 'Enter a valid date.');
  }
  return timestamp.fromDate(date);
}

function timestampMilliseconds(value) {
  const date = value && typeof value.toDate === 'function'
    ? value.toDate()
    : value instanceof Date
      ? value
      : new Date(value);
  const milliseconds = date.getTime();
  if (Number.isNaN(milliseconds)) {
    throw new OrganizationDomainError('invalid-argument', 'Enter a valid date.');
  }
  return milliseconds;
}

function assertNotFuture(value, now, label) {
  if (timestampMilliseconds(value) > timestampMilliseconds(now)) {
    throw new OrganizationDomainError(
      'invalid-argument',
      `${label} cannot be in the future.`,
    );
  }
}

function assertNotBefore(value, minimum, message) {
  if (timestampMilliseconds(value) < timestampMilliseconds(minimum)) {
    throw failedPrecondition(message);
  }
}

function assertAfter(value, minimum, message) {
  if (timestampMilliseconds(value) <= timestampMilliseconds(minimum)) {
    throw new OrganizationDomainError('invalid-argument', message);
  }
}

function requiredId(value, label) {
  const id = normalizeString(value);
  if (!id) {
    throw new OrganizationDomainError(
      'invalid-argument',
      `Select a valid ${label}.`,
    );
  }
  return id;
}

function requiredReason(value) {
  const reason = normalizeString(value);
  if (!reason) {
    throw new OrganizationDomainError(
      'invalid-argument',
      'A reason is required.',
    );
  }
  if (reason.length > 1000) {
    throw new OrganizationDomainError(
      'invalid-argument',
      'The reason exceeds the supported length.',
    );
  }
  return reason;
}

function boundedLimit(value, fallback) {
  const limit = Number(value || fallback);
  if (!Number.isInteger(limit) || limit < 1 || limit > 100) {
    throw new OrganizationDomainError(
      'invalid-argument',
      'The page limit must be between 1 and 100.',
    );
  }
  return limit;
}

function organizationSummary(data) {
  return {
    code: normalizeCode(data.code),
    name: normalizeString(data.name),
    status: normalizeStatus(data.status),
  };
}

function unitSummary(data) {
  return {
    code: normalizeCode(data.code),
    name: normalizeString(data.name),
    type: normalizeUnitType(data.type),
    parentUnitId: normalizeString(data.parentUnitId) || null,
    status: normalizeStatus(data.status),
  };
}

function pushDuplicate(map, keyValue, id, issues, type) {
  const key = normalizeString(keyValue);
  if (!key) return;
  if (map.has(key)) {
    issues.push({ type, key, assignmentIds: [map.get(key), id] });
  } else {
    map.set(key, id);
  }
}

function array(value) {
  return Array.isArray(value) ? value : [];
}

function notFound(label) {
  return new OrganizationDomainError('not-found', `${label} not found.`);
}

function failedPrecondition(message) {
  return new OrganizationDomainError('failed-precondition', message);
}

module.exports = {
  ORGANIZATION_COMMANDS,
  auditOrganizationArchitecture,
  createInitialAgentPlacement,
  executeOrganizationCommand,
  refreshAgentProjections,
  readOrganizationCommandReceipt,
};
