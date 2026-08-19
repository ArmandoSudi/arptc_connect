import 'package:arptc_connect/modules/usermanagement/application/organization_page_accumulator.dart';
import 'package:arptc_connect/modules/usermanagement/application/organization_timeline_accumulator.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrganizationPageAccumulator', () {
    test('seeds a stable cursor from the last complete first-page item', () {
      final accumulator = OrganizationPageAccumulator<_NamedItem>(
        idOf: (item) => item.id,
      );
      const firstPage = [
        _NamedItem('org-a', 'alpha'),
        _NamedItem('org-b', 'beta'),
      ];

      final cursor = accumulator.seedCursor(
        firstPage: firstPage,
        pageSize: 2,
        sortValueOf: (item) => item.nameLower,
      );

      expect(cursor?.nameLower, 'beta');
      expect(cursor?.id, 'org-b');
      expect(accumulator.nextCursor, same(cursor));
      expect(accumulator.hasMore, isTrue);
    });

    test('marks short and empty first pages as terminal', () {
      final short = OrganizationPageAccumulator<_NamedItem>(
        idOf: (item) => item.id,
      );
      final empty = OrganizationPageAccumulator<_NamedItem>(
        idOf: (item) => item.id,
      );

      expect(
        short.seedCursor(
          firstPage: const [_NamedItem('org-a', 'alpha')],
          pageSize: 2,
          sortValueOf: (item) => item.nameLower,
        ),
        isNull,
      );
      expect(short.hasMore, isFalse);
      expect(
        empty.seedCursor(
          firstPage: const [],
          pageSize: 2,
          sortValueOf: (item) => item.nameLower,
        ),
        isNull,
      );
      expect(empty.hasMore, isFalse);
    });

    test('deduplicates appended and refreshed first-page records', () {
      final accumulator = OrganizationPageAccumulator<_NamedItem>(
        idOf: (item) => item.id,
      );
      accumulator.seedCursor(
        firstPage: const [
          _NamedItem('org-a', 'alpha'),
          _NamedItem('org-b', 'beta'),
        ],
        pageSize: 2,
        sortValueOf: (item) => item.nameLower,
      );

      accumulator.append(
        const OrganizationPage<_NamedItem>(
          items: [
            _NamedItem('org-b', 'beta duplicate'),
            _NamedItem('org-c', 'charlie'),
            _NamedItem('org-c', 'charlie duplicate'),
          ],
          nextCursor: OrganizationPageCursor(
            nameLower: 'charlie',
            id: 'org-c',
          ),
        ),
      );

      expect(
        accumulator.mergeFirstPage(const [
          _NamedItem('org-a', 'alpha refreshed'),
          _NamedItem('org-b', 'beta refreshed'),
        ]).map((item) => item.id),
        ['org-a', 'org-b', 'org-c'],
      );
      expect(accumulator.nextCursor?.id, 'org-c');
      expect(accumulator.hasMore, isTrue);
    });

    test('terminal append and reset update continuation state', () {
      final accumulator = OrganizationPageAccumulator<_NamedItem>(
        idOf: (item) => item.id,
      );
      accumulator.append(
        const OrganizationPage<_NamedItem>(
          items: [_NamedItem('org-a', 'alpha')],
          nextCursor: null,
        ),
      );

      expect(accumulator.hasMore, isFalse);
      expect(accumulator.nextCursor, isNull);

      accumulator.reset();

      expect(accumulator.hasMore, isTrue);
      expect(accumulator.nextCursor, isNull);
      expect(accumulator.mergeFirstPage(const []), isEmpty);
    });
  });

  group('OrganizationTimelineAccumulator', () {
    test('seeds timestamp and document-ID tie-breaker from a full page', () {
      final accumulator = OrganizationTimelineAccumulator<_TimelineItem>(
        idOf: (item) => item.id,
      );
      final firstPage = [
        _TimelineItem('event-b', DateTime.utc(2026, 8, 11, 10)),
        _TimelineItem('event-a', DateTime.utc(2026, 8, 11, 9)),
      ];

      accumulator.seedCursor(
        firstPage: firstPage,
        pageSize: 2,
        timestampOf: (item) => item.timestamp,
      );

      expect(accumulator.nextCursor?.id, 'event-a');
      expect(
        accumulator.nextCursor?.timestamp,
        DateTime.utc(2026, 8, 11, 9),
      );
      expect(accumulator.hasMore, isTrue);
    });

    test('merge keeps streamed records first and deduplicates later pages', () {
      final accumulator = OrganizationTimelineAccumulator<_TimelineItem>(
        idOf: (item) => item.id,
      );
      final older = DateTime.utc(2026, 8, 10);
      accumulator.append(
        OrganizationTimelinePage<_TimelineItem>(
          items: [
            _TimelineItem('event-a', older),
            _TimelineItem('event-c', older),
            _TimelineItem('event-c', older),
          ],
          nextCursor: OrganizationTimelineCursor(
            timestamp: older,
            id: 'event-c',
          ),
        ),
      );

      final merged = accumulator.mergeFirstPage([
        _TimelineItem('event-a', DateTime.utc(2026, 8, 11)),
        _TimelineItem('event-b', DateTime.utc(2026, 8, 11)),
      ]);

      expect(merged.map((item) => item.id), ['event-a', 'event-b', 'event-c']);
      expect(merged.first.timestamp, DateTime.utc(2026, 8, 11));
      expect(accumulator.nextCursor?.id, 'event-c');
    });

    test('short pages terminate and reset permits a new cursor', () {
      final accumulator = OrganizationTimelineAccumulator<_TimelineItem>(
        idOf: (item) => item.id,
      );
      final item = _TimelineItem('event-a', DateTime.utc(2026, 8, 11));

      accumulator.seedCursor(
        firstPage: [item],
        pageSize: 2,
        timestampOf: (value) => value.timestamp,
      );
      expect(accumulator.hasMore, isFalse);
      expect(accumulator.nextCursor, isNull);

      accumulator.reset();
      accumulator.seedCursor(
        firstPage: [item],
        pageSize: 1,
        timestampOf: (value) => value.timestamp,
      );

      expect(accumulator.hasMore, isTrue);
      expect(accumulator.nextCursor?.id, 'event-a');
    });

    test('terminal append clears continuation state', () {
      final accumulator = OrganizationTimelineAccumulator<_TimelineItem>(
        idOf: (item) => item.id,
      );
      accumulator.append(
        OrganizationTimelinePage<_TimelineItem>(
          items: [
            _TimelineItem('event-a', DateTime.utc(2026, 8, 11)),
          ],
          nextCursor: null,
        ),
      );

      expect(accumulator.hasMore, isFalse);
      expect(accumulator.nextCursor, isNull);
    });
  });
}

class _NamedItem {
  const _NamedItem(this.id, this.nameLower);

  final String id;
  final String nameLower;
}

class _TimelineItem {
  const _TimelineItem(this.id, this.timestamp);

  final String id;
  final DateTime timestamp;
}
