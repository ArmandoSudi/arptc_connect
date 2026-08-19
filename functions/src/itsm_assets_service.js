'use strict';

const crypto = require('node:crypto');

const {
  ITSM_ROLES,
  ItsmCommandError,
  normalizeString,
} = require('./itsm_permissions');
const { runIdempotentCommand } = require('./itsm_idempotency');
const {
  ASSET_LIFECYCLE_STATES,
  CLAIM_STATUSES,
  ITSM_ASSETS_COMMANDS,
} = require('./itsm_assets_validation');
const {
  buildAssetAssignmentNotificationEvent,
  buildLowStockNotificationEvent,
} = require('./itsm_assets_notifications');

const ASSET_TRANSITIONS = Object.freeze({
  // Procurement-era states remain readable for existing records. New assets
  // enter the operational lifecycle directly in stock.
  planned: ['ordered'],
  ordered: ['received'],
  received: ['in_stock', 'configured', 'in_maintenance'],
  in_stock: ['configured', 'assigned', 'in_maintenance'],
  configured: ['assigned', 'in_stock', 'in_maintenance'],
  assigned: ['in_maintenance', 'returned', 'lost', 'stolen'],
  in_maintenance: ['configured', 'assigned', 'returned'],
  returned: ['in_stock', 'configured', 'in_maintenance'],
  retired: ['disposed'],
  disposed: [],
  // Recovery must use the return command so custody closes atomically.
  lost: ['returned'],
  stolen: ['returned'],
});

const DECOMMISSIONABLE_ASSET_STATES = new Set([
  'planned',
  'ordered',
  'received',
  'in_stock',
  'configured',
  'in_maintenance',
  'returned',
  'lost',
  'stolen',
]);

const CLAIM_TRANSITIONS = Object.freeze({
  submitted: ['acknowledged', 'rejected'],
  acknowledged: ['approved', 'rejected'],
  approved: ['resolved'],
  rejected: ['closed'],
  resolved: ['closed'],
  closed: [],
});

const RELATIONSHIP_CONSTRAINTS = Object.freeze({
  depends_on: {
    source: ['configuration_item', 'service'],
    target: ['configuration_item', 'service'],
  },
  runs_on: {
    source: ['configuration_item'],
    target: ['configuration_item'],
  },
  connected_to: {
    source: ['configuration_item'],
    target: ['configuration_item'],
  },
  uses: {
    source: ['user'],
    target: ['configuration_item', 'asset'],
  },
  represented_by: {
    source: ['asset'],
    target: ['configuration_item'],
  },
});

async function executeAssetsCommand({
  db,
  fieldValue,
  actor,
  command,
}) {
  requireManager(actor);
  return runIdempotentCommand({
    db,
    fieldValue,
    actorUid: actor.uid,
    command: command.command,
    idempotencyKey: command.idempotencyKey,
    execute: async (transaction, receiptId) => {
      const context = {
        db,
        fieldValue,
        transaction,
        actor,
        command,
        receiptId,
      };
      switch (command.command) {
        case ITSM_ASSETS_COMMANDS.registerAsset:
          return registerAsset(context);
        case ITSM_ASSETS_COMMANDS.updateAsset:
          return updateAsset(context);
        case ITSM_ASSETS_COMMANDS.changeAssetState:
          return changeAssetState(context);
        case ITSM_ASSETS_COMMANDS.transitionAsset:
          return transitionAsset(context);
        case ITSM_ASSETS_COMMANDS.assignAsset:
          return assignAsset(context);
        case ITSM_ASSETS_COMMANDS.returnAsset:
          return returnAsset(context);
        case ITSM_ASSETS_COMMANDS.decommissionAsset:
          return decommissionAsset(context);
        case ITSM_ASSETS_COMMANDS.saveAssetParameter:
          return saveAssetParameter(context);
        case ITSM_ASSETS_COMMANDS.saveStockLocation:
          return saveStockLocation(context);
        case ITSM_ASSETS_COMMANDS.saveStockItem:
          return saveStockItem(context);
        case ITSM_ASSETS_COMMANDS.receiveStock:
        case ITSM_ASSETS_COMMANDS.reserveStock:
        case ITSM_ASSETS_COMMANDS.issueStock:
        case ITSM_ASSETS_COMMANDS.returnStock:
        case ITSM_ASSETS_COMMANDS.transferStock:
        case ITSM_ASSETS_COMMANDS.adjustStock:
        case ITSM_ASSETS_COMMANDS.reconcileStock:
          return moveStock(context);
        case ITSM_ASSETS_COMMANDS.registerLicence:
          return registerLicence(context);
        case ITSM_ASSETS_COMMANDS.allocateLicence:
          return allocateLicence(context);
        case ITSM_ASSETS_COMMANDS.releaseLicence:
          return releaseLicence(context);
        case ITSM_ASSETS_COMMANDS.saveSupplier:
          return saveReferenceRecord(context, 'suppliers', 'supplier');
        case ITSM_ASSETS_COMMANDS.saveContract:
          return saveContract(context);
        case ITSM_ASSETS_COMMANDS.saveWarranty:
          return saveWarranty(context);
        case ITSM_ASSETS_COMMANDS.recordWarrantyClaim:
          return recordWarrantyClaim(context);
        case ITSM_ASSETS_COMMANDS.transitionWarrantyClaim:
          return transitionWarrantyClaim(context);
        case ITSM_ASSETS_COMMANDS.saveConfigurationItem:
          return saveConfigurationItem(context);
        case ITSM_ASSETS_COMMANDS.createCiRelationship:
          return createCiRelationship(context);
        case ITSM_ASSETS_COMMANDS.retireCiRelationship:
          return retireCiRelationship(context);
        default:
          throw invalid(`Unknown assets command: ${command.command}.`);
      }
    },
  });
}

async function registerAsset({
  db,
  fieldValue,
  transaction,
  actor,
  command,
  receiptId,
}) {
  const payload = command.payload;
  const ref = db.collection('assets').doc(payload.assetId);
  const timestamp = fieldValue.serverTimestamp();
  const hasInitialAssignment = Boolean(payload.assignedUserId);
  const status = hasInitialAssignment ? 'assigned' : 'in_stock';
  const identifierChanges = await prepareAssetIdentifierChanges({
    transaction,
    db,
    assetId: payload.assetId,
    current: null,
    next: payload,
  });
  let assignee = null;
  let warranty = null;
  let assignmentLockSnapshot = null;
  if (hasInitialAssignment) {
    [assignee, warranty, assignmentLockSnapshot] = await Promise.all([
      resolveActiveAgent(transaction, db, payload.assignedUserId, 'assigned user'),
      resolveProjectionWarranty(transaction, db, payload.warrantyId),
      transaction.get(db.collection('assetAssignmentLocks').doc(payload.assetId)),
    ]);
    if (assignmentLockSnapshot.exists &&
        assignmentLockSnapshot.data()?.isActive !== false) {
      throw failed('The asset already has an active assignment lock.');
    }
  }
  const assignmentId = hasInitialAssignment
    ? `assignment_${receiptId.substring(0, 32)}`
    : null;
  const assignedAt = hasInitialAssignment
    ? payload.assignedAt ? firestoreDate(payload.assignedAt) : timestamp
    : null;
  const assignedUserName = hasInitialAssignment
    ? authoritativeAgentName(assignee, payload.assignedUserId)
    : null;
  const assignedUserEmail = hasInitialAssignment
    ? authoritativeAgentEmail(assignee)
    : null;
  const departmentId = hasInitialAssignment
    ? normalizeString(assignee.departmentId) || payload.departmentId || null
    : payload.departmentId || null;
  const document = {
    ...withoutEmpty(payload, [
      'expectedRevision',
      'status',
      'assignedUserId',
      'assignedAt',
    ]),
    ...normalizedAssetIdentifierFields(payload),
    status,
    isInStock: !hasInitialAssignment,
    searchTokens: assetSearchTokens(payload),
    revision: 0,
    departmentId,
    assignedUserId: hasInitialAssignment ? payload.assignedUserId : null,
    assignedUserName,
    assignedUserEmail: assignedUserEmail || null,
    assignedAt,
    currentAssignmentId: assignmentId,
    decommissionedAt: null,
    decommissionedBy: null,
    decommissionReason: null,
    createdAt: timestamp,
    createdBy: actor.uid,
    updatedAt: timestamp,
    updatedBy: actor.uid,
  };
  transaction.create(ref, document);
  applyAssetIdentifierChanges({
    transaction,
    fieldValue,
    assetId: payload.assetId,
    changes: identifierChanges,
  });
  if (hasInitialAssignment) {
    const assignment = {
      assignmentId,
      assetId: payload.assetId,
      assetTag: payload.assetTag,
      assetType: payload.type,
      assetBrand: payload.brand || '',
      assetModel: payload.model || '',
      assignedUserId: payload.assignedUserId,
      assignedUserName,
      assignedUserEmail: assignedUserEmail || null,
      assignedByUserId: actor.uid,
      assignmentReason: 'Asset assigned during registration.',
      departmentId,
      departmentName: normalizeString(assignee.departmentName),
      locationId: payload.locationId || null,
      locationName: payload.locationName || '',
      status: 'current',
      isCurrent: true,
      assetStatus: 'assigned',
      assetCondition: payload.condition || 'good',
      assignedAt,
      returnedAt: null,
      returnedToUserId: null,
      relatedRequestId: null,
      evidence: [],
      actor: actorMap(actor),
      correlationId: command.idempotencyKey,
    };
    transaction.create(
      db.collection('assetAssignments').doc(assignmentId),
      assignment,
    );
    const assignmentLockRef = db.collection('assetAssignmentLocks').doc(payload.assetId);
    const assignmentLock = {
      assetId: payload.assetId,
      assignmentId,
      assignedUserId: payload.assignedUserId,
      isActive: true,
      updatedAt: timestamp,
    };
    if (assignmentLockSnapshot.exists) {
      transaction.update(assignmentLockRef, assignmentLock);
    } else {
      transaction.create(assignmentLockRef, assignmentLock);
    }
    writeSelfServiceProjection({
      db,
      fieldValue,
      transaction,
      asset: {...document, assetId: payload.assetId},
      assignment,
      warranty,
      isCurrent: true,
    });
    const notification = buildAssetAssignmentNotificationEvent({
      assetId: payload.assetId,
      assetTag: payload.assetTag,
      assignedUserId: payload.assignedUserId,
      assignedUserEmail,
      assignmentId,
      actor,
      createdAt: timestamp,
    });
    transaction.create(
      db.collection('notificationEvents').doc(notification.id),
      notification.data,
    );
  }
  writeAssetStateEvent({
    db,
    fieldValue,
    transaction,
    actor,
    command,
    receiptId,
    assetId: payload.assetId,
    fromStateId: null,
    fromStateName: null,
    toStateId: payload.stateId,
    toStateName: payload.stateName,
    observation: payload.observation || 'Asset registered.',
    revision: 0,
  });
  writeAssetLifecycleEvent({
    db,
    fieldValue,
    transaction,
    actor,
    command,
    receiptId,
    assetRef: ref,
    fromStatus: null,
    toStatus: status,
    reason: payload.observation || (hasInitialAssignment
      ? 'Asset registered and assigned to a custodian.'
      : 'Asset registered in stock.'),
  });
  writeAudit({
    db,
    fieldValue,
    transaction,
    actor,
    command,
    receiptId,
    parentRef: ref,
    entityType: 'asset',
    entityId: payload.assetId,
    action: 'registered',
    after: {
      status,
      assignedUserId: hasInitialAssignment ? payload.assignedUserId : null,
      revision: 0,
    },
  });
  return {
    assetId: payload.assetId,
    assignmentId,
    status,
    revision: 0,
  };
}

