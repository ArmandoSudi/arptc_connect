'use strict';

const crypto = require('node:crypto');

async function synchronizeInventoryBalance({ db, fieldValue, event }) {
  const before = event.data?.before?.data() || null;
  const after = event.data?.after?.data() || null;
  const balanceId = event.params.balanceId;
  const source = after || before;
  if (!source || !source.itemId) return;

  const itemRef = db.collection('inventoryItems').doc(source.itemId);
  const projectionRef = db.collection('inventoryCatalogProjections').doc(source.itemId);
  const alertRef = db.collection('inventoryAlerts').doc(balanceId);
  const [itemSnapshot, balancesSnapshot, alertSnapshot] = await Promise.all([
    itemRef.get(),
    db.collection('inventoryBalances').where('itemId', '==', source.itemId).get(),
    alertRef.get(),
  ]);
  if (!itemSnapshot.exists) return;

  let totalAvailableMilli = 0;
  let totalThresholdMilli = 0;
  for (const balance of balancesSnapshot.docs) {
    const data = balance.data() || {};
    totalAvailableMilli += (data.onHandMilli || 0) - (data.reservedMilli || 0);
    totalThresholdMilli += data.thresholdMilli || 0;
  }
  const item = itemSnapshot.data() || {};
  const availability = totalAvailableMilli <= 0
    ? 'unavailable'
    : totalAvailableMilli <= totalThresholdMilli ? 'limited' : 'available';
  const batch = db.batch();
  batch.set(projectionRef, {
    sku: item.sku || '',
    name: item.name || '',
    nameLower: item.nameLower || '',
    description: item.description || '',
    categoryId: item.categoryId || '',
    categoryName: item.categoryName || '',
    unitOfMeasureName: item.unitOfMeasureName || '',
    imageUrl: item.imageUrl || '',
    isRequestable: item.isRequestable !== false,
    isActive: item.isActive !== false,
    availability,
    updatedAt: fieldValue.serverTimestamp(),
  }, { merge: true });

  if (after) {
    const beforeAvailable = before
      ? (before.onHandMilli || 0) - (before.reservedMilli || 0)
      : Number.MAX_SAFE_INTEGER;
    const afterAvailable = (after.onHandMilli || 0) - (after.reservedMilli || 0);
    const threshold = after.thresholdMilli || 0;
    const wasLow = beforeAvailable <= threshold;
    const isLow = afterAvailable <= threshold;
    const activeAlert = alertSnapshot.exists && alertSnapshot.data()?.isActive === true;
    if (isLow) {
      batch.set(alertRef, {
        balanceId,
        itemId: after.itemId,
        itemName: after.itemName || item.name || '',
        warehouseId: after.warehouseId || '',
        warehouseName: after.warehouseName || '',
        locationId: after.locationId || '',
        locationName: after.locationName || '',
        availableMilli: afterAvailable,
        thresholdMilli: threshold,
        isActive: true,
        updatedAt: fieldValue.serverTimestamp(),
        ...(!activeAlert ? {
          triggeredAt: fieldValue.serverTimestamp(),
          resolvedAt: null,
        } : {}),
      }, { merge: true });
      if (!wasLow && !activeAlert) {
        const notificationId = stableKey(`inventory-low-stock|${balanceId}|${event.id}`);
        batch.set(db.collection('notificationEvents').doc(notificationId), {
          eventType: 'inventory.low_stock',
          moduleKey: 'inventory',
          title: 'Low inventory stock',
          body: `${after.itemName || item.name} is below its threshold at ${after.locationName || 'its location'}.`,
          entityType: 'inventoryBalance',
          entityId: balanceId,
          route: `/service/inventory/items/${after.itemId}`,
          deepLink: `/service/inventory/items/${after.itemId}`,
          deduplicationId: notificationId,
          sourceEventId: event.id,
          createdByUserId: '',
          createdByName: 'Inventory system',
          createdByEmail: '',
          target: {
            type: 'MODULE_ROLE',
            moduleKey: 'inventory',
            roles: ['MANAGER'],
          },
          status: 'PENDING',
          createdAt: fieldValue.serverTimestamp(),
        });
      }
    } else if (activeAlert) {
      batch.set(alertRef, {
        isActive: false,
        availableMilli: afterAvailable,
        resolvedAt: fieldValue.serverTimestamp(),
        updatedAt: fieldValue.serverTimestamp(),
      }, { merge: true });
    }
  }
  await batch.commit();
}

