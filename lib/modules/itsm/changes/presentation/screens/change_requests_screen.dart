import 'package:arptc_connect/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/changes_application.dart';
import '../../data/change_repository.dart';
import '../../domain/changes_domain.dart';
import '../../../shared/application/itsm_providers.dart';
import '../../../shared/domain/itsm_common.dart';
import '../../../shared/domain/pagination.dart';
import '../change_presentation_strings.dart';
import '../widgets/change_async_view.dart';
import '../widgets/change_page_shell.dart';
import '../widgets/change_request_views.dart';

class ChangeRequestsScreen extends ConsumerStatefulWidget {
  const ChangeRequestsScreen({
    required this.onNewChange,
    required this.onSelected,
    super.key,
    this.onBack,
  });

  final VoidCallback onNewChange;
  final ValueChanged<ChangeRequest> onSelected;
  final VoidCallback? onBack;

  @override
  ConsumerState<ChangeRequestsScreen> createState() =>
      _ChangeRequestsScreenState();
}

class _ChangeRequestsScreenState extends ConsumerState<ChangeRequestsScreen> {
  static const _pageSize = 25;

  bool _history = false;
  ChangeStatus? _status;
  List<ChangeRequest> _additionalChanges = const [];
  PageCursor? _nextCursor;
  bool _hasMore = false;
  bool _loadingMore = false;
  Object? _loadMoreError;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final session = ref.watch(itsmSessionProvider).valueOrNull;
    final manager = session?.role == ItsmRole.manager;
    final scope = manager
        ? (_history
            ? ChangeRequestScope.managerHistory
            : ChangeRequestScope.managerActive)
        : (_history
            ? ChangeRequestScope.myHistory
            : ChangeRequestScope.myActive);
    final request = ChangeFirstPageRequest(
      query: ChangeRequestQuery(scope: scope, status: _status),
      limit: _pageSize,
    );
    final changes = ref.watch(changeFirstPageProvider(request));
    return ChangePageShell(
      title: manager ? l10n.operationalChanges : l10n.myChanges,
      subtitle: l10n.changeManagementSubtitle,
      onBack: widget.onBack,
      actions: [
        FilledButton.icon(
          onPressed: widget.onNewChange,
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.newChange),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.changeActiveView),
                selected: !_history,
                onSelected: (_) => _changeFilters(history: false),
              ),
              ChoiceChip(
                label: Text(l10n.changeHistoryView),
                selected: _history,
                onSelected: (_) => _changeFilters(history: true),
              ),
              DropdownButton<ChangeStatus?>(
                value: _status,
                hint: Text(l10n.changeSelectStatus),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.allStatuses)),
                  for (final status in ChangeStatus.values)
                    DropdownMenuItem(
                      value: status,
                      child: Text(l10n.changeStatusLabel(status)),
                    ),
                ],
                onChanged: (value) => _changeFilters(status: value),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ChangeAsyncView<List<ChangeRequest>>(
            value: changes,
            loadingLabel: l10n.loading,
            retryLabel: l10n.retry,
            onRetry: () => ref.invalidate(changeFirstPageProvider(request)),
            data: (items) {
              _synchronizeFirstPage(items);
              return Column(
                children: [
                  ChangeRequestListView(
                    changes: _mergeChanges(items, _additionalChanges),
                    onSelected: widget.onSelected,
                  ),
                  if (_loadMoreError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _loadMoreError.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  if (_hasMore) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed:
                          _loadingMore ? null : () => _loadMore(request.query),
                      icon: _loadingMore
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.expand_more_rounded),
                      label:
                          Text(_loadingMore ? l10n.loadingMore : l10n.loadMore),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _synchronizeFirstPage(List<ChangeRequest> items) {
    if (_nextCursor != null || _additionalChanges.isNotEmpty) return;
    _hasMore = items.length == _pageSize;
    _nextCursor = _hasMore && items.isNotEmpty
        ? PageCursor({
            'updatedAt': items.last.updatedAt,
            'id': items.last.id,
          })
        : null;
  }

  void _changeFilters({bool? history, ChangeStatus? status}) {
    setState(() {
      if (history != null) _history = history;
      _status = status;
      _additionalChanges = const [];
      _nextCursor = null;
      _hasMore = false;
      _loadingMore = false;
      _loadMoreError = null;
    });
  }

  Future<void> _loadMore(ChangeRequestQuery query) async {
    final cursor = _nextCursor;
    if (cursor == null || _loadingMore) return;
    setState(() {
      _loadingMore = true;
      _loadMoreError = null;
    });
    try {
      final page = await ref.read(
        changePageProvider(
          ChangePageRequest(
            query: query,
            page: PageRequest(limit: _pageSize, cursor: cursor),
          ),
        ).future,
      );
      if (!mounted) return;
      setState(() {
        _additionalChanges = _mergeChanges(_additionalChanges, page.items);
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
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

List<ChangeRequest> _mergeChanges(
  Iterable<ChangeRequest> first,
  Iterable<ChangeRequest> second,
) {
  final byId = <String, ChangeRequest>{};
  for (final change in [...first, ...second]) {
    byId[change.id] = change;
  }
  return byId.values.toList(growable: false);
}
