'use strict';

const crypto = require('node:crypto');

const INVENTORY_COMMANDS = Object.freeze({
  saveItem: 'inventorySaveItem',
  setItemActive: 'inventorySetItemActive',
  saveWarehouse: 'inventorySaveWarehouse',
  saveLocation: 'inventorySaveLocation',
  saveParameter: 'inventorySaveParameter',
  receiveStock: 'inventoryReceiveStock',
  returnStock: 'inventoryReturnStock',
  transferStock: 'inventoryTransferStock',
  adjustStock: 'inventoryAdjustStock',
  reconcileStock: 'inventoryReconcileStock',
  setBalanceThreshold: 'inventorySetBalanceThreshold',
  submitRequest: 'inventorySubmitRequest',
  startReview: 'inventoryStartReview',
  takeOverRequest: 'inventoryTakeOverRequest',
  adjustRequestLine: 'inventoryAdjustRequestLine',
  reserveRequestLine: 'inventoryReserveRequestLine',
  markRequestReady: 'inventoryMarkRequestReady',
  issueRequest: 'inventoryIssueRequest',
  closeShortfall: 'inventoryCloseShortfall',
  cancelRequest: 'inventoryCancelRequest',
  rejectRequest: 'inventoryRejectRequest',
  confirmReceipt: 'inventoryConfirmReceipt',
});

const MANAGER_COMMANDS = new Set([
  INVENTORY_COMMANDS.saveItem,
  INVENTORY_COMMANDS.setItemActive,
  INVENTORY_COMMANDS.saveWarehouse,
  INVENTORY_COMMANDS.saveLocation,
  INVENTORY_COMMANDS.saveParameter,
  INVENTORY_COMMANDS.receiveStock,
  INVENTORY_COMMANDS.returnStock,
  INVENTORY_COMMANDS.transferStock,
  INVENTORY_COMMANDS.adjustStock,
  INVENTORY_COMMANDS.reconcileStock,
  INVENTORY_COMMANDS.setBalanceThreshold,
  INVENTORY_COMMANDS.startReview,
  INVENTORY_COMMANDS.takeOverRequest,
  INVENTORY_COMMANDS.adjustRequestLine,
  INVENTORY_COMMANDS.reserveRequestLine,
  INVENTORY_COMMANDS.markRequestReady,
  INVENTORY_COMMANDS.issueRequest,
  INVENTORY_COMMANDS.closeShortfall,
  INVENTORY_COMMANDS.rejectRequest,
]);

const REQUEST_ACTIVE_STATUSES = new Set([
  'submitted',
  'under_review',
  'adjusted',
  'ready_for_issue',
  'partially_fulfilled',
]);

class InventoryCommandError extends Error {
  constructor(code, message, details) {
    super(message);
    this.name = 'InventoryCommandError';
    this.code = code;
    this.details = details;
  }
}

function createInventoryCallableHandler({
  expectedCommand,
  db,
  fieldValue,
  timestamp,
  HttpsError,
  logger,
}) {
  if (!Object.values(INVENTORY_COMMANDS).includes(expectedCommand)) {
    throw new Error(`Unknown Inventory command: ${expectedCommand}`);
  }
  return async (request) => {
    try {
      if (!request.auth || request.auth.token?.email_verified !== true) {
        throw new InventoryCommandError(
          'unauthenticated',
          'An authenticated and verified agent is required.',
        );
      }
      const agentSnapshot = await db.collection('agents').doc(request.auth.uid).get();
      if (!agentSnapshot.exists || agentSnapshot.data()?.isActive !== true) {
        throw new InventoryCommandError(
          'permission-denied',
          'An active agent profile is required.',
        );
      }
      const agent = agentSnapshot.data() || {};
      if (agent.mustChangePassword === true) {
        throw new InventoryCommandError(
          'failed-precondition',
          'Complete the initial password change before using Inventory.',
        );
      }
      const role = inventoryRole(agent);
      authorizeCommand(expectedCommand, role);
      const actor = actorFrom(request.auth, agent, role);
      return await executeInventoryCommand({
        command: expectedCommand,
        payload: request.data || {},
        actor,
        db,
        fieldValue,
        timestamp,
      });
    } catch (error) {
      if (error instanceof InventoryCommandError) {
        throw new HttpsError(error.code, error.message, error.details);
      }
      logger?.error('Unexpected Inventory command failure', {
        command: expectedCommand,
        error: error?.message || String(error),
        stack: error?.stack,
      });
      throw new HttpsError('internal', 'The Inventory operation failed.');
    }
  };
}

function inventoryRole(agent) {
  const permissions = isObject(agent.modulePermissions)
    ? agent.modulePermissions
    : {};
  return normalizeString(permissions.inventory || permissions.inventaire || 'NONE')
    .toUpperCase();
}

function authorizeCommand(command, role) {
  if (role === 'ADMIN' || role === 'NONE') {
    throw new InventoryCommandError(
      'permission-denied',
      role === 'ADMIN'
        ? 'Inventory ADMIN access is read-only.'
        : 'You do not have access to Inventory.',
    );
  }
  if (MANAGER_COMMANDS.has(command) && role !== 'MANAGER') {
    throw new InventoryCommandError(
      'permission-denied',
      'Only an Inventory MANAGER can perform this action.',
    );
  }
  if (command === INVENTORY_COMMANDS.submitRequest &&
      !['USER', 'MANAGER'].includes(role)) {
    throw new InventoryCommandError('permission-denied', 'Request access denied.');
  }
  if ([INVENTORY_COMMANDS.cancelRequest, INVENTORY_COMMANDS.confirmReceipt]
    .includes(command) && role !== 'USER') {
    throw new InventoryCommandError(
      'permission-denied',
      'Only the requested-for USER can perform this action.',
    );
  }
}

async function executeInventoryCommand(context) {
  const commandId = requiredText(context.payload.commandId, 'command ID');
  const handlers = {
    [INVENTORY_COMMANDS.saveItem]: saveItem,
    [INVENTORY_COMMANDS.setItemActive]: setItemActive,
    [INVENTORY_COMMANDS.saveWarehouse]: saveWarehouse,
    [INVENTORY_COMMANDS.saveLocation]: saveLocation,
    [INVENTORY_COMMANDS.saveParameter]: saveParameter,
    [INVENTORY_COMMANDS.receiveStock]: receiveStock,
    [INVENTORY_COMMANDS.returnStock]: returnStock,
    [INVENTORY_COMMANDS.transferStock]: transferStock,
    [INVENTORY_COMMANDS.adjustStock]: adjustStock,
    [INVENTORY_COMMANDS.reconcileStock]: reconcileStock,
    [INVENTORY_COMMANDS.setBalanceThreshold]: setBalanceThreshold,
    [INVENTORY_COMMANDS.submitRequest]: submitRequest,
    [INVENTORY_COMMANDS.startReview]: startReview,
    [INVENTORY_COMMANDS.takeOverRequest]: takeOverRequest,
    [INVENTORY_COMMANDS.adjustRequestLine]: adjustRequestLine,
    [INVENTORY_COMMANDS.reserveRequestLine]: reserveRequestLine,
    [INVENTORY_COMMANDS.markRequestReady]: markRequestReady,
    [INVENTORY_COMMANDS.issueRequest]: issueRequest,
    [INVENTORY_COMMANDS.closeShortfall]: closeShortfall,
    [INVENTORY_COMMANDS.cancelRequest]: cancelRequest,
    [INVENTORY_COMMANDS.rejectRequest]: rejectRequest,
    [INVENTORY_COMMANDS.confirmReceipt]: confirmReceipt,
  };
  return handlers[context.command]({ ...context, commandId });
}

