import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_providers.dart';
import 'package:arptc_connect/modules/itsm/shared/data/itsm_work_item_repository.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_shared_domain.dart';
import 'package:arptc_connect/modules/itsm/shared/presentation/itsm_work_item_list_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyRequestsScreen extends ConsumerStatefulWidget {
  const MyRequestsScreen({super.key, this.onRequestSelected});

  final ValueChanged<ItsmWorkItemSummary>? onRequestSelected;

  @override
  ConsumerState<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends ConsumerState<MyRequestsScreen> {
  static const _pageSize = 25;

  var _history = false;
  var _search = '';
  var _types = <ItsmWorkItemType>{};
  var _statuses = <String>{};
  DateTimeRange? _dateRange;
  var _additionalItems = <ItsmWorkItemSummary>[];
  PageCursor? _nextCursor;
  var _hasMore = false;
  var _loadingMore = false;
  Object? _loadMoreError;

  ItsmWorkItemQuery get _query => ItsmWorkItemQuery(
        scope:
            _history ? ItsmWorkItemScope.myHistory : ItsmWorkItemScope.myActive,
        types: _types,
        statuses: _statuses,
        searchTerm: _search,
        createdFrom: _dateRange?.start,
        createdTo: _dateRange == null
            ? null
            : DateTime(
                _dateRange!.end.year,
                _dateRange!.end.month,
                _dateRange!.end.day,
                23,
                59,
                59,
                999,
              ),
      );

  ItsmWorkItemPageRequest get _firstPageRequest => ItsmWorkItemPageRequest(
        query: _query,
        page: PageRequest(limit: _pageSize),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final firstPage = ref.watch(itsmWorkItemPageProvider(_firstPageRequest));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.itsmMyRequests)),
      body: firstPage.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorStateView(
          title: l10n.unableToLoad,
          description: error.toString(),
          onRetry: () => ref.invalidate(
            itsmWorkItemPageProvider(_firstPageRequest),
          ),
        ),
        data: (page) {
          _synchronizeFirstPage(page);
          return ItsmWorkItemListView(
            items: _mergeItems(page.items, _additionalItems),
            searchQuery: _search,
            selectedTypes: _types,
            selectedStatuses: _statuses,
            dateRange: _dateRange,
            showHistory: _history,
            hasMore: _hasMore,
            isLoadingMore: _loadingMore,
            loadMoreError: _loadMoreError,
            onSearchChanged: (value) => _changeFilters(search: value),
            onHistoryChanged: (value) => _changeFilters(history: value),
            onTypesChanged: (value) => _changeFilters(types: value),
            onStatusesChanged: (value) => _changeFilters(statuses: value),
            onDateRangeChanged: (value) => _changeFilters(dateRange: value),
            onClearDateRange: () => _changeFilters(clearDateRange: true),
            onSelected: widget.onRequestSelected ?? (_) {},
            onLoadMore: _hasMore && !_loadingMore ? _loadMore : null,
          );
        },
      ),
    );
  }

  void _synchronizeFirstPage(PageResult<ItsmWorkItemSummary> page) {
    if (_nextCursor != null || _additionalItems.isNotEmpty) return;
    _hasMore = page.hasMore;
    _nextCursor = page.nextCursor;
  }

  void _changeFilters({
    String? search,
    bool? history,
    Set<ItsmWorkItemType>? types,
    Set<String>? statuses,
    DateTimeRange? dateRange,
    bool clearDateRange = false,
  }) {
    setState(() {
      if (search != null) _search = search;
      if (history != null) _history = history;
      if (types != null) _types = types;
      if (statuses != null) _statuses = statuses;
      if (dateRange != null || clearDateRange) {
        _dateRange = clearDateRange ? null : dateRange;
      }
      _additionalItems = const [];
      _nextCursor = null;
      _hasMore = false;
      _loadingMore = false;
      _loadMoreError = null;
    });
  }

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || _loadingMore) return;
    setState(() {
      _loadingMore = true;
      _loadMoreError = null;
    });
    try {
      final nextPage = await ref.read(
        itsmWorkItemPageProvider(
          ItsmWorkItemPageRequest(
            query: _query,
            page: PageRequest(limit: _pageSize, cursor: cursor),
          ),
        ).future,
      );
      if (!mounted) return;
      setState(() {
        _additionalItems = _mergeItems(_additionalItems, nextPage.items);
        _nextCursor = nextPage.nextCursor;
        _hasMore = nextPage.hasMore;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _loadMoreError = error;
      });
    }
  }
}

List<ItsmWorkItemSummary> _mergeItems(
  Iterable<ItsmWorkItemSummary> first,
  Iterable<ItsmWorkItemSummary> second,
) {
  final byIdentity = <String, ItsmWorkItemSummary>{};
  for (final item in [...first, ...second]) {
    byIdentity['${item.type.value}:${item.id}'] = item;
  }
  return byIdentity.values.toList(growable: false);
}