async function changeAssetState(context) {
  const { db, fieldValue, transaction, actor, command, receiptId } = context;
  const payload = command.payload;
  const ref = db.collection('assets').doc(payload.assetId);
  const snapshot = await transaction.get(ref);
  const asset = requireDocument(snapshot, 'The asset does not exist.');
  requireRevision(asset, payload.expectedRevision);
  if (['retired', 'disposed'].includes(normalizeString(asset.status))) {
    throw failed('A decommissioned asset state cannot be changed.');
  }
  if (normalizeString(asset.stateId) === payload.stateId) {
    throw failed('Select a different asset state.');
  }
  const revision = payload.expectedRevision + 1;
  const timestamp = fieldValue.serverTimestamp();
  transaction.update(ref, {
    stateId: payload.stateId,
    stateName: payload.stateName,
    observation: payload.observation,
    lastStateChangedAt: timestamp,
    lastStateChangedBy: actor.uid,
    revision,
    updatedAt: timestamp,
    updatedBy: actor.uid,
  });
  writeAssetStateEvent({
    ...context,
    assetId: payload.assetId,
    fromStateId: asset.stateId || null,
    fromStateName: asset.stateName || null,
    toStateId: payload.stateId,
    toStateName: payload.stateName,
    observation: payload.observation,
    revision,
  });
  writeAudit({
    ...context,
    parentRef: ref,
    entityType: 'asset',
    entityId: payload.assetId,
    action: 'state_changed',
    before: {
      stateId: asset.stateId || null,
      stateName: asset.stateName || null,
      revision: payload.expectedRevision,
    },
    after: {
      stateId: payload.stateId,
      stateName: payload.stateName,
      observation: payload.observation,
      revision,
    },
  });
  return {
    assetId: payload.assetId,
    stateId: payload.stateId,
    stateName: payload.stateName,
    revision,
  };
}

async function updateAsset(context) {
  const { db, fieldValue, transaction, actor, command, receiptId } = context;
  const payload = command.payload;
  const ref = db.collection('assets').doc(payload.assetId);
  const snapshot = await transaction.get(ref);
  const asset = requireDocument(snapshot, 'The asset does not exist.');
  requireRevision(asset, payload.expectedRevision);
  const mergedAsset = { ...asset, ...withoutEmpty(payload, ['assetId', 'expectedRevision']) };
  const identifierChanges = await prepareAssetIdentifierChanges({
    transaction,
    db,
    assetId: payload.assetId,
    current: asset,
    next: mergedAsset,
  });
  const warranty = asset.assignedUserId
    ? await resolveProjectionWarranty(transaction, db, mergedAsset.warrantyId)
    : null;
  const revision = payload.expectedRevision + 1;
  const patch = {
    ...withoutEmpty(payload, ['assetId', 'expectedRevision']),
    ...normalizedAssetIdentifierFields(mergedAsset),
    searchTokens: assetSearchTokens({ ...asset, ...payload }),
    revision,
    updatedAt: fieldValue.serverTimestamp(),
    updatedBy: actor.uid,
  };
  transaction.update(ref, patch);
  applyAssetIdentifierChanges({
    transaction,
    fieldValue,
    assetId: payload.assetId,
    changes: identifierChanges,
  });
  if (asset.assignedUserId && asset.currentAssignmentId) {
    writeSelfServiceProjection({
      db,
      fieldValue,
      transaction,
      asset: { ...mergedAsset, ...patch },
      assignment: {
        assetId: payload.assetId,
        assignmentId: asset.currentAssignmentId,
        assignedUserId: asset.assignedUserId,
        assignedUserName: asset.assignedUserName,
        assignedAt: asset.assignedAt,
      },
      warranty,
      isCurrent: true,
    });
  }
  writeAudit({
    ...context,
    parentRef: ref,
    entityType: 'asset',
    entityId: payload.assetId,
    action: 'updated',
    before: projectFields(asset, Object.keys(patch)),
    after: patch,
  });
  return { assetId: payload.assetId, status: asset.status, revision };
}

async function transitionAsset(context) {
  const { db, fieldValue, transaction, actor, command, receiptId } = context;
  const payload = command.payload;
  const ref = db.collection('assets').doc(payload.assetId);
  const snapshot = await transaction.get(ref);
  const asset = requireDocument(snapshot, 'The asset does not exist.');
  requireRevision(asset, payload.expectedRevision);
  const fromStatus = normalizeString(asset.status).toLowerCase();
  if (payload.toStatus === 'assigned') {
    throw failed('Use the assign asset action to select a custodian.');
  }
  if (payload.toStatus === 'returned') {
    throw failed('Use the return asset action to close the active assignment.');
  }
  if (payload.toStatus === 'retired') {
    throw failed('Use the decommission asset action.');
  }
  const hasActiveAssignment = Boolean(asset.currentAssignmentId || asset.assignedUserId);
  if (hasActiveAssignment &&
      !['in_maintenance', 'lost', 'stolen'].includes(payload.toStatus)) {
    throw failed('Return the active assignment before this lifecycle transition.');
  }
  validateAssetTransition(fromStatus, payload.toStatus);
  const revision = payload.expectedRevision + 1;
  const timestamp = fieldValue.serverTimestamp();
  const patch = {
    status: payload.toStatus,
    isInStock: isInStockStatus(payload.toStatus),
    condition: payload.condition || asset.condition || null,
    locationId: payload.locationId || asset.locationId || null,
    stockLocationId: payload.stockLocationId || asset.stockLocationId || null,
    revision,
    lastLifecycleReason: payload.reason,
    lastLifecycleChangedAt: timestamp,
    updatedAt: timestamp,
    updatedBy: actor.uid,
  };
  transaction.update(ref, patch);
  if (asset.assignedUserId && asset.currentAssignmentId) {
    transaction.update(db.collection('assetAssignments').doc(asset.currentAssignmentId), {
      assetStatus: payload.toStatus,
      updatedAt: timestamp,
    });
    writeSelfServiceProjection({
      db,
      fieldValue,
      transaction,
      asset: { ...asset, ...patch },
      assignment: {
        assetId: payload.assetId,
        assignmentId: asset.currentAssignmentId,
        assignedUserId: asset.assignedUserId,
        assignedUserName: asset.assignedUserName,
        assignedAt: asset.assignedAt,
      },
      warranty: null,
      // Lost and stolen assets remain the custodian's responsibility until
      // recovery is recorded through the dedicated return workflow.
      isCurrent: true,
    });
  }
  writeAssetLifecycleEvent({
    db,
    fieldValue,
    transaction,
    actor,
    command,
    receiptId,
    assetRef: ref,
    fromStatus,
    toStatus: payload.toStatus,
    reason: payload.reason,
    relatedRequestId: payload.relatedRequestId,
    evidence: payload.evidence,
  });
  writeAudit({
    ...context,
    parentRef: ref,
    entityType: 'asset',
    entityId: payload.assetId,
    action: 'lifecycle_transitioned',
    before: { status: fromStatus, revision: payload.expectedRevision },
    after: { status: payload.toStatus, revision },
  });
  return { assetId: payload.assetId, status: payload.toStatus, revision };
}