async function saveItem(context) {
  const { db, payload, actor, fieldValue, command, commandId } = context;
  const itemId = normalizeString(payload.itemId) || db.collection('inventoryItems').doc().id;
  const itemRef = db.collection('inventoryItems').doc(itemId);
  const receiptRef = receiptReference(db, commandId);
  const sku = requiredText(payload.sku, 'SKU').toUpperCase();
  const skuLockRef = db.collection('inventoryItemSkuLocks').doc(stableKey(sku));
  const openingBalances = array(payload.openingBalances);
  if (openingBalances.length > 50) invalid('At most 50 opening balances are allowed.');
  requireUniqueIds(openingBalances, 'locationId', 'opening balance location');

  return db.runTransaction(async (transaction) => {
    const locationRefs = openingBalances.map((entry) =>
      db.collection('inventoryLocations').doc(requiredText(entry.locationId, 'location')),
    );
    const [receipt, existing, skuLock, ...locations] = await Promise.all([
      transaction.get(receiptRef),
      transaction.get(itemRef),
      transaction.get(skuLockRef),
      ...locationRefs.map((reference) => transaction.get(reference)),
    ]);
    const replay = replayReceipt(receipt, command, actor, payload);
    if (replay) return replay;
    if (skuLock.exists && normalizeString(skuLock.data()?.itemId) !== itemId) {
      throw new InventoryCommandError('already-exists', 'This item SKU already exists.');
    }
    if (existing.exists && openingBalances.length > 0) {
      invalid('Opening balances can only be recorded when creating an item.');
    }
    const previousSku = normalizeString(existing.data()?.sku).toUpperCase();
    const previousSkuLockRef = previousSku && previousSku !== sku
      ? db.collection('inventoryItemSkuLocks').doc(stableKey(previousSku))
      : null;
    const previousSkuLock = previousSkuLockRef
      ? await transaction.get(previousSkuLockRef)
      : null;
    locations.forEach((snapshot) => {
      if (!snapshot.exists || snapshot.data()?.isActive !== true) {
        throw new InventoryCommandError(
          'failed-precondition',
          'Every opening balance requires an active location.',
        );
      }
    });
    const now = fieldValue.serverTimestamp();
    const item = itemDocument(payload, existing.data(), actor, now);
    transaction.set(itemRef, item, { merge: true });
    transaction.set(skuLockRef, { itemId, sku, updatedAt: now }, { merge: true });
    if (previousSkuLockRef &&
        previousSkuLock?.exists &&
        normalizeString(previousSkuLock.data()?.itemId) === itemId) {
      transaction.delete(previousSkuLockRef);
    }
    for (let index = 0; index < openingBalances.length; index += 1) {
      const entry = openingBalances[index];
      const location = locations[index].data() || {};
      const quantity = positiveMilli(entry.quantityMilli, 'opening quantity', true);
      const threshold = nonNegativeMilli(entry.thresholdMilli, 'threshold');
      const balanceId = balanceDocumentId(itemId, locations[index].id);
      const balanceRef = db.collection('inventoryBalances').doc(balanceId);
      transaction.create(balanceRef, balanceDocument({
        itemId,
        itemName: item.name,
        locationId: locations[index].id,
        location,
        onHandMilli: quantity,
        reservedMilli: 0,
        thresholdMilli: threshold,
        now,
      }));
      writeMovement(transaction, context, {
        type: 'opening_balance',
        itemId,
        itemName: item.name,
        balanceId,
        locationId: locations[index].id,
        location,
        quantityMilli: quantity,
        beforeOnHandMilli: 0,
        afterOnHandMilli: quantity,
        beforeReservedMilli: 0,
        afterReservedMilli: 0,
        reason: normalizeString(entry.reason) || 'Opening balance',
      });
    }
    writeCatalogueProjection(transaction, db, itemId, item, {
      totalAvailableMilli: openingBalances.reduce(
        (total, entry) => total + nonNegativeMilli(entry.quantityMilli, 'quantity'),
        0,
      ),
      totalThresholdMilli: openingBalances.reduce(
        (total, entry) => total + nonNegativeMilli(entry.thresholdMilli, 'threshold'),
        0,
      ),
      now,
    });
    writeAudit(transaction, context, {
      action: existing.exists ? 'ITEM_UPDATED' : 'ITEM_CREATED',
      entityType: 'inventoryItem',
      entityId: itemId,
      before: existing.data() || null,
      after: item,
    });
    return writeReceipt(transaction, context, { entityId: itemId, itemId });
  });
}

async function setItemActive(context) {
  const { db, payload, fieldValue, command, commandId, actor } = context;
  const itemId = requiredText(payload.itemId, 'item');
  const itemRef = db.collection('inventoryItems').doc(itemId);
  const projectionRef = db.collection('inventoryCatalogProjections').doc(itemId);
  const receiptRef = receiptReference(db, commandId);
  return db.runTransaction(async (transaction) => {
    const [receipt, item, projection] = await Promise.all([
      transaction.get(receiptRef),
      transaction.get(itemRef),
      transaction.get(projectionRef),
    ]);
    const replay = replayReceipt(receipt, command, actor, payload);
    if (replay) return replay;
    requireDocument(item, 'Inventory item');
    const isActive = payload.isActive === true;
    const now = fieldValue.serverTimestamp();
    transaction.update(itemRef, { isActive, updatedAt: now, updatedBy: actor.userId });
    if (projection.exists) {
      transaction.update(projectionRef, { isActive, updatedAt: now });
    }
    writeAudit(transaction, context, {
      action: isActive ? 'ITEM_ACTIVATED' : 'ITEM_DEACTIVATED',
      entityType: 'inventoryItem',
      entityId: itemId,
      before: item.data(),
      after: { ...item.data(), isActive },
    });
    return writeReceipt(transaction, context, { entityId: itemId, itemId });
  });
}

async function saveWarehouse(context) {
  return saveNamedConfiguration(context, {
    collection: 'inventoryWarehouses',
    entityType: 'inventoryWarehouse',
    fields: ['code', 'name', 'address'],
    required: ['code', 'name'],
  });
}

async function saveLocation(context) {
  const warehouseId = requiredText(context.payload.warehouseId, 'warehouse');
  const warehouse = await context.db.collection('inventoryWarehouses').doc(warehouseId).get();
  requireDocument(warehouse, 'Warehouse');
  if (warehouse.data()?.isActive !== true) {
    throw new InventoryCommandError('failed-precondition', 'The warehouse is inactive.');
  }
  return saveNamedConfiguration(context, {
    collection: 'inventoryLocations',
    entityType: 'inventoryLocation',
    fields: ['code', 'name'],
    required: ['code', 'name'],
    extra: {
      warehouseId,
      warehouseName: normalizeString(warehouse.data()?.name),
    },
  });
}

async function saveParameter(context) {
  const allowed = new Set([
    'category', 'unit_of_measure', 'item_type', 'movement_reason',
    'adjustment_reason', 'rejection_reason', 'shortfall_reason',
  ]);
  const type = requiredText(context.payload.type, 'parameter type').toLowerCase();
  if (!allowed.has(type)) invalid('Unsupported Inventory parameter type.');
  return saveNamedConfiguration(context, {
    collection: 'inventoryParameters',
    entityType: 'inventoryParameter',
    fields: ['name'],
    required: ['name'],
    extra: { type },
  });
}

async function saveNamedConfiguration(context, definition) {
  const { db, payload, fieldValue, actor, command, commandId } = context;
  const entityId = normalizeString(payload.id) || db.collection(definition.collection).doc().id;
  const ref = db.collection(definition.collection).doc(entityId);
  const receiptRef = receiptReference(db, commandId);
  return db.runTransaction(async (transaction) => {
    const [receipt, existing] = await Promise.all([
      transaction.get(receiptRef),
      transaction.get(ref),
    ]);
    const replay = replayReceipt(receipt, command, actor, payload);
    if (replay) return replay;
    for (const field of definition.required) requiredText(payload[field], field);
    const now = fieldValue.serverTimestamp();
    const data = {
      ...definition.extra,
      ...Object.fromEntries(definition.fields.map((field) => [field, normalizeString(payload[field])])),
      nameLower: normalizeString(payload.name).toLowerCase(),
      isActive: payload.isActive !== false,
      updatedAt: now,
      updatedBy: actor.userId,
      ...(existing.exists ? {} : { createdAt: now, createdBy: actor.userId }),
    };
    transaction.set(ref, data, { merge: true });
    writeAudit(transaction, context, {
      action: existing.exists ? 'PARAMETER_UPDATED' : 'PARAMETER_CREATED',
      entityType: definition.entityType,
      entityId,
      before: existing.data() || null,
      after: data,
    });
    return writeReceipt(transaction, context, { entityId });
  });
}

async function receiveStock(context) {
  return mutateSingleBalance(context, {
    type: 'receipt',
    apply(balance, payload) {
      const quantity = positiveMilli(payload.quantityMilli, 'receipt quantity');
      return { onHandMilli: balance.onHandMilli + quantity, reservedMilli: balance.reservedMilli, quantity };
    },
    requireReason: false,
    requireReference: true,
  });
}

async function returnStock(context) {
  return mutateSingleBalance(context, {
    type: 'return_to_stock',
    apply(balance, payload) {
      const quantity = positiveMilli(payload.quantityMilli, 'return quantity');
      return { onHandMilli: balance.onHandMilli + quantity, reservedMilli: balance.reservedMilli, quantity };
    },
    requireReason: true,
  });
}

async function adjustStock(context) {
  return mutateSingleBalance(context, {
    type: 'adjustment',
    apply(balance, payload) {
      const delta = signedMilli(payload.quantityMilli, 'adjustment quantity');
      if (delta === 0) invalid('Adjustment quantity cannot be zero.');
      const onHandMilli = balance.onHandMilli + delta;
      ensureValidBalance(onHandMilli, balance.reservedMilli);
      return {
        onHandMilli,
        reservedMilli: balance.reservedMilli,
        quantity: Math.abs(delta),
        movementType: delta > 0 ? 'adjustment_increase' : 'adjustment_decrease',
      };
    },
    requireReason: true,
  });
}

async function reconcileStock(context) {
  return mutateSingleBalance(context, {
    type: 'reconciliation',
    apply(balance, payload) {
      const target = nonNegativeMilli(payload.targetOnHandMilli, 'physical count');
      ensureValidBalance(target, balance.reservedMilli);
      return {
        onHandMilli: target,
        reservedMilli: balance.reservedMilli,
        quantity: Math.abs(target - balance.onHandMilli),
      };
    },
    requireReason: true,
  });
}

