const DEFAULT_BATCH_SIZE = 200;

function buildArchivePatch(fieldValue) {
  const serverTimestamp = fieldValue.serverTimestamp();
  return {
    status: 'archived',
    lifecycleState: 'archived',
    archivedAt: serverTimestamp,
    updatedAt: serverTimestamp,
    lastStatusChangedAt: serverTimestamp,
  };
}

async function archiveEligibleIncidents({
  db,
  fieldValue,
  timestamp,
  now = new Date(),
  batchSize = DEFAULT_BATCH_SIZE,
  logger,
}) {
  let archivedCount = 0;

  while (true) {
    const snapshot = await db
      .collection('incidentTickets')
      .where('lifecycleState', '==', 'closed')
      .where('isDeleted', '==', false)
      .where('archiveEligibleAt', '<=', timestamp.fromDate(now))
      .orderBy('archiveEligibleAt')
      .limit(batchSize)
      .get();

    if (snapshot.empty) {
      break;
    }

    const batch = db.batch();
    const patch = buildArchivePatch(fieldValue);
    for (const document of snapshot.docs) {
      batch.update(document.ref, patch);
    }
    await batch.commit();
    archivedCount += snapshot.size;

    logger?.info('Archived eligible incident batch', {
      batchCount: snapshot.size,
      archivedCount,
    });

    if (snapshot.size < batchSize) {
      break;
    }
  }

  return archivedCount;
}

module.exports = {
  DEFAULT_BATCH_SIZE,
  archiveEligibleIncidents,
  buildArchivePatch,
};