async function assignAsset(context) {
  const { db, fieldValue, transaction, actor, command, receiptId } = context;
  const payload = command.payload;
  const ref = db.collection('assets').doc(payload.assetId);
  const snapshot = await transaction.get(ref);
  const asset = requireDocument(snapshot, 'The asset does not exist.');
  requireRevision(asset, payload.expectedRevision);
  if (asset.currentAssignmentId || asset.assignedUserId) {
    throw failed('The asset already has an active assignment.');
  }
  if (!['in_stock', 'configured'].includes(asset.status)) {
    throw failed(`An asset in ${asset.status || 'unknown'} status cannot be assigned.`);
  }
  const [assignee, assignmentLockSnapshot, warranty] = await Promise.all([
    resolveActiveAgent(transaction, db, payload.assignedUserId, 'assigned user'),
    transaction.get(db.collection('assetAssignmentLocks').doc(payload.assetId)),
    resolveProjectionWarranty(transaction, db, asset.warrantyId),
  ]);
  const assignmentLock = assignmentLockSnapshot.exists
    ? assignmentLockSnapshot.data() || {}
    : null;
  if (assignmentLock && assignmentLock.isActive !== false) {
    throw failed('The asset already has an active assignment.');
  }
  const timestamp = fieldValue.serverTimestamp();
  const assignedAt = payload.assignedAt
    ? firestoreDate(payload.assignedAt)
    : timestamp;
  const revision = payload.expectedRevision + 1;
  const assignmentId = `assignment_${receiptId.substring(0, 32)}`;
  const assignedUserName = authoritativeAgentName(assignee, payload.assignedUserId);
  const assignedUserEmail = authoritativeAgentEmail(assignee);
  const assignment = {
    assignmentId,
    assetId: payload.assetId,
    assetTag: asset.assetTag,
    assetType: asset.type,
    assetBrand: asset.brand || '',
    assetModel: asset.model || '',
    assignedUserId: payload.assignedUserId,
    assignedUserName,
    assignedUserEmail: assignedUserEmail || null,
    assignedByUserId: actor.uid,
    assignmentReason: 'Asset assigned to a custodian.',
    departmentId: normalizeString(assignee.departmentId) || payload.departmentId || null,
    departmentName: normalizeString(assignee.departmentName) || asset.departmentName || '',
    locationId: payload.locationId || null,
    locationName: payload.locationName || asset.locationName || '',
    status: 'current',
    isCurrent: true,
    assetStatus: 'assigned',
    assetCondition: asset.condition || 'good',
    assignedAt,
    returnedAt: null,
    returnedToUserId: null,
    relatedRequestId: payload.relatedRequestId || null,
    evidence: payload.evidence,
    actor: actorMap(actor),
    correlationId: command.idempotencyKey,
  };
  transaction.create(db.collection('assetAssignments').doc(assignmentId), assignment);
  const assignmentLockRef = db.collection('assetAssignmentLocks').doc(payload.assetId);
  const assignmentLockDocument = {
    assetId: payload.assetId,
    assignmentId,
    assignedUserId: payload.assignedUserId,
    isActive: true,
    updatedAt: timestamp,
  };
  if (assignmentLockSnapshot.exists) {
    transaction.update(assignmentLockRef, assignmentLockDocument);
  } else {
    transaction.create(assignmentLockRef, assignmentLockDocument);
  }
  transaction.update(ref, {
    status: 'assigned',
    isInStock: false,
    assignedUserId: payload.assignedUserId,
    assignedUserName,
    assignedUserEmail: assignedUserEmail || null,
    departmentId: normalizeString(assignee.departmentId) ||
      payload.departmentId || asset.departmentId || null,
    locationId: payload.locationId || asset.locationId || null,
    currentAssignmentId: assignmentId,
    assignedAt,
    revision,
    updatedAt: timestamp,
    updatedBy: actor.uid,
  });
  writeSelfServiceProjection({
    db,
    fieldValue,
    transaction,
    asset: {
      ...asset,
      status: 'assigned',
      locationId: payload.locationId || asset.locationId || null,
      revision,
    },
    assignment,
    warranty,
    isCurrent: true,
  });
  const notification = buildAssetAssignmentNotificationEvent({
    assetId: payload.assetId,
    assetTag: asset.assetTag,
    assignedUserId: payload.assignedUserId,
    assignedUserEmail,
    assignmentId,
    actor,
    createdAt: timestamp,
  });
  transaction.create(
    db.collection('notificationEvents').doc(notification.id),
    notification.data,
  );
  writeAssetLifecycleEvent({
    ...context,
    assetRef: ref,
    fromStatus: asset.status,
    toStatus: 'assigned',
    reason: 'Asset assigned to a custodian.',
    relatedRequestId: payload.relatedRequestId,
    evidence: payload.evidence,
  });
  writeAudit({
    ...context,
    parentRef: ref,
    entityType: 'asset',
    entityId: payload.assetId,
    action: 'assigned',
    before: {
      status: asset.status,
      assignedUserId: asset.assignedUserId || null,
      revision: payload.expectedRevision,
    },
    after: {
      status: 'assigned',
      assignedUserId: payload.assignedUserId,
      revision,
    },
  });
  return {
    assetId: payload.assetId,
    assignmentId,
    status: 'assigned',
    revision,
  };
}

async function returnAsset(context) {
  const { db, fieldValue, transaction, actor, command } = context;
  const payload = command.payload;
  const ref = db.collection('assets').doc(payload.assetId);
  const snapshot = await transaction.get(ref);
  const asset = requireDocument(snapshot, 'The asset does not exist.');
  requireRevision(asset, payload.expectedRevision);
  if (!['assigned', 'in_maintenance', 'lost', 'stolen'].includes(asset.status) ||
      !asset.assignedUserId) {
    throw failed('Only an assigned, maintained, lost, or stolen asset can be returned.');
  }
  const timestamp = fieldValue.serverTimestamp();
  const revision = payload.expectedRevision + 1;
  if (!asset.currentAssignmentId) {
    throw failed('The asset has no current assignment record.');
  }
  const assignmentRef = db.collection('assetAssignments').doc(asset.currentAssignmentId);
  const assignmentSnapshot = await transaction.get(assignmentRef);
  const assignment = requireDocument(
    assignmentSnapshot,
    'The current asset assignment does not exist.',
  );
  if (assignment.status !== 'current' || assignment.assignedUserId !== asset.assignedUserId) {
    throw failed('The current asset assignment is inconsistent.');
  }
  const assignmentLockRef = db.collection('assetAssignmentLocks').doc(payload.assetId);
  const [assignmentLockSnapshot, warranty] = await Promise.all([
    transaction.get(assignmentLockRef),
    resolveProjectionWarranty(transaction, db, asset.warrantyId),
  ]);
  if (assignmentLockSnapshot.exists) {
    const assignmentLock = assignmentLockSnapshot.data() || {};
    if (assignmentLock.isActive === false ||
        assignmentLock.assignmentId !== asset.currentAssignmentId) {
      throw failed('The active assignment lock is inconsistent.');
    }
  }
  transaction.update(assignmentRef, {
    status: 'returned',
    isCurrent: false,
    assetStatus: 'returned',
    assetCondition: payload.condition,
    returnedAt: timestamp,
    returnedToUserId: actor.uid,
    returnReason: payload.reason,
    returnLocationId: payload.locationId || null,
    stockLocationId: payload.stockLocationId || null,
    relatedRequestId: payload.relatedRequestId || assignment.relatedRequestId || null,
    returnEvidence: payload.evidence,
    updatedAt: timestamp,
  });
  transaction.update(ref, {
    status: 'returned',
    isInStock: false,
    condition: payload.condition,
    locationId: payload.locationId || asset.locationId || null,
    stockLocationId: payload.stockLocationId || asset.stockLocationId || null,
    ...clearedAssignment(),
    currentAssignmentId: null,
    revision,
    updatedAt: timestamp,
    updatedBy: actor.uid,
  });
  if (assignmentLockSnapshot.exists) {
    transaction.update(assignmentLockRef, {
      isActive: false,
      returnedAt: timestamp,
      updatedAt: timestamp,
    });
  }
  writeSelfServiceProjection({
    db,
    fieldValue,
    transaction,
    asset: {
      ...asset,
      status: 'returned',
      condition: payload.condition,
      locationId: payload.locationId || asset.locationId || null,
    },
    assignment,
    warranty,
    isCurrent: false,
  });
  writeAssetLifecycleEvent({
    ...context,
    assetRef: ref,
    fromStatus: asset.status,
    toStatus: 'returned',
    reason: payload.reason,
    relatedRequestId: payload.relatedRequestId,
    evidence: payload.evidence,
  });
  writeAudit({
    ...context,
    parentRef: ref,
    entityType: 'asset',
    entityId: payload.assetId,
    action: 'returned',
    before: {
      status: asset.status,
      assignedUserId: asset.assignedUserId,
      revision: payload.expectedRevision,
    },
    after: { status: 'returned', assignedUserId: null, revision },
  });
  return { assetId: payload.assetId, status: 'returned', revision };
}

async function decommissionAsset(context) {
  const { db, fieldValue, transaction, actor, command } = context;
  const payload = command.payload;
  const ref = db.collection('assets').doc(payload.assetId);
  const assignmentLockRef = db.collection('assetAssignmentLocks').doc(payload.assetId);
  const [snapshot, assignmentLockSnapshot] = await Promise.all([
    transaction.get(ref),
    transaction.get(assignmentLockRef),
  ]);
  const asset = requireDocument(snapshot, 'The asset does not exist.');
  requireRevision(asset, payload.expectedRevision);
  const fromStatus = normalizeString(asset.status).toLowerCase();
  if (!DECOMMISSIONABLE_ASSET_STATES.has(fromStatus)) {
    throw failed(`An asset in ${fromStatus || 'unknown'} status cannot be decommissioned.`);
  }
  const lock = assignmentLockSnapshot.exists
    ? assignmentLockSnapshot.data() || {}
    : null;
  if (asset.currentAssignmentId || asset.assignedUserId || lock?.isActive === true) {
    throw failed('Return the active assignment before decommissioning this asset.');
  }
  const revision = payload.expectedRevision + 1;
  const timestamp = fieldValue.serverTimestamp();
  transaction.update(ref, {
    status: 'retired',
    isInStock: false,
    decommissionedAt: timestamp,
    decommissionedBy: actor.uid,
    decommissionReason: payload.observation,
    lastLifecycleReason: payload.observation,
    lastLifecycleChangedAt: timestamp,
    revision,
    updatedAt: timestamp,
    updatedBy: actor.uid,
  });
  writeAssetLifecycleEvent({
    ...context,
    assetRef: ref,
    fromStatus,
    toStatus: 'retired',
    reason: payload.observation,
  });
  writeAudit({
    ...context,
    parentRef: ref,
    entityType: 'asset',
    entityId: payload.assetId,
    action: 'decommissioned',
    before: { status: fromStatus, revision: payload.expectedRevision },
    after: {
      status: 'retired',
      isInStock: false,
      decommissionReason: payload.observation,
      revision,
    },
  });
  return { assetId: payload.assetId, status: 'retired', revision };
}