async function setBalanceThreshold(context) {
  const { db, payload, fieldValue, actor, command, commandId } = context;
  const balanceId = requiredText(payload.balanceId, 'stock balance');
  const thresholdMilli = nonNegativeMilli(payload.thresholdMilli, 'threshold');
  const balanceRef = db.collection('inventoryBalances').doc(balanceId);
  const receiptRef = receiptReference(db, commandId);
  return db.runTransaction(async (transaction) => {
    const [receipt, balanceSnapshot] = await Promise.all([
      transaction.get(receiptRef),
      transaction.get(balanceRef),
    ]);
    const replay = replayReceipt(receipt, command, actor, payload);
    if (replay) return replay;
    const balance = normalizedBalance(balanceSnapshot);
    const itemRef = db.collection('inventoryItems').doc(balance.itemId);
    const balancesQuery = db.collection('inventoryBalances')
      .where('itemId', '==', balance.itemId);
    const [itemSnapshot, balances] = await Promise.all([
      transaction.get(itemRef),
      transaction.get(balancesQuery),
    ]);
    requireDocument(itemSnapshot, 'Inventory item');
    const now = fieldValue.serverTimestamp();
    const next = {
      onHandMilli: balance.onHandMilli,
      reservedMilli: balance.reservedMilli,
      thresholdMilli,
    };
    transaction.update(balanceRef, {
      thresholdMilli,
      isLowStock: balance.onHandMilli - balance.reservedMilli <= thresholdMilli,
      updatedAt: now,
    });
    updateLowStockAlert(transaction, context, balance, next, now);
    updateProjectionFromSnapshots(
      transaction,
      db,
      itemSnapshot,
      balances,
      balanceId,
      next,
      now,
    );
    writeAudit(transaction, context, {
      action: 'STOCK_THRESHOLD_CHANGED',
      entityType: 'inventoryBalance',
      entityId: balanceId,
      before: { thresholdMilli: balance.thresholdMilli },
      after: { thresholdMilli },
      reason: normalizeString(payload.reason),
    });
    return writeReceipt(transaction, context, {
      entityId: balanceId,
      balanceId,
    });
  });
}

async function mutateSingleBalance(context, operation) {
  const { db, payload, fieldValue, actor, command, commandId } = context;
  const balanceId = requiredText(payload.balanceId, 'stock balance');
  const balanceRef = db.collection('inventoryBalances').doc(balanceId);
  const receiptRef = receiptReference(db, commandId);
  return db.runTransaction(async (transaction) => {
    const [receipt, balanceSnapshot] = await Promise.all([
      transaction.get(receiptRef),
      transaction.get(balanceRef),
    ]);
    const replay = replayReceipt(receipt, command, actor, payload);
    if (replay) return replay;
    requireDocument(balanceSnapshot, 'Inventory balance');
    const balance = normalizedBalance(balanceSnapshot);
    if (operation.requireReason) requiredText(payload.reason, 'reason');
    if (operation.requireReference) requiredText(payload.reference, 'source or reference');
    const next = operation.apply(balance, payload);
    ensureValidBalance(next.onHandMilli, next.reservedMilli);
    const itemRef = db.collection('inventoryItems').doc(balance.itemId);
    const balancesQuery = db.collection('inventoryBalances').where('itemId', '==', balance.itemId);
    const [itemSnapshot, allBalances] = await Promise.all([
      transaction.get(itemRef),
      transaction.get(balancesQuery),
    ]);
    requireDocument(itemSnapshot, 'Inventory item');
    const now = fieldValue.serverTimestamp();
    transaction.update(
      balanceRef,
      balanceUpdate({ ...next, thresholdMilli: balance.thresholdMilli }, now),
    );
    const movementId = writeMovement(transaction, context, {
      type: next.movementType || operation.type,
      ...balance,
      quantityMilli: next.quantity,
      beforeOnHandMilli: balance.onHandMilli,
      afterOnHandMilli: next.onHandMilli,
      beforeReservedMilli: balance.reservedMilli,
      afterReservedMilli: next.reservedMilli,
      reason: normalizeString(payload.reason),
      reference: normalizeString(payload.reference),
    });
    updateLowStockAlert(transaction, context, balance, next, now);
    updateProjectionFromSnapshots(
      transaction,
      db,
      itemSnapshot,
      allBalances,
      balanceId,
      next,
      now,
    );
    writeAudit(transaction, context, {
      action: `STOCK_${(next.movementType || operation.type).toUpperCase()}`,
      entityType: 'inventoryBalance',
      entityId: balanceId,
      before: balanceSnapshot.data(),
      after: next,
      reason: normalizeString(payload.reason),
    });
    return writeReceipt(transaction, context, {
      entityId: balanceId,
      balanceId,
      movementId,
    });
  });
}

async function transferStock(context) {
  const { db, payload, fieldValue, actor, command, commandId } = context;
  const sourceId = requiredText(payload.sourceBalanceId, 'source balance');
  const destinationId = requiredText(payload.destinationBalanceId, 'destination balance');
  if (sourceId === destinationId) invalid('Source and destination must differ.');
  const quantity = positiveMilli(payload.quantityMilli, 'transfer quantity');
  const sourceRef = db.collection('inventoryBalances').doc(sourceId);
  const destinationRef = db.collection('inventoryBalances').doc(destinationId);
  const receiptRef = receiptReference(db, commandId);
  return db.runTransaction(async (transaction) => {
    const [receipt, sourceSnapshot, destinationSnapshot] = await Promise.all([
      transaction.get(receiptRef), transaction.get(sourceRef), transaction.get(destinationRef),
    ]);
    const replay = replayReceipt(receipt, command, actor, payload);
    if (replay) return replay;
    requireDocument(sourceSnapshot, 'Source balance');
    requireDocument(destinationSnapshot, 'Destination balance');
    const source = normalizedBalance(sourceSnapshot);
    const destination = normalizedBalance(destinationSnapshot);
    if (source.itemId !== destination.itemId) invalid('Transfers must use the same item.');
    const nextSource = { onHandMilli: source.onHandMilli - quantity, reservedMilli: source.reservedMilli };
    const nextDestination = { onHandMilli: destination.onHandMilli + quantity, reservedMilli: destination.reservedMilli };
    ensureValidBalance(nextSource.onHandMilli, nextSource.reservedMilli);
    ensureValidBalance(nextDestination.onHandMilli, nextDestination.reservedMilli);
    const itemRef = db.collection('inventoryItems').doc(source.itemId);
    const balancesQuery = db.collection('inventoryBalances').where('itemId', '==', source.itemId);
    const [itemSnapshot, balances] = await Promise.all([
      transaction.get(itemRef), transaction.get(balancesQuery),
    ]);
    const now = fieldValue.serverTimestamp();
    transaction.update(
      sourceRef,
      balanceUpdate(
        { ...nextSource, thresholdMilli: source.thresholdMilli },
        now,
      ),
    );
    transaction.update(
      destinationRef,
      balanceUpdate(
        { ...nextDestination, thresholdMilli: destination.thresholdMilli },
        now,
      ),
    );
    writeMovement(transaction, context, {
      type: 'transfer_out', ...source, quantityMilli: quantity,
      beforeOnHandMilli: source.onHandMilli, afterOnHandMilli: nextSource.onHandMilli,
      beforeReservedMilli: source.reservedMilli, afterReservedMilli: source.reservedMilli,
      reason: normalizeString(payload.reason),
    });
    writeMovement(transaction, context, {
      type: 'transfer_in', ...destination, quantityMilli: quantity,
      beforeOnHandMilli: destination.onHandMilli, afterOnHandMilli: nextDestination.onHandMilli,
      beforeReservedMilli: destination.reservedMilli, afterReservedMilli: destination.reservedMilli,
      reason: normalizeString(payload.reason),
    });
    updateLowStockAlert(transaction, context, source, nextSource, now);
    updateLowStockAlert(transaction, context, destination, nextDestination, now);
    const replacements = new Map([[sourceId, nextSource], [destinationId, nextDestination]]);
    updateProjectionWithReplacements(transaction, db, itemSnapshot, balances, replacements, now);
    writeAudit(transaction, context, {
      action: 'STOCK_TRANSFERRED', entityType: 'inventoryItem', entityId: source.itemId,
      reason: normalizeString(payload.reason),
      after: { sourceBalanceId: sourceId, destinationBalanceId: destinationId, quantityMilli: quantity },
    });
    return writeReceipt(transaction, context, { entityId: source.itemId, itemId: source.itemId });
  });
}

