import 'dart:collection';

enum PageDirection { forward, backward }

class PageCursor {
  PageCursor(Map<String, Object?> values)
      : values = UnmodifiableMapView(Map<String, Object?>.from(values)) {
    if (this.values.isEmpty) {
      throw ArgumentError.value(values, 'values', 'A cursor cannot be empty.');
    }
  }

  final Map<String, Object?> values;

  Object? operator [](String key) => values[key];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PageCursor || values.length != other.values.length) {
      return false;
    }
    return values.entries
        .every((entry) => other.values[entry.key] == entry.value);
  }

  @override
  int get hashCode {
    final entries = values.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return Object.hashAll(
      entries.map((entry) => Object.hash(entry.key, entry.value)),
    );
  }
}

class PageRequest {
  factory PageRequest({
    int limit = defaultLimit,
    PageCursor? cursor,
    PageDirection direction = PageDirection.forward,
  }) {
    if (limit < 1 || limit > maximumLimit) {
      throw RangeError.range(limit, 1, maximumLimit, 'limit');
    }
    return PageRequest._(
      limit: limit,
      cursor: cursor,
      direction: direction,
    );
  }

  const PageRequest._({
    required this.limit,
    required this.cursor,
    required this.direction,
  });

  static const int defaultLimit = 25;
  static const int maximumLimit = 100;

  final int limit;
  final PageCursor? cursor;
  final PageDirection direction;

  PageRequest next(PageCursor nextCursor) {
    return PageRequest(
      limit: limit,
      cursor: nextCursor,
      direction: PageDirection.forward,
    );
  }
}

class PageResult<T> {
  PageResult({
    required Iterable<T> items,
    required this.hasMore,
    this.nextCursor,
    this.previousCursor,
  }) : items = List<T>.unmodifiable(items) {
    if (hasMore && nextCursor == null) {
      throw ArgumentError('A next cursor is required when hasMore is true.');
    }
  }

  final List<T> items;
  final bool hasMore;
  final PageCursor? nextCursor;
  final PageCursor? previousCursor;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  PageResult<R> map<R>(R Function(T item) transform) {
    return PageResult<R>(
      items: items.map(transform),
      hasMore: hasMore,
      nextCursor: nextCursor,
      previousCursor: previousCursor,
    );
  }
}
