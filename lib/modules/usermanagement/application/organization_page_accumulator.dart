import 'package:arptc_connect/modules/usermanagement/domain/organization_query.dart';

class OrganizationPageAccumulator<T> {
  OrganizationPageAccumulator({required this.idOf});

  final String Function(T item) idOf;
  final List<T> _additionalItems = [];
  OrganizationPageCursor? _nextCursor;
  bool _hasMore = true;

  List<T> mergeFirstPage(List<T> firstPage) {
    final seen = <String>{};
    return [
      ...firstPage,
      ..._additionalItems,
    ].where((item) => seen.add(idOf(item))).toList(growable: false);
  }

  OrganizationPageCursor? seedCursor({
    required List<T> firstPage,
    required int pageSize,
    required String Function(T item) sortValueOf,
  }) {
    if (_additionalItems.isNotEmpty || _nextCursor != null || !_hasMore) {
      return _nextCursor;
    }
    if (firstPage.length < pageSize || firstPage.isEmpty) {
      _hasMore = false;
      return null;
    }
    final last = firstPage.last;
    _nextCursor = OrganizationPageCursor(
      nameLower: sortValueOf(last),
      id: idOf(last),
    );
    return _nextCursor;
  }

  void append(OrganizationPage<T> page) {
    final existingIds = _additionalItems.map(idOf).toSet();
    _additionalItems.addAll(
      page.items.where((item) => existingIds.add(idOf(item))),
    );
    _nextCursor = page.nextCursor;
    _hasMore = page.hasMore;
  }

  OrganizationPageCursor? get nextCursor => _nextCursor;
  bool get hasMore => _hasMore;

  void reset() {
    _additionalItems.clear();
    _nextCursor = null;
    _hasMore = true;
  }
}