async function submitRequest(context) {
  const { db, payload, actor, fieldValue, timestamp, command, commandId } = context;
  const lines = array(payload.lines);
  if (lines.length < 1 || lines.length > 50) invalid('A request requires 1 to 50 items.');
  requireUniqueIds(lines, 'itemId', 'requested item');
  const requestedForId = actor.role === 'MANAGER'
    ? requiredText(payload.requestedForUserId, 'requested-for agent')
    : actor.userId;
  const requestedForRef = db.collection('agents').doc(requestedForId);
  const itemRefs = lines.map((line) =>
    db.collection('inventoryItems').doc(requiredText(line.itemId, 'item')),
  );
  const requestRef = db.collection('materialRequests').doc();
  const year = timestamp.now().toDate().getUTCFullYear();
  const counterRef = db.collection('inventoryCounters').doc(`materialRequests-${year}`);
  const receiptRef = receiptReference(db, commandId);
  return db.runTransaction(async (transaction) => {
    const [receipt, requestedForSnapshot, counter, ...items] = await Promise.all([
      transaction.get(receiptRef), transaction.get(requestedForRef), transaction.get(counterRef),
      ...itemRefs.map((ref) => transaction.get(ref)),
    ]);
    const replay = replayReceipt(receipt, command, actor, payload);
    if (replay) return replay;
    requireDocument(requestedForSnapshot, 'Requested-for agent');
    if (requestedForSnapshot.data()?.isActive !== true) invalid('The requested-for agent is inactive.');
    if (normalizeString(requestedForSnapshot.data()?.organizationId) !== actor.organizationId) {
      throw new InventoryCommandError(
        'permission-denied',
        'The requested-for agent must belong to your organization.',
      );
    }
    if (actor.role === 'MANAGER' &&
        inventoryRole(requestedForSnapshot.data() || {}) !== 'USER') {
      invalid('A manager can submit only for an active Inventory USER.');
    }
    items.forEach((item) => {
      requireDocument(item, 'Inventory item');
      if (item.data()?.isActive !== true || item.data()?.isRequestable !== true) {
        invalid('Every requested item must be active and requestable.');
      }
    });
    const sequence = (counter.data()?.value || 0) + 1;
    const requestNumber = `MAT-${year}-${String(sequence).padStart(6, '0')}`;
    const now = fieldValue.serverTimestamp();
    const requestedFor = actorSnapshot(requestedForId, requestedForSnapshot.data() || {});
    const parent = {
      requestNumber,
      status: 'submitted',
      submittedBy: actor,
      requestedFor,
      assignedManager: null,
      recipient: null,
      justification: normalizeString(payload.justification),
      deliveryDestination: requiredText(payload.deliveryDestination, 'delivery destination'),
      hasAdjustments: false,
      hasIssuedStock: false,
      lineCount: lines.length,
      rejectedReason: '',
      cancelledReason: '',
      shortfallReason: '',
      createdAt: now,
      updatedAt: now,
      submittedAt: now,
      fulfilledAt: null,
      confirmedAt: null,
    };
    transaction.create(requestRef, parent);
    transaction.set(counterRef, { value: sequence, updatedAt: now }, { merge: true });
    lines.forEach((line, index) => {
      const item = items[index].data() || {};
      const quantity = positiveMilli(line.quantityMilli, 'requested quantity');
      const lineRef = requestRef.collection('lines').doc();
      transaction.create(lineRef, {
        itemId: items[index].id,
        itemName: item.name,
        itemNameLower: normalizeString(item.name).toLowerCase(),
        unitOfMeasureName: item.unitOfMeasureName,
        status: 'requested',
        requestedMilli: quantity,
        approvedMilli: quantity,
        reservedMilli: 0,
        issuedMilli: 0,
        adjustmentReason: '',
        declineReason: '',
        createdAt: now,
        updatedAt: now,
      });
    });
    writeRequestAudit(transaction, context, requestRef, 'REQUEST_SUBMITTED', parent);
    writeAudit(transaction, context, {
      action: 'REQUEST_SUBMITTED', entityType: 'materialRequest', entityId: requestRef.id, after: parent,
    });
    writeNotification(transaction, context, {
      eventKind: 'submitted',
      eventType: 'inventory.request_submitted',
      entityType: 'materialRequest', entityId: requestRef.id,
      title: 'New material request',
      body: `${requestedFor.name} submitted ${requestNumber}.`,
      route: `/service/inventory/requests/${requestRef.id}`,
      target: { type: 'MODULE_ROLE', moduleKey: 'inventory', roles: ['MANAGER'] },
    });
    return writeReceipt(transaction, context, {
      entityId: requestRef.id, requestId: requestRef.id, requestNumber,
    });
  });
}

async function startReview(context) {
  return updateRequestState(context, {
    allowed: ['submitted'],
    nextStatus: 'under_review',
    action: 'REQUEST_REVIEW_STARTED',
    mutate(request, actor) {
      return { assignedManager: actor };
    },
  });
}

async function takeOverRequest(context) {
  requiredText(context.payload.reason, 'takeover reason');
  return updateRequestState(context, {
    allowed: [...REQUEST_ACTIVE_STATUSES],
    action: 'REQUEST_TAKEN_OVER',
    mutate(request, actor) {
      if (request.assignedManager?.userId === actor.userId) {
        invalid('This request is already assigned to you.');
      }
      return { assignedManager: actor };
    },
  });
}

async function adjustRequestLine(context) {
  const { db, payload, actor, fieldValue, command, commandId } = context;
  const requestId = requiredText(payload.requestId, 'request');
  const lineId = requiredText(payload.lineId, 'request line');
  const requestRef = db.collection('materialRequests').doc(requestId);
  const lineRef = requestRef.collection('lines').doc(lineId);
  const receiptRef = receiptReference(db, commandId);
  return db.runTransaction(async (transaction) => {
    const [receipt, requestSnapshot, lineSnapshot] = await Promise.all([
      transaction.get(receiptRef), transaction.get(requestRef), transaction.get(lineRef),
    ]);
    const replay = replayReceipt(receipt, command, actor, payload);
    if (replay) return replay;
    requireAssignedManager(requestSnapshot, actor, ['under_review', 'adjusted']);
    requireDocument(lineSnapshot, 'Request line');
    const requested = nonNegativeMilli(lineSnapshot.data()?.requestedMilli, 'requested quantity');
    const approved = nonNegativeMilli(payload.approvedMilli, 'approved quantity');
    if (approved > requested) invalid('Approved quantity cannot exceed requested quantity.');
    const reason = approved === requested ? normalizeString(payload.reason) : requiredText(payload.reason, 'adjustment reason');
    const now = fieldValue.serverTimestamp();
    const lineStatus = approved === 0 ? 'declined' : approved === requested ? 'approved' : 'adjusted';
    transaction.update(lineRef, {
      approvedMilli: approved,
      status: lineStatus,
      adjustmentReason: approved < requested ? reason : '',
      declineReason: approved === 0 ? reason : '',
      updatedAt: now,
    });
    transaction.update(requestRef, { status: 'adjusted', hasAdjustments: true, updatedAt: now });
    writeRequestAudit(transaction, context, requestRef, 'REQUEST_LINE_ADJUSTED', {
      lineId, requestedMilli: requested, approvedMilli: approved, reason,
    });
    writeAudit(transaction, context, {
      action: 'REQUEST_LINE_ADJUSTED', entityType: 'materialRequest', entityId: requestId,
      reason, after: { lineId, requestedMilli: requested, approvedMilli: approved },
    });
    const requestedFor = requestSnapshot.data()?.requestedFor || {};
    writeNotification(transaction, context, {
      eventKind: `adjusted:${lineId}:${approved}`,
      eventType: 'inventory.request_adjusted', entityType: 'materialRequest', entityId: requestId,
      title: 'Material request adjusted', body: reason,
      route: `/service/inventory/requests/${requestId}`,
      target: userTarget(requestedFor),
    });
    return writeReceipt(transaction, context, { entityId: requestId, requestId, lineId });
  });
}

