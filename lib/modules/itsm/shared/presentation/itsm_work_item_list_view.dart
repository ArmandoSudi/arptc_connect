import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/corporate_components.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/itsm_shared_domain.dart';

class ItsmWorkItemListView extends StatelessWidget {
  const ItsmWorkItemListView({
    required this.items,
    required this.searchQuery,
    required this.selectedTypes,
    required this.selectedStatuses,
    required this.showHistory,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onSearchChanged,
    required this.onHistoryChanged,
    required this.onTypesChanged,
    required this.onStatusesChanged,
    required this.onDateRangeChanged,
    required this.onClearDateRange,
    required this.onSelected,
    super.key,
    this.dateRange,
    this.loadMoreError,
    this.onLoadMore,
  });

  final List<ItsmWorkItemSummary> items;
  final String searchQuery;
  final Set<ItsmWorkItemType> selectedTypes;
  final Set<String> selectedStatuses;
  final DateTimeRange? dateRange;
  final bool showHistory;
  final bool hasMore;
  final bool isLoadingMore;
  final Object? loadMoreError;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool> onHistoryChanged;
  final ValueChanged<Set<ItsmWorkItemType>> onTypesChanged;
  final ValueChanged<Set<String>> onStatusesChanged;
  final ValueChanged<DateTimeRange> onDateRangeChanged;
  final VoidCallback onClearDateRange;
  final ValueChanged<ItsmWorkItemSummary> onSelected;
  final VoidCallback? onLoadMore;

  static const _statuses = [
    'open',
    'in_progress',
    'resolved',
    'submitted',
    'awaiting_approval',
    'approved',
    'assigned',
    'in_fulfilment',
    'awaiting_user',
    'fulfilled',
    'closed',
    'rejected',
    'cancelled',
    'archived',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          sliver: SliverToBoxAdapter(
            child: CorporateSurfaceCard(
              title: l10n.filter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CommonTextInput(
                    label: l10n.search,
                    hintText: l10n.itsmSearchWorkItems,
                    prefixIcon: const Icon(Icons.search),
                    onChanged: onSearchChanged,
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        icon: const Icon(Icons.pending_actions_outlined),
                        label: Text(l10n.active),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: const Icon(Icons.history),
                        label: Text(l10n.closedAndArchived),
                      ),
                    ],
                    selected: {showHistory},
                    onSelectionChanged: (selection) =>
                        onHistoryChanged(selection.single),
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.itsmWorkItemType),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ItsmWorkItemType.values.map((type) {
                      return FilterChip(
                        label: Text(_typeLabel(l10n, type)),
                        selected: selectedTypes.contains(type),
                        onSelected: (_) => onTypesChanged(
                          _toggled(selectedTypes, type),
                        ),
                      );
                    }).toList(growable: false),
                  ),
                  const SizedBox(height: 12),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    title: Text(l10n.status),
                    subtitle: selectedStatuses.isEmpty
                        ? Text(l10n.all)
                        : Text(selectedStatuses.join(', ')),
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _statuses.map((status) {
                            return FilterChip(
                              label: Text(status.replaceAll('_', ' ')),
                              selected: selectedStatuses.contains(status),
                              onSelected: (_) => onStatusesChanged(
                                _toggled(selectedStatuses, status),
                              ),
                            );
                          }).toList(growable: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _pickDates(context),
                        icon: const Icon(Icons.date_range_outlined),
                        label: Text(
                          dateRange == null
                              ? l10n.itsmFilterByDate
                              : '${DateFormat.yMd().format(dateRange!.start)} - '
                                  '${DateFormat.yMd().format(dateRange!.end)}',
                        ),
                      ),
                      if (dateRange != null)
                        TextButton.icon(
                          onPressed: onClearDateRange,
                          icon: const Icon(Icons.close),
                          label: Text(l10n.clear),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateView(
              icon: Icons.inbox_outlined,
              title: l10n.noDataAvailable,
              description: l10n.noDataDescription,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            sliver: SliverList.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _WorkItemCard(
                item: items[index],
                onTap: () => onSelected(items[index]),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                if (loadMoreError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      loadMoreError.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (hasMore || isLoadingMore)
                  FilledButton.tonalIcon(
                    onPressed: isLoadingMore ? null : onLoadMore,
                    icon: isLoadingMore
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.expand_more),
                    label: Text(l10n.itsmLoadMore),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDates(BuildContext context) async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: dateRange,
    );
    if (selected != null) onDateRangeChanged(selected);
  }
}

class _WorkItemCard extends StatelessWidget {
  const _WorkItemCard({required this.item, required this.onTap});

  final ItsmWorkItemSummary item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);
    return CorporateSurfaceCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: Icon(_typeIcon(item.type)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Chip(label: Text(_typeLabel(l10n, item.type))),
                    Chip(label: Text(item.status.replaceAll('_', ' '))),
                  ],
                ),
                Text(
                  item.reference,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '${l10n.updatedAt}: '
                  '${DateFormat.yMMMd().add_Hm().format(item.updatedAt.toLocal())}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

Set<T> _toggled<T>(Set<T> values, T value) {
  final result = Set<T>.from(values);
  result.contains(value) ? result.remove(value) : result.add(value);
  return result;
}

String _typeLabel(S l10n, ItsmWorkItemType type) => switch (type) {
      ItsmWorkItemType.incident => l10n.itsmIncidents,
      ItsmWorkItemType.serviceRequest => l10n.itsmServiceRequests,
      ItsmWorkItemType.changeRequest => l10n.itsmChangeRequests,
      ItsmWorkItemType.securityFinding => l10n.itsmSecurityFindings,
      ItsmWorkItemType.securityException => l10n.itsmSecurityExceptions,
    };

IconData _typeIcon(ItsmWorkItemType type) => switch (type) {
      ItsmWorkItemType.incident => Icons.support_agent,
      ItsmWorkItemType.serviceRequest => Icons.assignment_outlined,
      ItsmWorkItemType.changeRequest => Icons.change_circle_outlined,
      ItsmWorkItemType.securityFinding => Icons.gpp_maybe_outlined,
      ItsmWorkItemType.securityException => Icons.policy_outlined,
    };