async function saveStockLocation(context) {
  const { db, fieldValue, transaction, actor, command } = context;
  const payload = command.payload;
  const ref = db.collection('stockLocations').doc(payload.id);
  const snapshot = await transaction.get(ref);
  const current = snapshot.exists ? snapshot.data() || {} : null;
  requireExpectedRevision(current, payload.expectedRevision);
  const revision = current ? integer(current.revision) + 1 : 0;
  const timestamp = fieldValue.serverTimestamp();
  const document = {
    name: payload.name,
    description: payload.description || '',
    siteId: payload.siteId,
    siteName: payload.siteName,
    barcode: payload.barcode || '',
    isActive: payload.isActive,
    revision,
    updatedAt: timestamp,
    updatedBy: actor.uid,
  };
  if (current) {
    transaction.update(ref, document);
  } else {
    transaction.create(ref, {
      ...document,
      createdAt: timestamp,
      createdBy: actor.uid,
    });
  }
  writeAudit({
    ...context,
    parentRef: ref,
    entityType: 'stock_location',
    entityId: payload.id,
    action: current ? 'updated' : 'created',
    before: current ? { revision: current.revision } : {},
    after: { revision, isActive: payload.isActive },
  });
  return { id: payload.id, revision, created: !current };
}

async function saveAssetParameter(context) {
  const { db, fieldValue, transaction, actor, command } = context;
  const payload = command.payload;
  const collection = db.collection('assetParameters');
  const ref = payload.id ? collection.doc(payload.id) : collection.doc();
  const snapshot = await transaction.get(ref);
  const current = snapshot.exists ? snapshot.data() || {} : null;
  requireExpectedRevision(current, payload.expectedRevision);
  const revision = current ? integer(current.revision) + 1 : 0;
  const timestamp = fieldValue.serverTimestamp();
  const document = {
    type: payload.type,
    name: payload.name,
    isActive: payload.isActive,
    sortOrder: payload.sortOrder,
    revision,
    updatedAt: timestamp,
    updatedBy: actor.uid,
  };
  if (current) {
    transaction.update(ref, document);
  } else {
    transaction.create(ref, {
      ...document,
      createdAt: timestamp,
      createdBy: actor.uid,
    });
  }
  writeAudit({
    ...context,
    parentRef: ref,
    entityType: 'asset_parameter',
    entityId: ref.id,
    action: current ? 'updated' : 'created',
    before: current ? { revision: current.revision } : {},
    after: { revision, type: payload.type, isActive: payload.isActive },
  });
  return { id: ref.id, revision, created: !current };
}

async function saveStockItem(context) {
  const { db, fieldValue, transaction, actor, command } = context;
  const payload = command.payload;
  const ref = db.collection('stockItems').doc(payload.id);
  const snapshot = await transaction.get(ref);
  const current = snapshot.exists ? snapshot.data() || {} : null;
  requireExpectedRevision(current, payload.expectedRevision);
  const revision = current ? integer(current.revision) + 1 : 0;
  const balances = current ? normalizeBalances(current.balances) : {};
  const totals = stockTotals(balances);
  const isLowStock = totals.available <= payload.minimumQuantity;
  const timestamp = fieldValue.serverTimestamp();
  const document = {
    sku: payload.sku,
    name: payload.name,
    description: payload.description || '',
    kind: payload.kind,
    barcode: payload.barcode || '',
    assetCategoryId: payload.assetCategoryId || '',
    unitOfMeasure: payload.unitOfMeasure,
    minimumQuantity: payload.minimumQuantity,
    isActive: payload.isActive,
    balances,
    totalOnHand: totals.onHand,
    totalReserved: totals.reserved,
    availableQuantity: totals.available,
    isLowStock,
    lowStockEpisode: integer(current && current.lowStockEpisode),
    revision,
    updatedAt: timestamp,
    updatedBy: actor.uid,
  };
  if (current) {
    transaction.update(ref, document);
  } else {
    transaction.create(ref, {
      ...document,
      createdAt: timestamp,
      createdBy: actor.uid,
    });
  }
  writeAudit({
    ...context,
    parentRef: ref,
    entityType: 'stock_item',
    entityId: payload.id,
    action: current ? 'updated' : 'created',
    before: current ? { revision: current.revision } : {},
    after: { revision, minimumQuantity: payload.minimumQuantity },
  });
  return { id: payload.id, revision, created: !current };
}

async function moveStock(context) {
  const { db, fieldValue, transaction, actor, command, receiptId } = context;
  const payload = command.payload;
  const ref = db.collection('stockItems').doc(payload.stockItemId);
  const snapshot = await transaction.get(ref);
  const stockItem = requireDocument(snapshot, 'The stock item does not exist.');
  if (stockItem.isActive === false) throw failed('The stock item is disabled.');
  const recipientAgent = payload.recipientUserId
    ? await resolveActiveAgent(
      transaction,
      db,
      payload.recipientUserId,
      'stock recipient',
    )
    : null;
  const supportingDocument = await resolveStockSupportingDocument(
    transaction,
    db,
    payload.stockItemId,
    payload.supportingDocument,
  );
  const beforeBalances = normalizeBalances(stockItem.balances);
  const beforeTotals = stockTotals(beforeBalances);
  const afterBalances = clone(beforeBalances);
  const movementType = movementTypeFor(command.command);
  const effects = applyStockMovement(command.command, payload, afterBalances);
  validateBalances(afterBalances);
  const totals = stockTotals(afterBalances);
  const minimumQuantity = integer(stockItem.minimumQuantity);
  const wasLowStock = beforeTotals.available <= minimumQuantity;
  const isLowStock = totals.available <= minimumQuantity;
  const enteredLowStock = !wasLowStock && isLowStock;
  const lowStockEpisode = enteredLowStock
    ? integer(stockItem.lowStockEpisode) + 1
    : integer(stockItem.lowStockEpisode);
  const timestamp = fieldValue.serverTimestamp();
  const movementId = `movement_${receiptId.substring(0, 32)}`;
  const movement = {
    movementId,
    movementType,
    stockItemId: payload.stockItemId,
    quantity: effects.quantity,
    sourceLocationId: payload.sourceLocationId || null,
    destinationLocationId: payload.destinationLocationId || null,
    actor: actorMap(actor),
    actorUserId: actor.uid,
    recipient: payload.recipientUserId
      ? {
        userId: payload.recipientUserId,
        name: authoritativeAgentName(recipientAgent, payload.recipientUserId),
        email: authoritativeAgentEmail(recipientAgent) || null,
      }
      : null,
    recipientUserId: payload.recipientUserId || null,
    relatedRequestId: payload.relatedRequestId || null,
    reason: payload.reason,
    supportingDocument,
    evidence: payload.evidence,
    correlationId: payload.correlationId || command.idempotencyKey,
    idempotencyKey: command.idempotencyKey,
    receiptId,
    occurredAt: timestamp,
    createdAt: timestamp,
    before: effects.before,
    after: effects.after,
    quantityChanges: effects.quantityChanges,
  };
  transaction.update(ref, {
    balances: afterBalances,
    totalOnHand: totals.onHand,
    totalReserved: totals.reserved,
    availableQuantity: totals.available,
    isLowStock,
    lowStockEpisode,
    lastMovementId: movementId,
    lastMovementAt: timestamp,
    updatedAt: timestamp,
    updatedBy: actor.uid,
  });
  transaction.create(db.collection('stockMovements').doc(movementId), movement);
  if (enteredLowStock) {
    const notification = buildLowStockNotificationEvent({
      stockItemId: payload.stockItemId,
      stockItemName: stockItem.name,
      sku: stockItem.sku,
      availableQuantity: totals.available,
      minimumQuantity,
      episode: lowStockEpisode,
      actor,
      createdAt: timestamp,
    });
    transaction.create(
      db.collection('notificationEvents').doc(notification.id),
      notification.data,
    );
  }
  writeAudit({
    ...context,
    parentRef: ref,
    entityType: 'stock_item',
    entityId: payload.stockItemId,
    action: movementType,
    before: { balances: effects.before },
    after: { balances: effects.after },
  });
  return {
    stockItemId: payload.stockItemId,
    movementId,
    movementType,
    totalOnHand: totals.onHand,
    totalReserved: totals.reserved,
    availableQuantity: totals.available,
  };
}

function applyStockMovement(command, payload, balances) {
  const touched = new Set([
    payload.sourceLocationId,
    payload.destinationLocationId,
  ].filter(Boolean));
  const before = Object.fromEntries(
    [...touched].map((id) => [id, clone(balanceAt(balances, id))]),
  );
  const changes = {};
  const source = payload.sourceLocationId
    ? balanceAt(balances, payload.sourceLocationId)
    : null;
  const destination = payload.destinationLocationId
    ? balanceAt(balances, payload.destinationLocationId)
    : null;
  const quantity = payload.quantity || 0;

  switch (command) {
    case ITSM_ASSETS_COMMANDS.receiveStock:
    case ITSM_ASSETS_COMMANDS.returnStock:
      destination.onHand += quantity;
      changes[payload.destinationLocationId] = { onHand: quantity, reserved: 0 };
      break;
    case ITSM_ASSETS_COMMANDS.reserveStock:
      requireAvailable(source, quantity);
      source.reserved += quantity;
      changes[payload.sourceLocationId] = { onHand: 0, reserved: quantity };
      break;
    case ITSM_ASSETS_COMMANDS.issueStock: {
      const reservedQuantity = payload.reservedQuantity || 0;
      if (source.reserved < reservedQuantity) {
        throw failed('The reserved stock is lower than reservedQuantity.');
      }
      requireAvailable(source, quantity - reservedQuantity);
      source.onHand -= quantity;
      source.reserved -= reservedQuantity;
      changes[payload.sourceLocationId] = {
        onHand: -quantity,
        reserved: -reservedQuantity,
      };
      break;
    }
    case ITSM_ASSETS_COMMANDS.transferStock:
      requireAvailable(source, quantity);
      source.onHand -= quantity;
      destination.onHand += quantity;
      changes[payload.sourceLocationId] = { onHand: -quantity, reserved: 0 };
      changes[payload.destinationLocationId] = { onHand: quantity, reserved: 0 };
      break;
    case ITSM_ASSETS_COMMANDS.adjustStock:
      source.onHand += payload.adjustmentDelta;
      changes[payload.sourceLocationId] = {
        onHand: payload.adjustmentDelta,
        reserved: 0,
      };
      break;
    case ITSM_ASSETS_COMMANDS.reconcileStock:
      if (source.onHand === payload.targetOnHand &&
          source.reserved === payload.targetReserved) {
        throw failed('Reconciliation did not identify a stock difference.');
      }
      changes[payload.sourceLocationId] = {
        onHand: payload.targetOnHand - source.onHand,
        reserved: payload.targetReserved - source.reserved,
      };
      source.onHand = payload.targetOnHand;
      source.reserved = payload.targetReserved;
      break;
    default:
      throw invalid(`Unsupported stock command: ${command}.`);
  }
  const after = Object.fromEntries(
    [...touched].map((id) => [id, clone(balanceAt(balances, id))]),
  );
  const movementQuantity = command === ITSM_ASSETS_COMMANDS.reconcileStock
    ? Math.abs(changes[payload.sourceLocationId].onHand)
    : quantity;
  return { quantity: movementQuantity, before, after, quantityChanges: changes };
}

