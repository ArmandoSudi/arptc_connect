'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const {
  lastUtcMonthKeys,
  topEntries,
} = require('../src/inventory_triggers');

test('lastUtcMonthKeys returns a chronological UTC window across years', () => {
  const date = new Date('2026-02-19T23:59:59.000Z');

  assert.deepEqual(lastUtcMonthKeys(date, 6), [
    '2025-09',
    '2025-10',
    '2025-11',
    '2025-12',
    '2026-01',
    '2026-02',
  ]);
  assert.equal(date.toISOString(), '2026-02-19T23:59:59.000Z');
});

test('lastUtcMonthKeys handles year boundaries, singletons, and empty windows', () => {
  assert.deepEqual(
    lastUtcMonthKeys(new Date('2026-01-01T00:00:00.000Z'), 3),
    ['2025-11', '2025-12', '2026-01'],
  );
  assert.deepEqual(
    lastUtcMonthKeys(new Date('2026-08-19T00:00:00.000Z'), 1),
    ['2026-08'],
  );
  assert.deepEqual(
    lastUtcMonthKeys(new Date('2026-08-19T00:00:00.000Z'), 0),
    [],
  );
});

test('topEntries orders descending, applies the limit, and preserves input', () => {
  const values = {
    Paper: 4,
    Toner: 12,
    Staplers: 7,
    Envelopes: 2,
  };

  assert.deepEqual(topEntries(values, 3), {
    Toner: 12,
    Staplers: 7,
    Paper: 4,
  });
  assert.deepEqual(values, {
    Paper: 4,
    Toner: 12,
    Staplers: 7,
    Envelopes: 2,
  });
});

test('topEntries handles empty data, zero limits, and stable ties', () => {
  assert.deepEqual(topEntries({}, 10), {});
  assert.deepEqual(topEntries({ A: 2, B: 1 }, 0), {});
  assert.deepEqual(topEntries({ First: 5, Second: 5, Third: 4 }, 2), {
    First: 5,
    Second: 5,
  });
});