async function reserveRequestLine(context) {
  const { db, payload, actor, fieldValue, command, commandId } = context;
  const requestId = requiredText(payload.requestId, 'request');
  const lineId = requiredText(payload.lineId, 'request line');
  const allocations = array(payload.allocations);
  if (allocations.length < 1 || allocations.length > 20) invalid('Provide 1 to 20 allocations.');
  requireUniqueIds(allocations, 'balanceId', 'allocation balance');
  const requestRef = db.collection('materialRequests').doc(requestId);
  const lineRef = requestRef.collection('lines').doc(lineId);
  const balanceRefs = allocations.map((allocation) =>
    db.collection('inventoryBalances').doc(requiredText(allocation.balanceId, 'balance')),
  );
  const receiptRef = receiptReference(db, commandId);
  return db.runTransaction(async (transaction) => {
    const [receipt, requestSnapshot, lineSnapshot, ...balanceSnapshots] = await Promise.all([
      transaction.get(receiptRef), transaction.get(requestRef), transaction.get(lineRef),
      ...balanceRefs.map((ref) => transaction.get(ref)),
    ]);
    const replay = replayReceipt(receipt, command, actor, payload);
    if (replay) return replay;
    requireAssignedManager(requestSnapshot, actor, ['under_review', 'adjusted']);
    requireDocument(lineSnapshot, 'Request line');
    const line = lineSnapshot.data() || {};
    if ((line.reservedMilli || 0) !== 0) invalid('This line is already reserved.');
    const approved = nonNegativeMilli(line.approvedMilli, 'approved quantity');
    if (approved === 0) invalid('A declined line cannot be reserved.');
    const quantities = allocations.map((allocation) =>
      positiveMilli(allocation.quantityMilli, 'reserved quantity'),
    );
    if (quantities.reduce((sum, value) => sum + value, 0) !== approved) {
      invalid('Allocation quantities must equal the approved quantity.');
    }
    const normalized = balanceSnapshots.map((snapshot) => {
      requireDocument(snapshot, 'Inventory balance');
      const balance = normalizedBalance(snapshot);
      if (balance.itemId !== line.itemId) invalid('Allocation item does not match the request line.');
      return balance;
    });
    normalized.forEach((balance, index) => {
      ensureValidBalance(balance.onHandMilli, balance.reservedMilli + quantities[index]);
    });
    const now = fieldValue.serverTimestamp();
    normalized.forEach((balance, index) => {
      const nextReserved = balance.reservedMilli + quantities[index];
      const next = {
        onHandMilli: balance.onHandMilli,
        reservedMilli: nextReserved,
        thresholdMilli: balance.thresholdMilli,
      };
      transaction.update(balanceRefs[index], balanceUpdate(next, now));
      const allocationRef = requestRef.collection('allocations').doc();
      transaction.create(allocationRef, {
        lineId, balanceId: balance.balanceId,
        warehouseId: balance.warehouseId, warehouseName: balance.warehouseName,
        locationId: balance.locationId, locationName: balance.locationName,
        reservedMilli: quantities[index], issuedMilli: 0, createdAt: now, updatedAt: now,
      });
      writeMovement(transaction, context, {
        type: 'reservation', ...balance, quantityMilli: quantities[index],
        beforeOnHandMilli: balance.onHandMilli, afterOnHandMilli: balance.onHandMilli,
        beforeReservedMilli: balance.reservedMilli, afterReservedMilli: nextReserved,
        relatedRequestId: requestId,
      });
      updateLowStockAlert(transaction, context, balance, next, now);
    });
    transaction.update(lineRef, { reservedMilli: approved, status: 'reserved', updatedAt: now });
    transaction.update(requestRef, { updatedAt: now });
    writeRequestAudit(transaction, context, requestRef, 'REQUEST_LINE_RESERVED', { lineId, approvedMilli: approved });
    writeAudit(transaction, context, {
      action: 'REQUEST_LINE_RESERVED', entityType: 'materialRequest', entityId: requestId,
      after: { lineId, approvedMilli: approved },
    });
    return writeReceipt(transaction, context, { entityId: requestId, requestId, lineId });
  });
}

async function markRequestReady(context) {
  const { db, payload, actor, fieldValue, command, commandId } = context;
  const requestId = requiredText(payload.requestId, 'request');
  const requestRef = db.collection('materialRequests').doc(requestId);
  const receiptRef = receiptReference(db, commandId);
  return db.runTransaction(async (transaction) => {
    const [receipt, requestSnapshot, lines] = await Promise.all([
      transaction.get(receiptRef), transaction.get(requestRef),
      transaction.get(requestRef.collection('lines')),
    ]);
    const replay = replayReceipt(receipt, command, actor, payload);
    if (replay) return replay;
    requireAssignedManager(requestSnapshot, actor, ['under_review', 'adjusted']);
    if (lines.empty) invalid('The request has no lines.');
    const unready = lines.docs.some((line) => {
      const data = line.data() || {};
      return (data.approvedMilli || 0) > 0 && (data.reservedMilli || 0) !== (data.approvedMilli || 0);
    });
    if (unready) invalid('Reserve every approved line before marking the request ready.');
    const now = fieldValue.serverTimestamp();
    transaction.update(requestRef, { status: 'ready_for_issue', updatedAt: now });
    writeRequestAudit(transaction, context, requestRef, 'REQUEST_READY_FOR_ISSUE', {});
    notifyRequester(transaction, context, requestSnapshot, 'ready', 'inventory.request_ready', 'Material request ready', 'Your requested items are ready for issue.');
    writeAudit(transaction, context, { action: 'REQUEST_READY_FOR_ISSUE', entityType: 'materialRequest', entityId: requestId });
    return writeReceipt(transaction, context, { entityId: requestId, requestId });
  });
}

async function issueRequest(context) {
  const { db, payload, actor, fieldValue, command, commandId } = context;
  const requestId = requiredText(payload.requestId, 'request');
  const issues = array(payload.issues);
  if (issues.length < 1 || issues.length > 50) invalid('Provide 1 to 50 issue allocations.');
  requireUniqueIds(issues, 'allocationId', 'issue allocation');
  const recipientId = requiredText(payload.recipientUserId, 'recipient');
  const requestRef = db.collection('materialRequests').doc(requestId);
  const allocationRefs = issues.map((issue) => requestRef.collection('allocations').doc(requiredText(issue.allocationId, 'allocation')));
  const recipientRef = db.collection('agents').doc(recipientId);
  const receiptRef = receiptReference(db, commandId);
  return db.runTransaction(async (transaction) => {
    const [receipt, requestSnapshot, recipientSnapshot, linesSnapshot, ...allocationSnapshots] = await Promise.all([
      transaction.get(receiptRef), transaction.get(requestRef), transaction.get(recipientRef),
      transaction.get(requestRef.collection('lines')),
      ...allocationRefs.map((ref) => transaction.get(ref)),
    ]);
    const replay = replayReceipt(receipt, command, actor, payload);
    if (replay) return replay;
    requireAssignedManager(requestSnapshot, actor, ['ready_for_issue', 'partially_fulfilled']);
    requireDocument(recipientSnapshot, 'Recipient agent');
    const recipientData = recipientSnapshot.data() || {};
    if (recipientData.isActive !== true) invalid('The recipient agent is inactive.');
    if (normalizeString(recipientData.organizationId) !== actor.organizationId) {
      throw new InventoryCommandError(
        'permission-denied',
        'The recipient agent must belong to your organization.',
      );
    }
    const allocationData = allocationSnapshots.map((snapshot) => {
      requireDocument(snapshot, 'Request allocation');
      return snapshot.data() || {};
    });
    const balanceRefs = allocationData.map((allocation) => db.collection('inventoryBalances').doc(allocation.balanceId));
    const balanceSnapshots = await Promise.all(balanceRefs.map((ref) => transaction.get(ref)));
    const quantities = issues.map((issue) => positiveMilli(issue.quantityMilli, 'issued quantity'));
    const lineChanges = new Map();
    const projectedBalances = new Map();
    const now = fieldValue.serverTimestamp();
    allocationData.forEach((allocation, index) => {
      const storedBalance = normalizedBalance(balanceSnapshots[index]);
      const projected = projectedBalances.get(storedBalance.balanceId);
      const balance = projected?.current || storedBalance;
      const remainingReserved = (allocation.reservedMilli || 0) - (allocation.issuedMilli || 0);
      if (quantities[index] > remainingReserved) invalid('Issue quantity exceeds the allocation reservation.');
      const next = {
        onHandMilli: balance.onHandMilli - quantities[index],
        reservedMilli: balance.reservedMilli - quantities[index],
      };
      ensureValidBalance(next.onHandMilli, next.reservedMilli);
      projectedBalances.set(storedBalance.balanceId, {
        original: projected?.original || storedBalance,
        current: { ...balance, ...next },
        ref: balanceRefs[index],
      });
      transaction.update(allocationRefs[index], {
        issuedMilli: (allocation.issuedMilli || 0) + quantities[index],
        updatedAt: now,
      });
      const current = lineChanges.get(allocation.lineId) || 0;
      lineChanges.set(allocation.lineId, current + quantities[index]);
      writeMovement(transaction, context, {
        type: 'issue', ...balance, quantityMilli: quantities[index],
        beforeOnHandMilli: balance.onHandMilli, afterOnHandMilli: next.onHandMilli,
        beforeReservedMilli: balance.reservedMilli, afterReservedMilli: next.reservedMilli,
        relatedRequestId: requestId,
      });
    });
    projectedBalances.forEach(({ original, current, ref }) => {
      transaction.update(
        ref,
        balanceUpdate(
          {
            onHandMilli: current.onHandMilli,
            reservedMilli: current.reservedMilli,
            thresholdMilli: current.thresholdMilli,
          },
          now,
        ),
      );
      updateLowStockAlert(transaction, context, original, current, now);
    });
    const lineById = new Map(linesSnapshot.docs.map((line) => [line.id, line]));
    const projectedLines = new Map(
      linesSnapshot.docs.map((line) => [line.id, { ...(line.data() || {}) }]),
    );
    lineChanges.forEach((issuedDelta, lineId) => {
      const line = lineById.get(lineId);
      requireDocument(line, 'Request line');
      const data = projectedLines.get(lineId) || {};
      const issuedMilli = (data.issuedMilli || 0) + issuedDelta;
      const reservedMilli = (data.reservedMilli || 0) - issuedDelta;
      transaction.update(line.ref, {
        issuedMilli, reservedMilli,
        status: issuedMilli >= (data.approvedMilli || 0) ? 'issued' : 'partially_fulfilled',
        updatedAt: now,
      });
      projectedLines.set(lineId, { ...data, issuedMilli, reservedMilli });
    });
    const allComplete = [...projectedLines.values()].every((data) => {
      return (data.approvedMilli || 0) === 0 || (data.issuedMilli || 0) >= (data.approvedMilli || 0);
    });
    const status = allComplete ? 'awaiting_confirmation' : 'partially_fulfilled';
    const recipient = actorSnapshot(recipientId, recipientData);
    transaction.update(requestRef, {
      status, recipient, hasIssuedStock: true, updatedAt: now,
      fulfilledAt: allComplete ? now : null,
    });
    writeRequestAudit(transaction, context, requestRef, 'REQUEST_ITEMS_ISSUED', { status, recipient });
    notifyRequester(
      transaction, context, requestSnapshot,
      status, `inventory.request_${status}`,
      allComplete ? 'Confirm material receipt' : 'Material request partially issued',
      allComplete ? 'Confirm that you received the issued items.' : 'Part of your request has been issued.',
    );
    writeAudit(transaction, context, { action: 'REQUEST_ITEMS_ISSUED', entityType: 'materialRequest', entityId: requestId, after: { status, recipient } });
    return writeReceipt(transaction, context, { entityId: requestId, requestId });
  });
}

