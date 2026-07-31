const crypto = require('node:crypto');

function buildIdempotencyDocumentId(actorUid, command, idempotencyKey) {
  return crypto
    .createHash('sha256')
    .update(`${actorUid}\u0000${command}\u0000${idempotencyKey}`)
    .digest('hex');
}

async function runIdempotentCommand({
  db,
  fieldValue,
  actorUid,
  command,
  idempotencyKey,
  execute,
}) {
  const receiptId = buildIdempotencyDocumentId(
    actorUid,
    command,
    idempotencyKey,
  );
  const receiptRef = db.collection('itsmCommandReceipts').doc(receiptId);

  return db.runTransaction(async (transaction) => {
    const receiptSnapshot = await transaction.get(receiptRef);
    if (receiptSnapshot.exists) {
      return receiptSnapshot.get('result');
    }

    const result = await execute(transaction, receiptId);
    transaction.create(receiptRef, {
      actorUid,
      command,
      idempotencyKey,
      result,
      createdAt: fieldValue.serverTimestamp(),
    });
    return result;
  });
}

module.exports = {
  buildIdempotencyDocumentId,
  runIdempotentCommand,
};