async function registerLicence(context) {
  const { db, fieldValue, transaction, actor, command } = context;
  const payload = command.payload;
  const ref = db.collection('softwareLicences').doc(payload.licenceId);
  const timestamp = fieldValue.serverTimestamp();
  const document = {
    ...withoutEmpty(payload),
    purchaseDate: firestoreDate(payload.purchaseDate),
    effectiveDate: firestoreDate(payload.effectiveDate),
    expiryDate: firestoreDate(payload.expiryDate),
    renewalDate: firestoreDate(payload.renewalDate),
    allocatedQuantity: 0,
    availableQuantity: payload.purchasedQuantity,
    revision: 0,
    createdAt: timestamp,
    createdBy: actor.uid,
    updatedAt: timestamp,
    updatedBy: actor.uid,
  };
  transaction.create(ref, document);
  writeLicenceHistory({
    ...context,
    licenceRef: ref,
    action: 'registered',
    after: {
      purchasedQuantity: payload.purchasedQuantity,
      allocatedQuantity: 0,
    },
  });
  writeAudit({
    ...context,
    parentRef: ref,
    entityType: 'software_licence',
    entityId: payload.licenceId,
    action: 'registered',
    after: { purchasedQuantity: payload.purchasedQuantity },
  });
  return {
    licenceId: payload.licenceId,
    allocatedQuantity: 0,
    availableQuantity: payload.purchasedQuantity,
  };
}

async function allocateLicence(context) {
  const { db, fieldValue, transaction, actor, command, receiptId } = context;
  const payload = command.payload;
  const ref = db.collection('softwareLicences').doc(payload.licenceId);
  const snapshot = await transaction.get(ref);
  const licence = requireDocument(snapshot, 'The software licence does not exist.');
  const purchased = integer(licence.purchasedQuantity);
  const allocated = integer(licence.allocatedQuantity);
  if (allocated + payload.quantity > purchased) {
    throw failed('The allocation exceeds the purchased licence capacity.');
  }
  const target = payload.assignmentType === 'user'
    ? await resolveActiveAgent(transaction, db, payload.assigneeId, 'licence assignee')
    : await resolveAllocatableAsset(transaction, db, payload.assigneeId);
  const timestamp = fieldValue.serverTimestamp();
  const allocationId = `allocation_${receiptId.substring(0, 32)}`;
  const assigneeName = payload.assignmentType === 'user'
    ? authoritativeAgentName(target, payload.assigneeId)
    : authoritativeAssetName(target, payload.assigneeId);
  transaction.create(ref.collection('allocations').doc(allocationId), {
    allocationId,
    licenceId: payload.licenceId,
    assignmentType: payload.assignmentType,
    assigneeId: payload.assigneeId,
    assigneeName,
    assigneeEmail: payload.assignmentType === 'user'
      ? authoritativeAgentEmail(target) || null
      : null,
    quantity: payload.quantity,
    relatedRequestId: payload.relatedRequestId || null,
    notes: payload.notes || null,
    status: 'active',
    allocatedBy: actorMap(actor),
    allocatedAt: timestamp,
    correlationId: command.idempotencyKey,
  });
  const nextAllocated = allocated + payload.quantity;
  transaction.update(ref, {
    allocatedQuantity: nextAllocated,
    availableQuantity: purchased - nextAllocated,
    revision: integer(licence.revision) + 1,
    updatedAt: timestamp,
    updatedBy: actor.uid,
  });
  writeLicenceHistory({
    ...context,
    licenceRef: ref,
    action: 'allocated',
    before: { allocatedQuantity: allocated },
    after: {
      allocatedQuantity: nextAllocated,
      allocationId,
      assigneeId: payload.assigneeId,
      quantity: payload.quantity,
    },
  });
  writeAudit({
    ...context,
    parentRef: ref,
    entityType: 'software_licence',
    entityId: payload.licenceId,
    action: 'allocated',
    before: { allocatedQuantity: allocated },
    after: { allocatedQuantity: nextAllocated, allocationId },
  });
  return {
    licenceId: payload.licenceId,
    allocationId,
    allocatedQuantity: nextAllocated,
    availableQuantity: purchased - nextAllocated,
  };
}

async function releaseLicence(context) {
  const { db, fieldValue, transaction, actor, command } = context;
  const payload = command.payload;
  const ref = db.collection('softwareLicences').doc(payload.licenceId);
  const allocationRef = ref.collection('allocations').doc(payload.allocationId);
  const [licenceSnapshot, allocationSnapshot] = await Promise.all([
    transaction.get(ref),
    transaction.get(allocationRef),
  ]);
  const licence = requireDocument(licenceSnapshot, 'The software licence does not exist.');
  const allocation = requireDocument(allocationSnapshot, 'The licence allocation does not exist.');
  if (allocation.status !== 'active') throw failed('The licence allocation is not active.');
  const purchased = integer(licence.purchasedQuantity);
  const allocated = integer(licence.allocatedQuantity);
  const quantity = integer(allocation.quantity);
  if (quantity < 1 || allocated < quantity) {
    throw failed('The licence allocation totals are inconsistent.');
  }
  const timestamp = fieldValue.serverTimestamp();
  const nextAllocated = allocated - quantity;
  transaction.update(allocationRef, {
    status: 'released',
    releasedAt: timestamp,
    releasedBy: actorMap(actor),
    releaseReason: payload.reason,
    releaseRelatedRequestId: payload.relatedRequestId || null,
  });
  transaction.update(ref, {
    allocatedQuantity: nextAllocated,
    availableQuantity: purchased - nextAllocated,
    revision: integer(licence.revision) + 1,
    updatedAt: timestamp,
    updatedBy: actor.uid,
  });
  writeLicenceHistory({
    ...context,
    licenceRef: ref,
    action: 'released',
    before: { allocatedQuantity: allocated },
    after: {
      allocatedQuantity: nextAllocated,
      allocationId: payload.allocationId,
      quantity,
    },
  });
  writeAudit({
    ...context,
    parentRef: ref,
    entityType: 'software_licence',
    entityId: payload.licenceId,
    action: 'released',
    before: { allocatedQuantity: allocated },
    after: { allocatedQuantity: nextAllocated, allocationId: payload.allocationId },
  });
  return {
    licenceId: payload.licenceId,
    allocationId: payload.allocationId,
    allocatedQuantity: nextAllocated,
    availableQuantity: purchased - nextAllocated,
  };
}

async function saveReferenceRecord(context, collection, entityType) {
  const { db, fieldValue, transaction, actor, command } = context;
  const payload = command.payload;
  const ref = db.collection(collection).doc(payload.id);
  const snapshot = await transaction.get(ref);
  const current = snapshot.exists ? snapshot.data() || {} : null;
  requireExpectedRevision(current, payload.expectedRevision);
  const revision = current ? integer(current.revision) + 1 : 0;
  const timestamp = fieldValue.serverTimestamp();
  const document = {
    ...referenceRecordFields(entityType, payload),
    revision,
    updatedAt: timestamp,
    updatedBy: actor.uid,
  };
  if (current) {
    transaction.update(ref, document);
  } else {
    transaction.create(ref, {
      ...document,
      createdAt: timestamp,
      createdBy: actor.uid,
    });
  }
  writeAudit({
    ...context,
    parentRef: ref,
    entityType,
    entityId: payload.id,
    action: current ? 'updated' : 'created',
    before: current ? { revision: current.revision } : {},
    after: { revision },
  });
  return { id: payload.id, revision, created: !current };
}

async function saveContract(context) {
  const { db, transaction, command } = context;
  await requireReference(
    transaction,
    db.collection('suppliers').doc(command.payload.supplierId),
    'The contract supplier does not exist.',
  );
  return saveReferenceRecord(context, 'supplierContracts', 'supplier_contract');
}

async function saveWarranty(context) {
  const { db, transaction, command } = context;
  await requireReference(
    transaction,
    db.collection('suppliers').doc(command.payload.supplierId),
    'The warranty supplier does not exist.',
  );
  if (command.payload.contractId) {
    await requireReference(
      transaction,
      db.collection('supplierContracts').doc(command.payload.contractId),
      'The warranty contract does not exist.',
    );
  }
  return saveReferenceRecord(context, 'warranties', 'warranty');
}