async function closeShortfall(context) {
  const { db, payload, actor, fieldValue, command, commandId } = context;
  const reason = requiredText(payload.reason, 'shortfall reason');
  const requestId = requiredText(payload.requestId, 'request');
  const requestRef = db.collection('materialRequests').doc(requestId);
  const receiptRef = receiptReference(db, commandId);
  return db.runTransaction(async (transaction) => {
    const [receipt, requestSnapshot, lines, allocations] = await Promise.all([
      transaction.get(receiptRef), transaction.get(requestRef),
      transaction.get(requestRef.collection('lines')),
      transaction.get(requestRef.collection('allocations')),
    ]);
    const replay = replayReceipt(receipt, command, actor, payload);
    if (replay) return replay;
    requireAssignedManager(requestSnapshot, actor, ['partially_fulfilled']);
    const activeAllocations = allocations.docs.filter((doc) => {
      const data = doc.data() || {};
      return (data.reservedMilli || 0) > (data.issuedMilli || 0);
    });
    const balanceRefs = activeAllocations.map((doc) => db.collection('inventoryBalances').doc(doc.data().balanceId));
    const balances = await Promise.all(balanceRefs.map((ref) => transaction.get(ref)));
    const now = fieldValue.serverTimestamp();
    activeAllocations.forEach((allocationSnapshot, index) => {
      const allocation = allocationSnapshot.data() || {};
      const release = (allocation.reservedMilli || 0) - (allocation.issuedMilli || 0);
      const balance = normalizedBalance(balances[index]);
      const nextReserved = balance.reservedMilli - release;
      const next = {
        onHandMilli: balance.onHandMilli,
        reservedMilli: nextReserved,
        thresholdMilli: balance.thresholdMilli,
      };
      transaction.update(balanceRefs[index], balanceUpdate(next, now));
      transaction.update(allocationSnapshot.ref, { reservedMilli: allocation.issuedMilli || 0, updatedAt: now });
      writeMovement(transaction, context, {
        type: 'reservation_release', ...balance, quantityMilli: release,
        beforeOnHandMilli: balance.onHandMilli, afterOnHandMilli: balance.onHandMilli,
        beforeReservedMilli: balance.reservedMilli, afterReservedMilli: nextReserved,
        relatedRequestId: requestId, reason,
      });
      updateLowStockAlert(transaction, context, balance, next, now);
    });
    lines.docs.forEach((line) => {
      const data = line.data() || {};
      if ((data.issuedMilli || 0) < (data.approvedMilli || 0)) {
        transaction.update(line.ref, { status: 'closed_short', reservedMilli: 0, updatedAt: now });
      }
    });
    transaction.update(requestRef, {
      status: 'awaiting_confirmation', shortfallReason: reason, updatedAt: now, fulfilledAt: now,
    });
    writeRequestAudit(transaction, context, requestRef, 'REQUEST_SHORTFALL_CLOSED', { reason });
    notifyRequester(transaction, context, requestSnapshot, 'closed-short', 'inventory.request_awaiting_confirmation', 'Confirm material receipt', reason);
    writeAudit(transaction, context, { action: 'REQUEST_SHORTFALL_CLOSED', entityType: 'materialRequest', entityId: requestId, reason });
    return writeReceipt(transaction, context, { entityId: requestId, requestId });
  });
}

async function cancelRequest(context) {
  const { db, payload, actor, fieldValue, command, commandId } = context;
  const requestId = requiredText(payload.requestId, 'request');
  const requestRef = db.collection('materialRequests').doc(requestId);
  const receiptRef = receiptReference(db, commandId);
  return db.runTransaction(async (transaction) => {
    const [receipt, requestSnapshot, allocations, lines] = await Promise.all([
      transaction.get(receiptRef), transaction.get(requestRef),
      transaction.get(requestRef.collection('allocations')),
      transaction.get(requestRef.collection('lines')),
    ]);
    const replay = replayReceipt(receipt, command, actor, payload);
    if (replay) return replay;
    requireDocument(requestSnapshot, 'Material request');
    const request = requestSnapshot.data() || {};
    if (normalizeString(request.requestedFor?.userId) !== actor.userId) {
      throw new InventoryCommandError('permission-denied', 'You can only cancel your own request.');
    }
    if (request.hasIssuedStock === true || !REQUEST_ACTIVE_STATUSES.has(request.status)) {
      throw new InventoryCommandError('failed-precondition', 'This request can no longer be cancelled.');
    }
    const active = allocations.docs.filter((doc) => {
      const data = doc.data() || {};
      return (data.reservedMilli || 0) > (data.issuedMilli || 0);
    });
    const balanceRefs = active.map((doc) => db.collection('inventoryBalances').doc(doc.data().balanceId));
    const balances = await Promise.all(balanceRefs.map((ref) => transaction.get(ref)));
    const now = fieldValue.serverTimestamp();
    active.forEach((allocationSnapshot, index) => {
      const allocation = allocationSnapshot.data() || {};
      const release = (allocation.reservedMilli || 0) - (allocation.issuedMilli || 0);
      const balance = normalizedBalance(balances[index]);
      const nextReserved = balance.reservedMilli - release;
      const next = {
        onHandMilli: balance.onHandMilli,
        reservedMilli: nextReserved,
        thresholdMilli: balance.thresholdMilli,
      };
      transaction.update(balanceRefs[index], balanceUpdate(next, now));
      transaction.update(allocationSnapshot.ref, { reservedMilli: allocation.issuedMilli || 0, updatedAt: now });
      writeMovement(transaction, context, {
        type: 'reservation_release',
        ...balance,
        quantityMilli: release,
        beforeOnHandMilli: balance.onHandMilli,
        afterOnHandMilli: balance.onHandMilli,
        beforeReservedMilli: balance.reservedMilli,
        afterReservedMilli: nextReserved,
        relatedRequestId: requestId,
        reason: normalizeString(payload.reason) || 'Request cancelled',
      });
      updateLowStockAlert(transaction, context, balance, next, now);
    });
    lines.docs.forEach((line) => {
      const data = line.data() || {};
      transaction.update(line.ref, {
        reservedMilli: data.issuedMilli || 0,
        updatedAt: now,
      });
    });
    const reason = normalizeString(payload.reason);
    transaction.update(requestRef, { status: 'cancelled', cancelledReason: reason, updatedAt: now });
    writeRequestAudit(transaction, context, requestRef, 'REQUEST_CANCELLED', { reason });
    writeNotification(transaction, context, {
      eventKind: 'cancelled', eventType: 'inventory.request_cancelled',
      entityType: 'materialRequest', entityId: requestId,
      title: 'Material request cancelled', body: reason || request.requestNumber,
      route: `/service/inventory/requests/${requestId}`,
      target: { type: 'MODULE_ROLE', moduleKey: 'inventory', roles: ['MANAGER'] },
    });
    writeAudit(transaction, context, { action: 'REQUEST_CANCELLED', entityType: 'materialRequest', entityId: requestId, reason });
    return writeReceipt(transaction, context, { entityId: requestId, requestId });
  });
}

async function rejectRequest(context) {
  requiredText(context.payload.reason, 'rejection reason');
  return updateRequestState(context, {
    allowed: ['submitted', 'under_review', 'adjusted'],
    nextStatus: 'rejected', action: 'REQUEST_REJECTED',
    mutate(request, actor, payload) {
      return { rejectedReason: normalizeString(payload.reason), assignedManager: request.assignedManager || actor };
    },
    notify: { eventType: 'inventory.request_rejected', title: 'Material request rejected' },
  });
}

