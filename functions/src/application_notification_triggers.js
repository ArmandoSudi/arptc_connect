'use strict';

const crypto = require('node:crypto');
const { normalizeString } = require('./itsm_permissions');

function notificationEventsForNewsChange({
  postId,
  before,
  after,
  sourceEventId,
  fieldValue,
}) {
  const current = snapshotData(after);
  if (!current) return [];
  const previous = snapshotData(before);
  const status = normalizeString(current.status).toUpperCase();
  const previousStatus = normalizeString(previous && previous.status).toUpperCase();
  if (!status || status === previousStatus) return [];

  const common = {
    moduleKey: 'news',
    entityType: 'newsPost',
    entityId: postId,
    sourceEventId,
    fieldValue,
  };
  const title = normalizeString(current.title) || 'Company news';
  if (
    status === 'PENDING' &&
    (!previous || ['DRAFT', 'REJECTED'].includes(previousStatus))
  ) {
    return [buildApplicationNotificationEvent({
      ...common,
      eventKind: 'submitted_for_review',
      eventType: 'news.submitted_for_review',
      title: 'News post awaiting review',
      body: `${actorName(current, 'author')} submitted "${title}".`,
      route: `/service/news/review/${encodeURIComponent(postId)}`,
      actor: actorData(current, 'author'),
      target: {
        type: 'MODULE_ROLE',
        moduleKey: 'news',
        roles: ['REVIEWER'],
      },
    })];
  }

  if (status === 'ACCEPTED' && previousStatus === 'PENDING') {
    return [buildApplicationNotificationEvent({
      ...common,
      eventKind: 'accepted',
      eventType: 'news.accepted',
      title: 'News post accepted',
      body: `"${title}" was accepted and can now be published.`,
      route: `/service/news/edit/${encodeURIComponent(postId)}`,
      actor: actorData(current, 'reviewedBy'),
      target: userTarget(current.authorId, current.authorEmail),
    })];
  }

  if (status === 'REJECTED' && previousStatus === 'PENDING') {
    const comment = normalizeString(current.reviewComment);
    return [buildApplicationNotificationEvent({
      ...common,
      eventKind: 'rejected',
      eventType: 'news.rejected',
      title: 'News post rejected',
      body: comment || `"${title}" needs revision before publication.`,
      route: `/service/news/edit/${encodeURIComponent(postId)}`,
      actor: actorData(current, 'reviewedBy'),
      target: userTarget(current.authorId, current.authorEmail),
    })];
  }

  if (status === 'PUBLISHED' && previousStatus === 'ACCEPTED') {
    return [buildApplicationNotificationEvent({
      ...common,
      eventKind: 'published',
      eventType: 'news.published',
      title: 'New company news',
      body: title,
      route: `/home/news/${encodeURIComponent(postId)}`,
      actor: actorData(current, 'author'),
      target: { type: 'ALL' },
    })];
  }

  return [];
}

function notificationEventsForMeetingHallReservationChange({
  reservationId,
  before,
  after,
  sourceEventId,
  fieldValue,
}) {
  const current = snapshotData(after);
  if (!current) return [];
  const previous = snapshotData(before);
  const status = normalizeString(current.status).toUpperCase();
  const previousStatus = normalizeString(previous && previous.status).toUpperCase();
  const route = meetingHallRoute(current, reservationId);
  const common = {
    moduleKey: 'meetinghall',
    entityType: 'meetingHallReservation',
    entityId: reservationId,
    sourceEventId,
    fieldValue,
    route,
  };
  const reservationTitle = normalizeString(current.title) || 'Meeting hall';

  if (!previous && status === 'ON_HOLD') {
    return [buildApplicationNotificationEvent({
      ...common,
      eventKind: 'requested',
      eventType: 'meeting_hall.reservation_requested',
      title: 'Meeting hall reservation request',
      body: `${normalizeString(current.userName) || 'An agent'} requested ` +
        `"${reservationTitle}" on ${displayDate(current.startTime)}.`,
      actor: actorData(current, 'user'),
      target: {
        type: 'MODULE_ROLE',
        moduleKey: 'meetinghall',
        roles: ['MANAGER'],
      },
    })];
  }

  if (
    previous && status !== previousStatus &&
    ['ACCEPTED', 'REJECTED', 'CANCELLED'].includes(status)
  ) {
    const copy = meetingHallStatusCopy(current, status, reservationTitle);
    return [buildApplicationNotificationEvent({
      ...common,
      eventKind: `status:${status}`,
      eventType: `meeting_hall.reservation_${status.toLowerCase()}`,
      title: copy.title,
      body: copy.body,
      actor: actorData(current, 'lastActionBy'),
      target: userTarget(current.userId, current.userEmail),
    })];
  }

  return [];
}