async function recordWarrantyClaim(context) {
  const { db, fieldValue, transaction, actor, command, receiptId } = context;
  const payload = command.payload;
  const warrantyRef = db.collection('warranties').doc(payload.warrantyId);
  await Promise.all([
    requireReference(transaction, warrantyRef, 'The warranty does not exist.'),
    requireReference(
      transaction,
      db.collection('assets').doc(payload.assetId),
      'The claimed asset does not exist.',
    ),
  ]);
  const claimRef = warrantyRef.collection('claims').doc(payload.claimId);
  const timestamp = fieldValue.serverTimestamp();
  transaction.create(claimRef, {
    ...payload,
    status: 'submitted',
    revision: 0,
    actor: actorMap(actor),
    createdAt: timestamp,
    updatedAt: timestamp,
    correlationId: command.idempotencyKey,
  });
  transaction.create(claimRef.collection('history').doc(`history_${receiptId}`), {
    action: 'submitted',
    fromStatus: null,
    toStatus: 'submitted',
    actor: actorMap(actor),
    occurredAt: timestamp,
  });
  writeAudit({
    ...context,
    parentRef: warrantyRef,
    entityType: 'warranty_claim',
    entityId: payload.claimId,
    action: 'submitted',
    after: { status: 'submitted', assetId: payload.assetId },
  });
  return { warrantyId: payload.warrantyId, claimId: payload.claimId, status: 'submitted' };
}

async function transitionWarrantyClaim(context) {
  const { db, fieldValue, transaction, actor, command, receiptId } = context;
  const payload = command.payload;
  const warrantyRef = db.collection('warranties').doc(payload.warrantyId);
  const claimRef = warrantyRef.collection('claims').doc(payload.claimId);
  const snapshot = await transaction.get(claimRef);
  const claim = requireDocument(snapshot, 'The warranty claim does not exist.');
  requireRevision(claim, payload.expectedRevision);
  const fromStatus = normalizeString(claim.status).toLowerCase();
  const allowed = CLAIM_TRANSITIONS[fromStatus] || [];
  if (!CLAIM_STATUSES.includes(payload.toStatus) || !allowed.includes(payload.toStatus)) {
    throw failed(`Warranty claim cannot transition from ${fromStatus} to ${payload.toStatus}.`);
  }
  const timestamp = fieldValue.serverTimestamp();
  const revision = payload.expectedRevision + 1;
  transaction.update(claimRef, {
    status: payload.toStatus,
    revision,
    transitionReason: payload.reason,
    evidence: payload.evidence,
    updatedAt: timestamp,
    updatedBy: actor.uid,
  });
  transaction.create(claimRef.collection('history').doc(`history_${receiptId}`), {
    action: 'status_transitioned',
    fromStatus,
    toStatus: payload.toStatus,
    reason: payload.reason,
    evidence: payload.evidence,
    actor: actorMap(actor),
    occurredAt: timestamp,
  });
  writeAudit({
    ...context,
    parentRef: warrantyRef,
    entityType: 'warranty_claim',
    entityId: payload.claimId,
    action: 'status_transitioned',
    before: { status: fromStatus, revision: payload.expectedRevision },
    after: { status: payload.toStatus, revision },
  });
  return {
    warrantyId: payload.warrantyId,
    claimId: payload.claimId,
    status: payload.toStatus,
    revision,
  };
}

async function saveConfigurationItem(context) {
  const { db, fieldValue, transaction, actor, command, receiptId } = context;
  const payload = command.payload;
  const owner = payload.ownerUserId
    ? await resolveActiveAgent(transaction, db, payload.ownerUserId, 'CI owner')
    : null;
  if (payload.linkedAssetId) {
    await requireReference(
      transaction,
      db.collection('assets').doc(payload.linkedAssetId),
      'The linked asset does not exist.',
    );
  }
  const ref = db.collection('configurationItems').doc(payload.ciId);
  const snapshot = await transaction.get(ref);
  const current = snapshot.exists ? snapshot.data() || {} : null;
  requireExpectedRevision(current, payload.expectedRevision);
  const revision = current ? integer(current.revision) + 1 : 0;
  const timestamp = fieldValue.serverTimestamp();
  const document = {
    ...withoutEmpty(payload, ['ciId', 'expectedRevision']),
    ownerName: owner
      ? authoritativeAgentName(owner, payload.ownerUserId)
      : null,
    ownerEmail: owner ? authoritativeAgentEmail(owner) || null : null,
    revision,
    updatedAt: timestamp,
    updatedBy: actor.uid,
  };
  if (current) {
    transaction.update(ref, document);
  } else {
    transaction.create(ref, {
      ...document,
      createdAt: timestamp,
      createdBy: actor.uid,
    });
  }
  transaction.create(ref.collection('history').doc(`history_${receiptId}`), {
    action: current ? 'updated' : 'created',
    revision,
    before: current ? safeCiHistorySnapshot(current) : {},
    after: safeCiHistorySnapshot({ ...current, ...document }),
    actor: actorMap(actor),
    correlationId: command.idempotencyKey,
    occurredAt: timestamp,
  });
  writeAudit({
    ...context,
    parentRef: ref,
    entityType: 'configuration_item',
    entityId: payload.ciId,
    action: current ? 'updated' : 'created',
    before: current ? { revision: current.revision } : {},
    after: { revision, operationalStatus: payload.operationalStatus },
  });
  return { ciId: payload.ciId, revision, created: !current };
}

async function createCiRelationship(context) {
  const { db, fieldValue, transaction, actor, command } = context;
  const payload = command.payload;
  validateRelationshipDirection(payload);
  if (payload.sourceEntityType === payload.targetEntityType &&
      payload.sourceEntityId === payload.targetEntityId) {
    throw invalid('A relationship cannot reference the same source and target.');
  }
  const sourceRef = relationshipEntityReference(
    db,
    payload.sourceEntityType,
    payload.sourceEntityId,
  );
  const targetRef = relationshipEntityReference(
    db,
    payload.targetEntityType,
    payload.targetEntityId,
  );
  const relationshipKey = deterministicRelationshipKey(payload);
  const relationshipLockRef = db.collection('ciRelationshipKeys').doc(relationshipKey);
  const [sourceSnapshot, targetSnapshot, relationshipLockSnapshot] = await Promise.all([
    transaction.get(sourceRef),
    transaction.get(targetRef),
    transaction.get(relationshipLockRef),
  ]);
  const source = requireDocument(sourceSnapshot, 'The relationship source does not exist.');
  const target = requireDocument(targetSnapshot, 'The relationship target does not exist.');
  validateCiTypeDirection(payload.relationshipType, source, target);
  const existingRelationship = relationshipLockSnapshot.exists
    ? relationshipLockSnapshot.data() || {}
    : null;
  if (existingRelationship && existingRelationship.isActive !== false) {
    throw failed('An equivalent active CI relationship already exists.');
  }
  const ref = db.collection('ciRelationships').doc(payload.relationshipId);
  const timestamp = fieldValue.serverTimestamp();
  const relationshipLock = {
    relationshipKey,
    relationshipId: payload.relationshipId,
    relationshipType: payload.relationshipType,
    sourceEntityType: payload.sourceEntityType,
    sourceEntityId: payload.sourceEntityId,
    targetEntityType: payload.targetEntityType,
    targetEntityId: payload.targetEntityId,
    isActive: true,
    updatedAt: timestamp,
  };
  if (relationshipLockSnapshot.exists) {
    transaction.update(relationshipLockRef, relationshipLock);
  } else {
    transaction.create(relationshipLockRef, relationshipLock);
  }
  transaction.create(ref, {
    ...payload,
    relationshipKey,
    isActive: true,
    sourceName: normalizeString(source.name || source.assetTag),
    targetName: normalizeString(target.name || target.assetTag),
    createdAt: timestamp,
    createdBy: actor.uid,
    updatedAt: timestamp,
  });
  writeAudit({
    ...context,
    parentRef: ref,
    entityType: 'ci_relationship',
    entityId: payload.relationshipId,
    action: 'created',
    after: {
      relationshipType: payload.relationshipType,
      sourceEntityId: payload.sourceEntityId,
      targetEntityId: payload.targetEntityId,
    },
  });
  return { relationshipId: payload.relationshipId, isActive: true };
}

async function retireCiRelationship(context) {
  const { db, fieldValue, transaction, actor, command } = context;
  const payload = command.payload;
  const ref = db.collection('ciRelationships').doc(payload.relationshipId);
  const snapshot = await transaction.get(ref);
  const relationship = requireDocument(snapshot, 'The CI relationship does not exist.');
  if (relationship.isActive === false) throw failed('The CI relationship is already retired.');
  const relationshipKey = normalizeString(relationship.relationshipKey) ||
    deterministicRelationshipKey(relationship);
  const relationshipLockRef = db.collection('ciRelationshipKeys').doc(relationshipKey);
  const relationshipLockSnapshot = await transaction.get(relationshipLockRef);
  const timestamp = fieldValue.serverTimestamp();
  transaction.update(ref, {
    isActive: false,
    retirementReason: payload.reason,
    retiredAt: timestamp,
    retiredBy: actor.uid,
    updatedAt: timestamp,
  });
  if (relationshipLockSnapshot.exists) {
    transaction.update(relationshipLockRef, {
      isActive: false,
      retiredAt: timestamp,
      updatedAt: timestamp,
    });
  }
  writeAudit({
    ...context,
    parentRef: ref,
    entityType: 'ci_relationship',
    entityId: payload.relationshipId,
    action: 'retired',
    before: { isActive: true },
    after: { isActive: false },
  });
  return { relationshipId: payload.relationshipId, isActive: false };
}

async function resolveActiveAgent(transaction, db, userId, label) {
  const snapshot = await transaction.get(db.collection('agents').doc(userId));
  const agent = requireDocument(snapshot, `The ${label} does not exist.`);
  const status = normalizeString(agent.status).toLowerCase();
  if (agent.isActive === false || agent.disabled === true ||
      agent.accountDisabled === true || ['disabled', 'inactive'].includes(status)) {
    throw failed(`The ${label} is disabled.`);
  }
  return agent;
}