async function confirmReceipt(context) {
  const { db, payload, actor, fieldValue, command, commandId } = context;
  const requestId = requiredText(payload.requestId, 'request');
  const requestRef = db.collection('materialRequests').doc(requestId);
  const receiptRef = receiptReference(db, commandId);
  return db.runTransaction(async (transaction) => {
    const [receipt, requestSnapshot] = await Promise.all([
      transaction.get(receiptRef), transaction.get(requestRef),
    ]);
    const replay = replayReceipt(receipt, command, actor, payload);
    if (replay) return replay;
    requireDocument(requestSnapshot, 'Material request');
    const request = requestSnapshot.data() || {};
    if (request.status !== 'awaiting_confirmation') invalid('This request is not awaiting confirmation.');
    if (normalizeString(request.requestedFor?.userId) !== actor.userId) {
      throw new InventoryCommandError('permission-denied', 'Only the requested-for agent can confirm receipt.');
    }
    const finalStatus = normalizeString(request.shortfallReason) ? 'closed_short' : 'fulfilled';
    const now = fieldValue.serverTimestamp();
    transaction.update(requestRef, { status: finalStatus, confirmedAt: now, updatedAt: now });
    writeRequestAudit(transaction, context, requestRef, 'REQUEST_RECEIPT_CONFIRMED', { finalStatus });
    writeAudit(transaction, context, { action: 'REQUEST_RECEIPT_CONFIRMED', entityType: 'materialRequest', entityId: requestId, after: { finalStatus } });
    return writeReceipt(transaction, context, { entityId: requestId, requestId, status: finalStatus });
  });
}

async function updateRequestState(context, definition) {
  const { db, payload, actor, fieldValue, command, commandId } = context;
  const requestId = requiredText(payload.requestId, 'request');
  const requestRef = db.collection('materialRequests').doc(requestId);
  const receiptRef = receiptReference(db, commandId);
  return db.runTransaction(async (transaction) => {
    const [receipt, requestSnapshot] = await Promise.all([
      transaction.get(receiptRef), transaction.get(requestRef),
    ]);
    const replay = replayReceipt(receipt, command, actor, payload);
    if (replay) return replay;
    requireDocument(requestSnapshot, 'Material request');
    const request = requestSnapshot.data() || {};
    if (!definition.allowed.includes(request.status)) {
      throw new InventoryCommandError('failed-precondition', 'The request status does not allow this action.');
    }
    if (request.assignedManager?.userId &&
        request.assignedManager.userId !== actor.userId &&
        command !== INVENTORY_COMMANDS.takeOverRequest) {
      throw new InventoryCommandError('failed-precondition', 'This request is assigned to another manager.');
    }
    const changes = definition.mutate ? definition.mutate(request, actor, payload) : {};
    const nextStatus = definition.nextStatus || request.status;
    const now = fieldValue.serverTimestamp();
    transaction.update(requestRef, { ...changes, status: nextStatus, updatedAt: now });
    writeRequestAudit(transaction, context, requestRef, definition.action, { ...changes, status: nextStatus });
    writeAudit(transaction, context, { action: definition.action, entityType: 'materialRequest', entityId: requestId, reason: normalizeString(payload.reason), after: { ...changes, status: nextStatus } });
    if (definition.notify) {
      notifyRequester(transaction, context, requestSnapshot, nextStatus, definition.notify.eventType, definition.notify.title, normalizeString(payload.reason));
    }
    return writeReceipt(transaction, context, { entityId: requestId, requestId, status: nextStatus });
  });
}

function itemDocument(payload, existing, actor, now) {
  return {
    sku: requiredText(payload.sku, 'SKU').toUpperCase(),
    name: requiredText(payload.name, 'name'),
    nameLower: requiredText(payload.name, 'name').toLowerCase(),
    description: normalizeString(payload.description),
    categoryId: requiredText(payload.categoryId, 'category'),
    categoryName: requiredText(payload.categoryName, 'category name'),
    unitOfMeasureId: requiredText(payload.unitOfMeasureId, 'unit of measure'),
    unitOfMeasureName: requiredText(payload.unitOfMeasureName, 'unit of measure name'),
    itemTypeId: requiredText(payload.itemTypeId, 'item type'),
    itemTypeName: requiredText(payload.itemTypeName, 'item type name'),
    imageUrl: normalizeString(payload.imageUrl),
    isRequestable: typeof payload.isRequestable === 'boolean'
      ? payload.isRequestable
      : existing?.isRequestable !== false,
    isActive: typeof payload.isActive === 'boolean'
      ? payload.isActive
      : existing?.isActive !== false,
    updatedAt: now,
    updatedBy: actor.userId,
    ...(existing ? {} : { createdAt: now, createdBy: actor.userId }),
  };
}

function balanceDocument({ itemId, itemName, locationId, location, onHandMilli, reservedMilli, thresholdMilli, now }) {
  return {
    itemId, itemName, itemNameLower: normalizeString(itemName).toLowerCase(),
    warehouseId: normalizeString(location.warehouseId), warehouseName: normalizeString(location.warehouseName),
    locationId, locationName: normalizeString(location.name),
    onHandMilli, reservedMilli, availableMilli: onHandMilli - reservedMilli,
    thresholdMilli, isLowStock: onHandMilli - reservedMilli <= thresholdMilli,
    isOutOfStock: onHandMilli - reservedMilli <= 0,
    createdAt: now, updatedAt: now,
  };
}

function normalizedBalance(snapshot) {
  requireDocument(snapshot, 'Inventory balance');
  const data = snapshot.data() || {};
  return {
    balanceId: snapshot.id,
    itemId: normalizeString(data.itemId), itemName: normalizeString(data.itemName),
    warehouseId: normalizeString(data.warehouseId), warehouseName: normalizeString(data.warehouseName),
    locationId: normalizeString(data.locationId), locationName: normalizeString(data.locationName),
    onHandMilli: nonNegativeMilli(data.onHandMilli, 'on-hand quantity'),
    reservedMilli: nonNegativeMilli(data.reservedMilli, 'reserved quantity'),
    thresholdMilli: nonNegativeMilli(data.thresholdMilli, 'threshold'),
  };
}

function balanceUpdate(next, now) {
  return {
    onHandMilli: next.onHandMilli,
    reservedMilli: next.reservedMilli,
    availableMilli: next.onHandMilli - next.reservedMilli,
    isLowStock: next.onHandMilli - next.reservedMilli <= (next.thresholdMilli ?? Number.MIN_SAFE_INTEGER),
    isOutOfStock: next.onHandMilli - next.reservedMilli <= 0,
    updatedAt: now,
  };
}

function ensureValidBalance(onHandMilli, reservedMilli) {
  if (onHandMilli < 0) invalid('Stock on hand cannot become negative.');
  if (reservedMilli < 0) invalid('Reserved stock cannot become negative.');
  if (reservedMilli > onHandMilli) invalid('Reserved stock cannot exceed stock on hand.');
}

function writeMovement(transaction, context, movement) {
  const ref = context.db.collection('inventoryStockMovements').doc();
  transaction.create(ref, {
    movementNumber: `MOV-${ref.id.substring(0, 10).toUpperCase()}`,
    type: movement.type,
    itemId: movement.itemId,
    itemName: movement.itemName,
    balanceId: movement.balanceId || '',
    warehouseId: movement.warehouseId || normalizeString(movement.location?.warehouseId),
    warehouseName: movement.warehouseName || normalizeString(movement.location?.warehouseName),
    locationId: movement.locationId || '',
    locationName: movement.locationName || normalizeString(movement.location?.name),
    quantityMilli: movement.quantityMilli,
    beforeOnHandMilli: movement.beforeOnHandMilli,
    afterOnHandMilli: movement.afterOnHandMilli,
    beforeReservedMilli: movement.beforeReservedMilli,
    afterReservedMilli: movement.afterReservedMilli,
    relatedRequestId: movement.relatedRequestId || '',
    reason: movement.reason || '',
    reference: movement.reference || '',
    actor: context.actor,
    commandId: context.commandId,
    createdAt: context.fieldValue.serverTimestamp(),
  });
  return ref.id;
}