async function rebuildInventoryDashboardSnapshots({ db, fieldValue }) {
  const [requests, balances, movements] = await Promise.all([
    db.collection('materialRequests')
      .orderBy('updatedAt', 'desc')
      .limit(2000)
      .get(),
    db.collection('inventoryBalances')
      .orderBy('updatedAt', 'desc')
      .limit(2000)
      .get(),
    db.collection('inventoryStockMovements')
      .orderBy('createdAt', 'desc')
      .limit(2000)
      .get(),
  ]);
  const statusCounts = {};
  const requestDepartments = new Map();
  const consumptionByDepartment = {};
  const topRequestedItems = {};
  const issuesVsReceipts = { Receipts: 0, Issues: 0 };
  const fulfillmentDurations = [];
  const now = new Date();
  const startToday = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());
  const monthKeys = lastUtcMonthKeys(now, 6);
  const monthlyFulfillmentTrend = Object.fromEntries(monthKeys.map((key) => [key, 0]));
  let fulfilledTodayCount = 0;
  for (const snapshot of requests.docs) {
    const request = snapshot.data() || {};
    requestDepartments.set(
      snapshot.id,
      request.requestedFor?.departmentName || 'Unassigned',
    );
    statusCounts[request.status || 'submitted'] =
      (statusCounts[request.status || 'submitted'] || 0) + 1;
    const submittedAt = toDate(request.submittedAt);
    const fulfilledAt = toDate(request.fulfilledAt);
    if (fulfilledAt && fulfilledAt.getTime() >= startToday) fulfilledTodayCount += 1;
    if (submittedAt && fulfilledAt) {
      fulfillmentDurations.push((fulfilledAt - submittedAt) / 60000);
      const monthKey = utcMonthKey(fulfilledAt);
      if (Object.hasOwn(monthlyFulfillmentTrend, monthKey)) {
        monthlyFulfillmentTrend[monthKey] += 1;
      }
    }
  }
  let lowStockCount = 0;
  let outOfStockCount = 0;
  const lowByWarehouse = {};
  for (const snapshot of balances.docs) {
    const balance = snapshot.data() || {};
    const available = (balance.onHandMilli || 0) - (balance.reservedMilli || 0);
    if (available <= (balance.thresholdMilli || 0)) {
      lowStockCount += 1;
      const warehouse = balance.warehouseName || 'Unassigned';
      lowByWarehouse[warehouse] = (lowByWarehouse[warehouse] || 0) + 1;
    }
    if (available <= 0) outOfStockCount += 1;
  }
  for (const snapshot of movements.docs) {
    const movement = snapshot.data() || {};
    const quantity = Math.abs(Number(movement.quantityMilli) || 0) / 1000;
    if (movement.type === 'receipt' || movement.type === 'opening_balance') {
      issuesVsReceipts.Receipts += quantity;
    }
    if (movement.type === 'issue') {
      issuesVsReceipts.Issues += quantity;
      const item = movement.itemName || 'Unassigned';
      topRequestedItems[item] = (topRequestedItems[item] || 0) + quantity;
      const department = requestDepartments.get(movement.relatedRequestId) || 'Unassigned';
      consumptionByDepartment[department] =
        (consumptionByDepartment[department] || 0) + quantity;
    }
  }
  const snapshot = {
    submittedCount: statusCounts.submitted || 0,
    underReviewCount: statusCounts.under_review || 0,
    readyForIssueCount: statusCounts.ready_for_issue || 0,
    partiallyFulfilledCount: statusCounts.partially_fulfilled || 0,
    lowStockCount,
    outOfStockCount,
    fulfilledTodayCount,
    averageFulfillmentMinutes: fulfillmentDurations.length
      ? fulfillmentDurations.reduce((sum, value) => sum + value, 0) /
        fulfillmentDurations.length
      : 0,
    requestsByStatus: statusCounts,
    topRequestedItems: topEntries(topRequestedItems, 10),
    consumptionByDepartment: topEntries(consumptionByDepartment, 10),
    issuesVsReceipts,
    lowStockByWarehouse: lowByWarehouse,
    monthlyFulfillmentTrend,
    recentMovementIds: movements.docs.slice(0, 100).map((entry) => entry.id),
    updatedAt: fieldValue.serverTimestamp(),
  };
  const batch = db.batch();
  batch.set(db.collection('inventoryDashboardSnapshots').doc('manager'), snapshot);
  batch.set(db.collection('inventoryDashboardSnapshots').doc('admin'), snapshot);
  await batch.commit();
}

function lastUtcMonthKeys(date, count) {
  return Array.from({ length: count }, (_, index) => {
    const cursor = new Date(Date.UTC(
      date.getUTCFullYear(),
      date.getUTCMonth() - (count - index - 1),
      1,
    ));
    return utcMonthKey(cursor);
  });
}

function utcMonthKey(date) {
  return `${date.getUTCFullYear()}-${String(date.getUTCMonth() + 1).padStart(2, '0')}`;
}

function topEntries(values, limit) {
  return Object.fromEntries(
    Object.entries(values)
      .sort((left, right) => right[1] - left[1])
      .slice(0, limit),
  );
}

function toDate(value) {
  if (value && typeof value.toDate === 'function') return value.toDate();
  if (value instanceof Date) return value;
  return null;
}

function stableKey(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

module.exports = {
  lastUtcMonthKeys,
  rebuildInventoryDashboardSnapshots,
  synchronizeInventoryBalance,
  topEntries,
};
