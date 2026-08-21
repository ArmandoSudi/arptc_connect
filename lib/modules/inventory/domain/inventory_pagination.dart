class InventoryPageRequest {
  const InventoryPageRequest({this.limit = 50, this.cursor});

  final int limit;
  final InventoryPageCursor? cursor;

  InventoryPageRequest validate() {
    if (limit < 1 || limit > 100) {
      throw RangeError.range(limit, 1, 100, 'limit');
    }
    return this;
  }

  @override
  bool operator ==(Object other) =>
      other is InventoryPageRequest &&
      other.limit == limit &&
      other.cursor == cursor;

  @override
  int get hashCode => Object.hash(limit, cursor);
}

class InventoryPageCursor {
  const InventoryPageCursor(
      {required this.documentId, required this.sortValue});

  final String documentId;
  final Object? sortValue;

  @override
  bool operator ==(Object other) =>
      other is InventoryPageCursor &&
      other.documentId == documentId &&
      other.sortValue == sortValue;

  @override
  int get hashCode => Object.hash(documentId, sortValue);
}

class InventoryPageResult<T> {
  const InventoryPageResult({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<T> items;
  final bool hasMore;
  final InventoryPageCursor? nextCursor;
}