async function resolveStockSupportingDocument(
  transaction,
  db,
  stockItemId,
  candidate,
) {
  if (!candidate) return null;
  const attachmentId = normalizeString(candidate.attachmentId);
  if (!attachmentId) {
    throw invalid('The supporting document attachment ID is required.');
  }
  const snapshot = await transaction.get(
    db.collection('stockSupportingDocuments').doc(attachmentId),
  );
  const document = requireDocument(
    snapshot,
    'The registered stock supporting document does not exist.',
  );
  if (normalizeString(document.stockItemId) !== normalizeString(stockItemId)) {
    throw failed('The supporting document belongs to a different stock item.');
  }
  const storagePath = normalizeString(document.storagePath);
  const fileName = normalizeString(document.fileName);
  const contentType = normalizeString(document.contentType).toLowerCase();
  const sizeBytes = Number(document.sizeBytes);
  if (!storagePath || !fileName || !contentType ||
      !Number.isSafeInteger(sizeBytes) || sizeBytes <= 0) {
    throw failed('The registered supporting document metadata is incomplete.');
  }
  return {
    attachmentId,
    storagePath,
    fileName,
    contentType,
    sizeBytes,
    checksum: normalizeString(document.checksum) || null,
  };
}

async function resolveAllocatableAsset(transaction, db, assetId) {
  const snapshot = await transaction.get(db.collection('assets').doc(assetId));
  const asset = requireDocument(snapshot, 'The licence device does not exist.');
  const status = normalizeString(asset.status).toLowerCase();
  if (asset.isActive === false ||
      ['retired', 'disposed', 'lost', 'stolen'].includes(status)) {
    throw failed('The licence device is disabled or unavailable.');
  }
  return asset;
}

function authoritativeAgentName(agent, fallbackId) {
  const name = [agent.firstName, agent.name, agent.postName]
    .map(normalizeString)
    .filter(Boolean)
    .join(' ');
  return name || normalizeString(agent.displayName) || fallbackId;
}

function authoritativeAgentEmail(agent) {
  return normalizeString(agent.email).toLowerCase();
}

function authoritativeAssetName(asset, fallbackId) {
  return normalizeString(asset.name) || normalizeString(asset.assetTag) ||
    [asset.brand, asset.model].map(normalizeString).filter(Boolean).join(' ') ||
    fallbackId;
}

async function resolveProjectionWarranty(transaction, db, warrantyId) {
  const id = normalizeString(warrantyId);
  if (!id) return null;
  const snapshot = await transaction.get(db.collection('warranties').doc(id));
  if (!snapshot.exists) return null;
  const warranty = snapshot.data() || {};
  return {
    label: normalizeString(warranty.name || warranty.warrantyNumber),
    expiresAt: warranty.expirationDate || null,
  };
}

function writeSelfServiceProjection({
  db,
  fieldValue,
  transaction,
  asset,
  assignment,
  warranty,
  isCurrent,
}) {
  const assignedUserId = normalizeString(assignment.assignedUserId);
  if (!assignedUserId) return;
  const assetId = normalizeString(asset.assetId || asset.id) ||
    normalizeString(assignment.assetId);
  if (!assetId) throw failed('The self-service asset projection has no asset ID.');
  const projectionId = `${assignedUserId}_${assetId}`;
  const projection = {
    assetId,
    assetTag: normalizeString(asset.assetTag),
    name: authoritativeAssetName(asset, normalizeString(asset.assetTag) || assetId),
    categoryId: normalizeString(asset.categoryId),
    categoryName: normalizeString(asset.categoryName),
    type: normalizeString(asset.type),
    brand: normalizeString(asset.brand),
    model: normalizeString(asset.model),
    serialNumber: normalizeString(asset.serialNumber),
    status: normalizeString(asset.status),
    condition: normalizeString(asset.condition),
    locationId: normalizeString(asset.locationId),
    locationName: normalizeString(asset.locationName),
    photoUrl: normalizeString(asset.safePhotoUrl) || null,
    assignedUserId,
    assignedUserName: normalizeString(assignment.assignedUserName),
    assignmentId: normalizeString(assignment.assignmentId),
    assignedAt: assignment.assignedAt || null,
    warrantyLabel: warranty ? warranty.label : '',
    warrantyExpiresAt: warranty ? warranty.expiresAt : null,
    isCurrent: Boolean(isCurrent),
    updatedAt: fieldValue.serverTimestamp(),
  };
  transaction.set(
    db.collection('assetSelfServiceProjections').doc(projectionId),
    projection,
  );
}

function deterministicRelationshipKey(payload) {
  const canonical = [
    payload.relationshipType,
    payload.sourceEntityType,
    payload.sourceEntityId,
    payload.targetEntityType,
    payload.targetEntityId,
  ].map(normalizeString).join('|');
  return `relationship_${crypto.createHash('sha256').update(canonical).digest('hex')}`;
}

async function prepareAssetIdentifierChanges({
  transaction,
  db,
  assetId,
  current,
  next,
}) {
  const previous = new Map(
    assetIdentifierDefinitions(current || {}).map((entry) => [entry.key, entry]),
  );
  const desired = new Map(
    assetIdentifierDefinitions(next || {}).map((entry) => [entry.key, entry]),
  );
  const definitions = new Map([...previous, ...desired]);
  for (const entry of definitions.values()) {
    entry.reference = db.collection('assetIdentifierLocks').doc(entry.key);
  }
  const snapshots = new Map(await Promise.all(
    [...definitions.entries()].map(async ([key, entry]) => [
      key,
      await transaction.get(entry.reference),
    ]),
  ));
  const conflicts = await findAssetIdentifierConflicts({
    transaction,
    db,
    assetId,
    desired,
  });

  const claims = [];
  for (const [key, entry] of desired) {
    if (conflicts.has(key)) {
      throw alreadyExists(
        `Another asset already uses this ${entry.label}: ${entry.value}.`,
      );
    }
    const snapshot = snapshots.get(key);
    if (snapshot?.exists) {
      const ownerId = normalizeString((snapshot.data() || {}).assetId);
      if (ownerId !== assetId) {
        throw alreadyExists(
          `Another asset already uses this ${entry.label}: ${entry.value}.`,
        );
      }
    } else {
      claims.push(entry);
    }
  }

  const releases = [];
  for (const [key, entry] of previous) {
    if (desired.has(key)) continue;
    const snapshot = snapshots.get(key);
    if (snapshot?.exists &&
        normalizeString((snapshot.data() || {}).assetId) === assetId) {
      releases.push(entry);
    }
  }
  return { claims, releases };
}

async function findAssetIdentifierConflicts({
  transaction,
  db,
  assetId,
  desired,
}) {
  const results = await Promise.all(
    [...desired.entries()].map(async ([key, entry]) => {
      const normalizedQuery = db.collection('assets')
        .where(entry.normalizedField, '==', entry.normalizedValue)
        .limit(2);
      const legacyQuery = db.collection('assets')
        .where(entry.rawField, 'in', legacyAssetIdentifierVariants(entry.value))
        .limit(2);
      const [normalizedSnapshot, legacySnapshot] = await Promise.all([
        transaction.get(normalizedQuery),
        transaction.get(legacyQuery),
      ]);
      const hasConflict = [
        ...normalizedSnapshot.docs,
        ...legacySnapshot.docs,
      ].some((document) => document.id !== assetId);
      return [key, hasConflict];
    }),
  );
  return new Map(results.filter(([, hasConflict]) => hasConflict));
}

function applyAssetIdentifierChanges({
  transaction,
  fieldValue,
  assetId,
  changes,
}) {
  for (const entry of changes.claims) {
    transaction.create(entry.reference, {
      assetId,
      identifierType: entry.type,
      normalizedValue: entry.normalizedValue,
      createdAt: fieldValue.serverTimestamp(),
      updatedAt: fieldValue.serverTimestamp(),
    });
  }
  for (const entry of changes.releases) {
    transaction.delete(entry.reference);
  }
}

function assetIdentifierDefinitions(asset) {
  return [
    [
      'serial_number',
      'serial number',
      'serialNumber',
      'serialNumberNormalized',
      asset.serialNumber,
    ],
    [
      'product_number',
      'product number',
      'productNumber',
      'productNumberNormalized',
      asset.productNumber,
    ],
  ].flatMap(([type, label, rawField, normalizedField, rawValue]) => {
    const value = normalizeString(rawValue);
    const normalizedValue = normalizeAssetIdentifier(value);
    if (!normalizedValue) return [];
    const key = `asset_identifier_${crypto.createHash('sha256')
      .update(`${type}|${normalizedValue}`)
      .digest('hex')}`;
    return [{
      key,
      type,
      label,
      value,
      normalizedValue,
      rawField,
      normalizedField,
      reference: null,
    }];
  });
}

function legacyAssetIdentifierVariants(value) {
  return [...new Set([
    normalizeString(value),
    normalizeString(value).toLowerCase(),
    normalizeString(value).toUpperCase(),
  ])];
}

function normalizedAssetIdentifierFields(asset) {
  return {
    serialNumberNormalized: normalizeAssetIdentifier(asset.serialNumber),
    productNumberNormalized: normalizeAssetIdentifier(asset.productNumber),
  };
}

function normalizeAssetIdentifier(value) {
  return normalizeString(value).normalize('NFKC').toLowerCase();
}

function safeCiHistorySnapshot(ci) {
  return {
    name: normalizeString(ci.name),
    ciType: normalizeString(ci.ciType),
    ownerUserId: normalizeString(ci.ownerUserId) || null,
    supportGroupId: normalizeString(ci.supportGroupId) || null,
    criticality: normalizeString(ci.criticality),
    operationalStatus: normalizeString(ci.operationalStatus),
    linkedAssetId: normalizeString(ci.linkedAssetId) || null,
    configurationBaseline: clone(ci.configurationBaseline || {}),
    dataQualityStatus: normalizeString(ci.dataQualityStatus),
    revision: integer(ci.revision),
  };
}

function writeAssetLifecycleEvent({
  db,
  fieldValue,
  transaction,
  actor,
  command,
  receiptId,
  assetRef,
  fromStatus,
  toStatus,
  reason,
  relatedRequestId = '',
  evidence = [],
}) {
  const eventId = `lifecycle_${receiptId.substring(0, 32)}`;
  transaction.create(db.collection('assetLifecycleEvents').doc(eventId), {
    eventId,
    assetId: assetRef.id,
    fromStatus,
    toStatus,
    reason,
    relatedRequestId: relatedRequestId || null,
    evidence,
    actor: actorMap(actor),
    correlationId: command.idempotencyKey,
    occurredAt: fieldValue.serverTimestamp(),
  });
}