async function writeApplicationNotificationEvents({ db, events }) {
  if (events.length === 0) return 0;
  const batch = db.batch();
  for (const event of events) {
    batch.set(
      db.collection('notificationEvents').doc(event.id),
      event.data,
      { merge: false },
    );
  }
  await batch.commit();
  return events.length;
}

function buildApplicationNotificationEvent({
  moduleKey,
  entityType,
  entityId,
  sourceEventId,
  eventKind,
  eventType,
  title,
  body,
  route,
  actor,
  target,
  fieldValue,
}) {
  const deduplicationId = deterministicId(
    'notification', moduleKey, entityType, entityId, eventKind, sourceEventId,
  );
  return {
    id: deduplicationId,
    data: {
      eventType,
      moduleKey,
      title,
      body,
      entityType,
      entityId,
      route,
      deepLink: route,
      deduplicationId,
      sourceEventId,
      createdByUserId: normalizeString(actor.userId),
      createdByName: normalizeString(actor.name),
      createdByEmail: normalizeString(actor.email).toLowerCase(),
      target,
      status: 'PENDING',
      createdAt: fieldValue.serverTimestamp(),
    },
  };
}

function meetingHallStatusCopy(current, status, title) {
  const reason = status === 'REJECTED'
    ? normalizeString(current.rejectionReason)
    : normalizeString(current.cancelReason);
  const suffix = reason ? ` Reason: ${reason}` : '';
  if (status === 'ACCEPTED') {
    return {
      title: 'Meeting hall reservation approved',
      body: `Your reservation "${title}" was approved.`,
    };
  }
  if (status === 'REJECTED') {
    return {
      title: 'Meeting hall reservation rejected',
      body: `Your reservation "${title}" was rejected.${suffix}`,
    };
  }
  return {
    title: 'Meeting hall reservation cancelled',
    body: `Your reservation "${title}" was cancelled.${suffix}`,
  };
}

function meetingHallRoute(data, reservationId) {
  const hallId = normalizeString(data.hallId);
  const date = isoDate(data.startTime);
  const query = new URLSearchParams({
    date,
    reservationId: normalizeString(reservationId),
  });
  return `/service/meeting-hall/${encodeURIComponent(hallId)}?${query}`;
}

function isoDate(value) {
  const date = toDate(value);
  if (!date) return '';
  return [
    date.getUTCFullYear().toString().padStart(4, '0'),
    (date.getUTCMonth() + 1).toString().padStart(2, '0'),
    date.getUTCDate().toString().padStart(2, '0'),
  ].join('-');
}

function displayDate(value) {
  const date = toDate(value);
  return date
    ? `${date.getUTCDate()}/${date.getUTCMonth() + 1}/${date.getUTCFullYear()}`
    : 'the selected date';
}

function toDate(value) {
  if (value && typeof value.toDate === 'function') return value.toDate();
  if (value instanceof Date) return value;
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function actorData(data, prefix) {
  return {
    userId: data[`${prefix}UserId`] || data[`${prefix}Id`],
    name: data[`${prefix}Name`],
    email: data[`${prefix}Email`],
  };
}

function actorName(data, prefix) {
  return normalizeString(actorData(data, prefix).name) || 'An agent';
}

function userTarget(userId, email) {
  const normalizedUserId = normalizeString(userId);
  const normalizedEmail = normalizeString(email).toLowerCase();
  return {
    type: 'USERS',
    userIds: normalizedUserId ? [normalizedUserId] : [],
    userEmails: normalizedEmail ? [normalizedEmail] : [],
  };
}

function snapshotData(snapshot) {
  if (!snapshot || snapshot.exists === false) return null;
  return typeof snapshot.data === 'function' ? snapshot.data() || {} : snapshot;
}

function deterministicId(...parts) {
  return crypto
    .createHash('sha256')
    .update(parts.map(normalizeString).join('\u0000'))
    .digest('hex');
}

module.exports = {
  notificationEventsForMeetingHallReservationChange,
  notificationEventsForNewsChange,
  writeApplicationNotificationEvents,
};
