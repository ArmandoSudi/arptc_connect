import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/pagination.dart';
import '../security_compliance_strings.dart';
import 'security_compliance_state.dart';

class SecurityCompliancePagedList<T> extends StatefulWidget {
  const SecurityCompliancePagedList({
    required this.firstPage,
    required this.loadPage,
    required this.cursorOf,
    required this.itemBuilder,
    required this.onRetry,
    super.key,
    this.pageSize = PageRequest.defaultLimit,
  });

  final AsyncValue<List<T>> firstPage;
  final Future<PageResult<T>> Function(PageCursor cursor) loadPage;
  final PageCursor Function(T item) cursorOf;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final VoidCallback onRetry;
  final int pageSize;

  @override
  State<SecurityCompliancePagedList<T>> createState() =>
      _SecurityCompliancePagedListState<T>();
}

class _SecurityCompliancePagedListState<T>
    extends State<SecurityCompliancePagedList<T>> {
  List<T> _additional = const [];
  PageCursor? _nextCursor;
  bool _hasMore = false;
  bool _loadingMore = false;
  bool _loadMoreFailed = false;

  @override
  void didUpdateWidget(covariant SecurityCompliancePagedList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.firstPage != widget.firstPage) {
      _additional = const [];
      _nextCursor = null;
      _hasMore = false;
      _loadMoreFailed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = SecurityComplianceStrings.of(context);
    return SecurityComplianceAsyncState<List<T>>(
      value: widget.firstPage,
      onRetry: widget.onRetry,
      loadingLabel: strings.value('loading'),
      errorLabel: strings.value('unableToLoad'),
      retryLabel: strings.value('retry'),
      data: (first) {
        _initialize(first);
        final items = [...first, ..._additional];
        if (items.isEmpty) {
          return SecurityComplianceMessageState(
            icon: Icons.policy_outlined,
            title: strings.value('noData'),
            description: strings.value('noDataDescription'),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1100
                    ? 3
                    : constraints.maxWidth >= 680
                        ? 2
                        : 1;
                if (columns == 1) {
                  return Column(
                    children: [
                      for (final item in items) ...[
                        widget.itemBuilder(context, item),
                        const SizedBox(height: 12),
                      ],
                    ],
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: columns == 3 ? 1.35 : 1.5,
                  ),
                  itemBuilder: (context, index) =>
                      widget.itemBuilder(context, items[index]),
                );
              },
            ),
            if (_loadMoreFailed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  strings.value('unableToLoad'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            if (_hasMore) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loadingMore ? null : _loadMore,
                icon: _loadingMore
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more_rounded),
                label: Text(
                  strings.value(_loadingMore ? 'loadingMore' : 'loadMore'),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _initialize(List<T> first) {
    if (_nextCursor != null || _additional.isNotEmpty) return;
    _hasMore = first.length == widget.pageSize;
    _nextCursor =
        _hasMore && first.isNotEmpty ? widget.cursorOf(first.last) : null;
  }

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || _loadingMore) return;
    setState(() {
      _loadingMore = true;
      _loadMoreFailed = false;
    });
    try {
      final page = await widget.loadPage(cursor);
      if (!mounted) return;
      setState(() {
        _additional = [..._additional, ...page.items];
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _loadMoreFailed = true;
      });
    }
  }
}
