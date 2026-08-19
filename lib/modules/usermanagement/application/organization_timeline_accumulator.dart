import 'package:arptc_connect/modules/usermanagement/domain/organization_query.dart';

class OrganizationTimelineAccumulator<T> {
  OrganizationTimelineAccumulator({required this.idOf});

  final String Function(T item) idOf;
  final List<T> _additionalItems = [];
  OrganizationTimelineCursor? _nextCursor;
  bool _hasMore = true;

  List<T> mergeFirstPage(List<T> firstPage) {
    final seen = <String>{};
    return [
      ...firstPage,
      ..._additionalItems,
    ].where((item) => seen.add(idOf(item))).toList(growable: false);
  }

  void seedCursor({
    required List<T> firstPage,
    required int pageSize,
    required DateTime Function(T item) timestampOf,
  }) {
    if (_additionalItems.isNotEmpty || _nextCursor != null || !_hasMore) return;
    if (firstPage.length < pageSize || firstPage.isEmpty) {
      _hasMore = false;
      return;
    }
    final last = firstPage.last;
    _nextCursor = OrganizationTimelineCursor(
      timestamp: timestampOf(last),
      id: idOf(last),
    );
  }

  void append(OrganizationTimelinePage<T> page) {
    final existingIds = _additionalItems.map(idOf).toSet();
    _additionalItems.addAll(
      page.items.where((item) => existingIds.add(idOf(item))),
    );
    _nextCursor = page.nextCursor;
    _hasMore = page.hasMore;
  }

  OrganizationTimelineCursor? get nextCursor => _nextCursor;
  bool get hasMore => _hasMore;

  void reset() {
    _additionalItems.clear();
    _nextCursor = null;
    _hasMore = true;
  }
}