function writeAssetStateEvent({
  db,
  fieldValue,
  transaction,
  actor,
  command,
  receiptId,
  assetId,
  fromStateId,
  fromStateName,
  toStateId,
  toStateName,
  observation,
  revision,
}) {
  const eventId = `state_${receiptId.substring(0, 32)}`;
  transaction.create(db.collection('assetStateEvents').doc(eventId), {
    eventId,
    assetId,
    fromStateId: fromStateId || null,
    fromStateName: fromStateName || null,
    toStateId,
    toStateName,
    observation,
    revision,
    actor: actorMap(actor),
    correlationId: command.idempotencyKey,
    changedAt: fieldValue.serverTimestamp(),
  });
}

function writeLicenceHistory({
  fieldValue,
  transaction,
  actor,
  command,
  receiptId,
  licenceRef,
  action,
  before = {},
  after = {},
}) {
  transaction.create(licenceRef.collection('history').doc(`history_${receiptId}`), {
    action,
    before,
    after,
    actor: actorMap(actor),
    correlationId: command.idempotencyKey,
    occurredAt: fieldValue.serverTimestamp(),
  });
}

function writeAudit({
  db,
  fieldValue,
  transaction,
  actor,
  command,
  receiptId,
  parentRef,
  entityType,
  entityId,
  action,
  before = {},
  after = {},
}) {
  const auditId = `audit_${receiptId}`;
  const event = {
    eventType: `${entityType}.${action}`,
    action,
    entityType,
    entityId,
    actor: actorMap(actor),
    actorUserId: actor.uid,
    actorRole: actor.role,
    before,
    after,
    sourceCommand: command.command,
    sourceIdempotencyKey: command.idempotencyKey,
    correlationId: command.idempotencyKey,
    createdAt: fieldValue.serverTimestamp(),
  };
  transaction.create(parentRef.collection('auditLogs').doc(auditId), event);
  transaction.create(db.collection('itsmAuditEvents').doc(auditId), {
    ...event,
    sourcePath: parentRef.path,
  });
}

function validateAssetTransition(fromStatus, toStatus) {
  if (!ASSET_LIFECYCLE_STATES.includes(fromStatus)) {
    throw failed('The asset has an invalid lifecycle status.');
  }
  if (!(ASSET_TRANSITIONS[fromStatus] || []).includes(toStatus)) {
    throw failed(`Asset cannot transition from ${fromStatus} to ${toStatus}.`);
  }
}

function movementTypeFor(command) {
  return ({
    [ITSM_ASSETS_COMMANDS.receiveStock]: 'receipt',
    [ITSM_ASSETS_COMMANDS.reserveStock]: 'reservation',
    [ITSM_ASSETS_COMMANDS.issueStock]: 'issue',
    [ITSM_ASSETS_COMMANDS.returnStock]: 'return',
    [ITSM_ASSETS_COMMANDS.transferStock]: 'transfer',
    [ITSM_ASSETS_COMMANDS.adjustStock]: 'adjustment',
    [ITSM_ASSETS_COMMANDS.reconcileStock]: 'reconciliation',
  })[command];
}

function normalizeBalances(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return {};
  return Object.fromEntries(Object.entries(value).map(([locationId, balance]) => [
    locationId,
    {
      onHand: integer(balance && balance.onHand),
      reserved: integer(balance && balance.reserved),
    },
  ]));
}

function balanceAt(balances, locationId) {
  if (!balances[locationId]) balances[locationId] = { onHand: 0, reserved: 0 };
  return balances[locationId];
}

function validateBalances(balances) {
  for (const [locationId, balance] of Object.entries(balances)) {
    if (!Number.isSafeInteger(balance.onHand) ||
        !Number.isSafeInteger(balance.reserved) ||
        balance.onHand < 0 || balance.reserved < 0 ||
        balance.reserved > balance.onHand) {
      throw failed(`Stock balance at ${locationId} would become inconsistent.`);
    }
  }
}

function stockTotals(balances) {
  return Object.values(balances).reduce(
    (totals, balance) => ({
      onHand: totals.onHand + balance.onHand,
      reserved: totals.reserved + balance.reserved,
      available: totals.available + balance.onHand - balance.reserved,
    }),
    { onHand: 0, reserved: 0, available: 0 },
  );
}

function requireAvailable(balance, quantity) {
  if (!balance || balance.onHand - balance.reserved < quantity) {
    throw failed('There is not enough available stock for this movement.');
  }
}

function validateRelationshipDirection(payload) {
  const constraint = RELATIONSHIP_CONSTRAINTS[payload.relationshipType];
  if (!constraint ||
      !constraint.source.includes(payload.sourceEntityType) ||
      !constraint.target.includes(payload.targetEntityType)) {
    throw failed(
      `${payload.relationshipType} does not allow ${payload.sourceEntityType} ` +
      `to ${payload.targetEntityType}.`,
    );
  }
}

function validateCiTypeDirection(relationshipType, source, target) {
  if (relationshipType !== 'runs_on') return;
  const sourceTypes = ['application', 'service', 'software'];
  const targetTypes = ['server', 'virtual_machine', 'infrastructure', 'platform'];
  const sourceType = normalizeString(source.ciType).toLowerCase();
  const targetType = normalizeString(target.ciType).toLowerCase();
  if (!sourceTypes.includes(sourceType) || !targetTypes.includes(targetType)) {
    throw failed('runs_on must point from an application/service CI to a hosting CI.');
  }
}

function relationshipEntityReference(db, entityType, entityId) {
  const collection = ({
    configuration_item: 'configurationItems',
    asset: 'assets',
    service: 'itServices',
    user: 'agents',
  })[entityType];
  return db.collection(collection).doc(entityId);
}

async function requireReference(transaction, ref, message) {
  return requireDocument(await transaction.get(ref), message);
}

function requireExpectedRevision(current, expectedRevision) {
  if (!current) {
    if (expectedRevision !== null) {
      throw conflict('expectedRevision must be omitted when creating a record.');
    }
    return;
  }
  if (expectedRevision === null || integer(current.revision) !== expectedRevision) {
    throw conflict('The record changed after it was loaded. Refresh and try again.');
  }
}

function requireRevision(record, expectedRevision) {
  if (integer(record.revision) !== expectedRevision) {
    throw conflict('The record changed after it was loaded. Refresh and try again.');
  }
}

function requireDocument(snapshot, message) {
  if (!snapshot || !snapshot.exists) throw new ItsmCommandError('not-found', message);
  return snapshot.data() || {};
}

function requireManager(actor) {
  if (!actor || actor.role !== ITSM_ROLES.manager || !normalizeString(actor.uid)) {
    throw new ItsmCommandError(
      'permission-denied',
      'Only an ITSM MANAGER can perform asset and configuration operations.',
    );
  }
}

function actorMap(actor) {
  return {
    userId: actor.uid,
    name: actor.displayName || '',
    email: actor.email || '',
    role: actor.role,
  };
}

function clearedAssignment() {
  return {
    assignedUserId: null,
    assignedUserName: null,
    assignedUserEmail: null,
    assignedAt: null,
  };
}

function isInStockStatus(status) {
  return ['in_stock', 'configured'].includes(normalizeString(status).toLowerCase());
}

function assetSearchTokens(asset) {
  return [...new Set([
    asset.assetTag,
    asset.barcode,
    asset.categoryName,
    asset.type,
    asset.brand,
    asset.model,
    asset.serialNumber,
    asset.productNumber,
  ]
    .flatMap((value) => normalizeString(value).toLowerCase().split(/[^\p{L}\p{N}]+/u))
    .filter(Boolean))]
    .slice(0, 100);
}

function referenceRecordFields(entityType, payload) {
  const fields = withoutEmpty(payload, ['expectedRevision']);
  if (entityType === 'supplier_contract') {
    fields.startDate = firestoreDate(payload.startDate);
    fields.endDate = firestoreDate(payload.endDate);
    fields.renewalNoticeDate = firestoreDate(payload.renewalNoticeDate);
  } else if (entityType === 'warranty') {
    fields.startDate = firestoreDate(payload.startDate);
    fields.expirationDate = firestoreDate(payload.expirationDate);
  }
  return withoutEmpty(fields);
}

function firestoreDate(value) {
  if (!value) return null;
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) throw invalid('A persisted date is invalid.');
  return date;
}

function withoutEmpty(value, excluded = []) {
  return Object.fromEntries(Object.entries(value).filter(([key, entry]) =>
    !excluded.includes(key) && entry !== '' && entry !== undefined,
  ));
}

function projectFields(value, fields) {
  return Object.fromEntries(fields.filter((field) => field in value).map((field) => [
    field,
    value[field],
  ]));
}

function integer(value) {
  const number = Number(value);
  return Number.isSafeInteger(number) ? number : 0;
}

function clone(value) {
  return value === undefined ? undefined : structuredClone(value);
}

function invalid(message) {
  return new ItsmCommandError('invalid-argument', message);
}

function failed(message) {
  return new ItsmCommandError('failed-precondition', message);
}

function alreadyExists(message) {
  return new ItsmCommandError('already-exists', message);
}

function conflict(message) {
  return new ItsmCommandError('aborted', message);
}

module.exports = {
  ASSET_TRANSITIONS,
  CLAIM_TRANSITIONS,
  RELATIONSHIP_CONSTRAINTS,
  allocateLicence,
  assignAsset,
  createCiRelationship,
  executeAssetsCommand,
  moveStock,
  registerAsset,
  registerLicence,
  releaseLicence,
  returnAsset,
  saveConfigurationItem,
  saveAssetParameter,
  saveStockItem,
  saveStockLocation,
  transitionAsset,
  transitionWarrantyClaim,
};