function updateLowStockAlert(transaction, context, balance, next, now) {
  const beforeAvailable = balance.onHandMilli - balance.reservedMilli;
  const afterAvailable = next.onHandMilli - next.reservedMilli;
  const threshold = balance.thresholdMilli;
  const alertRef = context.db.collection('inventoryAlerts').doc(balance.balanceId);
  if (beforeAvailable > threshold && afterAvailable <= threshold) {
    transaction.set(alertRef, {
      balanceId: balance.balanceId,
      itemId: balance.itemId, itemName: balance.itemName,
      warehouseId: balance.warehouseId, warehouseName: balance.warehouseName,
      locationId: balance.locationId, locationName: balance.locationName,
      availableMilli: afterAvailable, thresholdMilli: threshold,
      isActive: true, triggeredAt: now, resolvedAt: null, updatedAt: now,
    }, { merge: true });
    writeNotification(transaction, context, {
      eventKind: `low-stock:${balance.balanceId}`,
      eventType: 'inventory.low_stock', entityType: 'inventoryBalance', entityId: balance.balanceId,
      title: 'Low inventory stock',
      body: `${balance.itemName} is below its threshold at ${balance.locationName}.`,
      route: `/service/inventory/items/${balance.itemId}`,
      target: { type: 'MODULE_ROLE', moduleKey: 'inventory', roles: ['MANAGER'] },
    });
  } else if (beforeAvailable <= threshold && afterAvailable > threshold) {
    transaction.set(alertRef, { isActive: false, availableMilli: afterAvailable, resolvedAt: now, updatedAt: now }, { merge: true });
  } else if (afterAvailable <= threshold) {
    transaction.set(alertRef, { availableMilli: afterAvailable, updatedAt: now }, { merge: true });
  }
}

function updateProjectionFromSnapshots(transaction, db, itemSnapshot, balances, changedId, next, now) {
  updateProjectionWithReplacements(transaction, db, itemSnapshot, balances, new Map([[changedId, next]]), now);
}

function updateProjectionWithReplacements(transaction, db, itemSnapshot, balances, replacements, now) {
  requireDocument(itemSnapshot, 'Inventory item');
  let totalAvailableMilli = 0;
  let totalThresholdMilli = 0;
  balances.docs.forEach((snapshot) => {
    const data = snapshot.data() || {};
    const replacement = replacements.get(snapshot.id);
    totalAvailableMilli += replacement
      ? replacement.onHandMilli - replacement.reservedMilli
      : (data.onHandMilli || 0) - (data.reservedMilli || 0);
    totalThresholdMilli += replacement?.thresholdMilli ?? data.thresholdMilli ?? 0;
  });
  writeCatalogueProjection(transaction, db, itemSnapshot.id, itemSnapshot.data(), { totalAvailableMilli, totalThresholdMilli, now });
}

function writeCatalogueProjection(transaction, db, itemId, item, totals) {
  const availability = totals.totalAvailableMilli <= 0
    ? 'unavailable'
    : totals.totalAvailableMilli <= totals.totalThresholdMilli ? 'limited' : 'available';
  transaction.set(db.collection('inventoryCatalogProjections').doc(itemId), {
    sku: item.sku, name: item.name, nameLower: item.nameLower,
    description: item.description || '', categoryId: item.categoryId,
    categoryName: item.categoryName, unitOfMeasureName: item.unitOfMeasureName,
    imageUrl: item.imageUrl || '', isRequestable: item.isRequestable !== false,
    isActive: item.isActive !== false, availability, updatedAt: totals.now,
  }, { merge: true });
}

function requireAssignedManager(requestSnapshot, actor, allowedStatuses) {
  requireDocument(requestSnapshot, 'Material request');
  const request = requestSnapshot.data() || {};
  if (!allowedStatuses.includes(request.status)) {
    throw new InventoryCommandError('failed-precondition', 'The request status does not allow this action.');
  }
  if (normalizeString(request.assignedManager?.userId) !== actor.userId) {
    throw new InventoryCommandError('failed-precondition', 'This request is assigned to another manager.');
  }
}

function writeAudit(transaction, context, event) {
  const ref = context.db.collection('inventoryAuditEvents').doc();
  transaction.create(ref, {
    action: event.action, entityType: event.entityType, entityId: event.entityId,
    actor: context.actor, reason: event.reason || '',
    before: event.before || null, after: event.after || null,
    commandId: context.commandId, createdAt: context.fieldValue.serverTimestamp(),
  });
}

function writeRequestAudit(transaction, context, requestRef, action, details) {
  transaction.create(requestRef.collection('auditLogs').doc(), {
    action, actor: context.actor, details: details || {},
    commandId: context.commandId, createdAt: context.fieldValue.serverTimestamp(),
  });
}

function notifyRequester(transaction, context, requestSnapshot, eventKind, eventType, title, body) {
  const request = requestSnapshot.data() || {};
  writeNotification(transaction, context, {
    eventKind, eventType, entityType: 'materialRequest', entityId: requestSnapshot.id,
    title, body, route: `/service/inventory/requests/${requestSnapshot.id}`,
    target: userTarget(request.requestedFor || {}),
  });
}

function writeNotification(transaction, context, event) {
  const id = stableKey([
    'inventory', event.entityType, event.entityId, event.eventKind, context.commandId,
  ].join('|'));
  transaction.set(context.db.collection('notificationEvents').doc(id), {
    eventType: event.eventType, moduleKey: 'inventory',
    title: event.title, body: event.body || '',
    entityType: event.entityType, entityId: event.entityId,
    route: event.route, deepLink: event.route,
    deduplicationId: id, sourceEventId: context.commandId,
    createdByUserId: context.actor.userId,
    createdByName: context.actor.name,
    createdByEmail: context.actor.email,
    target: event.target, status: 'PENDING',
    createdAt: context.fieldValue.serverTimestamp(),
  }, { merge: false });
}

function userTarget(agent) {
  return { type: 'USER', userId: normalizeString(agent.userId), email: normalizeString(agent.email).toLowerCase() };
}

function actorFrom(auth, agent, role) {
  return { ...actorSnapshot(auth.uid, agent), role };
}

function actorSnapshot(userId, agent) {
  return {
    userId,
    name: [agent.firstName, agent.name, agent.postName].map(normalizeString).filter(Boolean).join(' ') || normalizeString(agent.displayName),
    email: normalizeString(agent.emailLower || agent.email).toLowerCase(),
    organizationId: normalizeString(agent.organizationId),
    departmentId: normalizeString(agent.departmentId), departmentName: normalizeString(agent.department),
    serviceId: normalizeString(agent.serviceId), serviceName: normalizeString(agent.service),
    bureauId: normalizeString(agent.bureauId), bureauName: normalizeString(agent.bureau),
  };
}

function receiptReference(db, commandId) {
  return db.collection('inventoryCommandReceipts').doc(commandId);
}

function replayReceipt(snapshot, command, actor, payload) {
  if (!snapshot.exists) return null;
  const data = snapshot.data() || {};
  if (data.command !== command || data.actorUserId !== actor.userId || data.payloadDigest !== payloadDigest(payload)) {
    throw new InventoryCommandError('already-exists', 'This command ID was already used for another operation.');
  }
  return { ...(data.result || {}), replayed: true };
}

function writeReceipt(transaction, context, result) {
  const response = { commandId: context.commandId, ...result, replayed: false };
  transaction.create(receiptReference(context.db, context.commandId), {
    command: context.command, actorUserId: context.actor.userId,
    payloadDigest: payloadDigest(context.payload), result: response,
    createdAt: context.fieldValue.serverTimestamp(),
  });
  return response;
}

function payloadDigest(payload) {
  return crypto.createHash('sha256').update(stableJson(payload)).digest('hex');
}

function stableJson(value) {
  if (Array.isArray(value)) return `[${value.map(stableJson).join(',')}]`;
  if (isObject(value)) {
    return `{${Object.keys(value).sort().map((key) => `${JSON.stringify(key)}:${stableJson(value[key])}`).join(',')}}`;
  }
  return JSON.stringify(value ?? null);
}

function stableKey(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

function balanceDocumentId(itemId, locationId) {
  return stableKey(`${itemId}|${locationId}`);
}

function requiredText(value, label) {
  const normalized = normalizeString(value);
  if (!normalized) invalid(`A valid ${label} is required.`);
  return normalized;
}

function signedMilli(value, label) {
  const number = Number(value);
  if (!Number.isSafeInteger(number)) invalid(`${label} must use integer thousandths.`);
  return number;
}

function nonNegativeMilli(value, label) {
  const number = signedMilli(value ?? 0, label);
  if (number < 0) invalid(`${label} cannot be negative.`);
  return number;
}

function positiveMilli(value, label, allowZero = false) {
  const number = nonNegativeMilli(value, label);
  if (allowZero ? number < 0 : number <= 0) invalid(`${label} must be greater than zero.`);
  return number;
}

function requireDocument(snapshot, label) {
  if (!snapshot || !snapshot.exists) {
    throw new InventoryCommandError('not-found', `${label} was not found.`);
  }
}

function invalid(message) {
  throw new InventoryCommandError('invalid-argument', message);
}

function normalizeString(value) {
  return value == null ? '' : String(value).trim();
}

function array(value) {
  return Array.isArray(value) ? value : [];
}

function requireUniqueIds(values, field, label) {
  const identifiers = values.map((value) => requiredText(value?.[field], label));
  if (new Set(identifiers).size !== identifiers.length) {
    invalid(`Each ${label} must be unique.`);
  }
}

function isObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

module.exports = {
  INVENTORY_COMMANDS,
  InventoryCommandError,
  authorizeCommand,
  balanceDocumentId,
  createInventoryCallableHandler,
  executeInventoryCommand,
  inventoryRole,
  payloadDigest,
};
