'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  notificationEventsForMeetingHallReservationChange,
  notificationEventsForNewsChange,
} = require('../src/application_notification_triggers');

const fieldValue = { serverTimestamp: () => 'server-time' };

test('news submission targets reviewers and trigger retries are deduplicated', () => {
  const input = {
    postId: 'post-1',
    before: snapshot({ status: 'DRAFT' }),
    after: snapshot({
      status: 'PENDING',
      title: 'Network maintenance',
      authorId: 'author-1',
      authorName: 'Alice Author',
      authorEmail: 'alice@example.com',
    }),
    sourceEventId: 'source-1',
    fieldValue,
  };
  const first = notificationEventsForNewsChange(input);
  const replay = notificationEventsForNewsChange(input);
  assert.equal(first.length, 1);
  assert.equal(first[0].id, replay[0].id);
  assert.deepEqual(first[0].data.target, {
    type: 'MODULE_ROLE',
    moduleKey: 'news',
    roles: ['REVIEWER'],
  });
  assert.equal(first[0].data.status, 'PENDING');
});

test('news review and publication transitions target the intended audiences', () => {
  const rejected = notificationEventsForNewsChange({
    postId: 'post-1',
    before: snapshot({ status: 'PENDING' }),
    after: snapshot({
      status: 'REJECTED',
      title: 'Draft announcement',
      reviewComment: 'Confirm the publication date.',
      authorId: 'author-1',
      authorEmail: 'author@example.com',
      reviewedByUserId: 'reviewer-1',
      reviewedByName: 'Rita Reviewer',
      reviewedByEmail: 'reviewer@example.com',
    }),
    sourceEventId: 'review-1',
    fieldValue,
  });
  assert.equal(rejected[0].data.body, 'Confirm the publication date.');
  assert.deepEqual(rejected[0].data.target.userIds, ['author-1']);
  assert.equal(rejected[0].data.createdByUserId, 'reviewer-1');

  const published = notificationEventsForNewsChange({
    postId: 'post-1',
    before: snapshot({ status: 'ACCEPTED' }),
    after: snapshot({
      status: 'PUBLISHED',
      title: 'Approved announcement',
      authorId: 'author-1',
      authorName: 'Alice Author',
      authorEmail: 'author@example.com',
    }),
    sourceEventId: 'publish-1',
    fieldValue,
  });
  assert.deepEqual(published[0].data.target, { type: 'ALL' });
  assert.equal(published[0].data.route, '/home/news/post-1');
});

test('reservation submission only notifies Meeting Hall managers', () => {
  const events = notificationEventsForMeetingHallReservationChange({
    reservationId: 'reservation-1',
    before: missingSnapshot(),
    after: snapshot({
      status: 'ON_HOLD',
      hallId: 'hall-1',
      title: 'Quarterly review',
      userId: 'requester-1',
      userName: 'Rachel Requester',
      userEmail: 'requester@example.com',
      startTime: new Date('2026-07-10T08:00:00.000Z'),
    }),
    sourceEventId: 'reservation-created',
    fieldValue,
  });
  assert.equal(events.length, 1);
  assert.deepEqual(events[0].data.target, {
    type: 'MODULE_ROLE',
    moduleKey: 'meetinghall',
    roles: ['MANAGER'],
  });
  assert.equal(
    events[0].data.route,
    '/service/meeting-hall/hall-1?date=2026-07-10&reservationId=reservation-1',
  );
  assert.equal(events[0].data.target.userIds, undefined);
});

test('reservation decision notifies requester and includes rejection reason', () => {
  const events = notificationEventsForMeetingHallReservationChange({
    reservationId: 'reservation-1',
    before: snapshot({ status: 'ON_HOLD' }),
    after: snapshot({
      status: 'REJECTED',
      hallId: 'hall-1',
      title: 'Quarterly review',
      userId: 'requester-1',
      userEmail: 'requester@example.com',
      rejectionReason: 'The room is under maintenance.',
      lastActionByUserId: 'manager-1',
      lastActionByName: 'Mary Manager',
      lastActionByEmail: 'manager@example.com',
      startTime: new Date('2026-07-10T08:00:00.000Z'),
    }),
    sourceEventId: 'reservation-rejected',
    fieldValue,
  });
  assert.deepEqual(events[0].data.target.userIds, ['requester-1']);
  assert.match(events[0].data.body, /under maintenance/);
  assert.equal(events[0].data.createdByUserId, 'manager-1');
});

test('non-notifying state changes remain silent', () => {
  assert.deepEqual(notificationEventsForNewsChange({
    postId: 'post-1',
    before: snapshot({ status: 'PUBLISHED' }),
    after: snapshot({ status: 'ARCHIVED' }),
    sourceEventId: 'archive-1',
    fieldValue,
  }), []);
  assert.deepEqual(notificationEventsForMeetingHallReservationChange({
    reservationId: 'reservation-1',
    before: missingSnapshot(),
    after: snapshot({ status: 'BLOCKED' }),
    sourceEventId: 'block-1',
    fieldValue,
  }), []);
});

function snapshot(data) {
  return { exists: true, data: () => data };
}

function missingSnapshot() {
  return { exists: false, data: () => undefined };
}
