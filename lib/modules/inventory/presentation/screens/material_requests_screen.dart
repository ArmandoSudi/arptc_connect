import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/widgets/app_search_bar.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../application/inventory_contracts.dart';
import '../../application/inventory_providers.dart';
import '../../domain/inventory_domain.dart';
import '../widgets/inventory_shell.dart';
import '../widgets/inventory_status_badge.dart';

class MaterialRequestsScreen extends ConsumerStatefulWidget {
  const MaterialRequestsScreen({
    super.key,
    this.historyOnly = false,
    this.assignedToMe = false,
    this.initialStatus,
  });

  final bool historyOnly;
  final bool assignedToMe;
  final MaterialRequestStatus? initialStatus;

  @override
  ConsumerState<MaterialRequestsScreen> createState() =>
      _MaterialRequestsScreenState();
}

class _MaterialRequestsScreenState
    extends ConsumerState<MaterialRequestsScreen> {
  String _search = '';
  MaterialRequestStatus? _status;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
  }

  @override
  void didUpdateWidget(covariant MaterialRequestsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStatus != widget.initialStatus) {
      _status = widget.initialStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final policy = ref.watch(inventoryAccessPolicyProvider);
    final statuses = widget.historyOnly
        ? MaterialRequestStatus.values
            .where((status) => status.isTerminal)
            .toList()
        : MaterialRequestStatus.values
            .where((status) => !status.isTerminal)
            .toList();
    final query = InventoryRequestQuery(
      search: _search,
      statuses: _status == null ? statuses : [_status!],
      assignedToMe: widget.assignedToMe,
    );
    final requests = ref.watch(materialRequestsProvider(query));
    final title = widget.historyOnly
        ? l10n.lookup('invRequestHistory')
        : policy.canReadAllRequests
            ? l10n.lookup('invRequestQueue')
            : l10n.lookup('invMyRequests');
    return InventoryShell(
      title: title,
      subtitle: policy.isReadOnlyAdmin
          ? l10n.lookup('invReadOnly')
          : l10n.lookup('invUserSubtitle'),
      onBack: () => context.pop(),
      actions: [
        if (!widget.historyOnly)
          OutlinedButton.icon(
            onPressed: () =>
                context.go('/service/inventory/requests/history'),
            icon: const Icon(Icons.history_rounded),
            label: Text(l10n.lookup('invRequestHistory')),
          ),
        if (policy.canSubmitOwnRequest || policy.canSubmitOnBehalf)
          FilledButton.icon(
            onPressed: () => context.go('/service/inventory/catalog'),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.lookup('invRequestItems')),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final search = AppSearchBar(
                hintText: l10n.search,
                onChanged: (value) => setState(() => _search = value),
              );
              final filter = DropdownButtonFormField<MaterialRequestStatus?>(
                value: _status,
                decoration: InputDecoration(labelText: l10n.status),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.allStatuses)),
                  for (final status in statuses)
                    DropdownMenuItem(
                      value: status,
                      child: Text(_statusLabel(context, status)),
                    ),
                ],
                onChanged: (value) => setState(() => _status = value),
              );
              if (constraints.maxWidth < 680) {
                return Column(
                    children: [search, const SizedBox(height: 12), filter]);
              }
              return Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: 16),
                  SizedBox(width: 260, child: filter),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          requests.when(
            loading: () => LoadingStateView(message: l10n.loading),
            error: (error, _) => ErrorStateView(
              title: l10n.unableToLoad,
              description: error.toString(),
              onRetry: () => ref.invalidate(materialRequestsProvider(query)),
            ),
            data: (entries) => entries.isEmpty
                ? EmptyStateView(
                    icon: Icons.receipt_long_outlined,
                    title: l10n.lookup('invNoRequests'),
                  )
                : InventoryPanel(
                    padding: EdgeInsets.zero,
                    child: LayoutBuilder(
                      builder: (context, constraints) =>
                          constraints.maxWidth < 820
                              ? _RequestCards(requests: entries)
                              : _RequestTable(requests: entries),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RequestTable extends StatelessWidget {
  const _RequestTable({required this.requests});

  final List<MaterialRequest> requests;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        showCheckboxColumn: false,
        columns: [
          DataColumn(label: Text(l10n.lookup('invRequestNumber'))),
          DataColumn(label: Text(l10n.lookup('invRequestedFor'))),
          DataColumn(label: Text(l10n.status)),
          DataColumn(label: Text(l10n.lookup('invManagerAssigned'))),
          DataColumn(label: Text(l10n.updatedAt)),
        ],
        rows: [
          for (final request in requests)
            DataRow(
              onSelectChanged: (_) =>
                  context.go('/service/inventory/requests/${request.id}'),
              cells: [
                DataCell(Text(request.requestNumber)),
                DataCell(Text(request.requestedFor.name)),
                DataCell(InventoryRequestStatusBadge(request.status)),
                DataCell(
                    Text(request.assignedManager?.name ?? l10n.unassigned)),
                DataCell(Text(_date(request.updatedAt))),
              ],
            ),
        ],
      ),
    );
  }
}

class _RequestCards extends StatelessWidget {
  const _RequestCards({required this.requests});

  final List<MaterialRequest> requests;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < requests.length; index++) ...[
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            title: Text(
              requests[index].requestNumber,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                  '${requests[index].requestedFor.name}  |  ${_date(requests[index].updatedAt)}'),
            ),
            trailing: InventoryRequestStatusBadge(requests[index].status),
            onTap: () => context.go(
              '/service/inventory/requests/${requests[index].id}',
            ),
          ),
          if (index != requests.length - 1) const Divider(height: 1),
        ],
      ],
    );
  }
}

String _statusLabel(BuildContext context, MaterialRequestStatus status) {
  final l10n = S.of(context);
  return l10n.lookup(switch (status) {
    MaterialRequestStatus.submitted => 'invSubmitted',
    MaterialRequestStatus.underReview => 'invUnderReview',
    MaterialRequestStatus.adjusted => 'invAdjusted',
    MaterialRequestStatus.readyForIssue => 'invReadyForIssue',
    MaterialRequestStatus.partiallyFulfilled => 'invPartiallyFulfilled',
    MaterialRequestStatus.awaitingConfirmation => 'invAwaitingConfirmation',
    MaterialRequestStatus.fulfilled => 'invFulfilled',
    MaterialRequestStatus.closedShort => 'invClosedShort',
    MaterialRequestStatus.cancelled => 'invCancelled',
    MaterialRequestStatus.rejected => 'invRejected',
  });
}

String _date(DateTime? value) =>
    value == null ? '-' : DateFormat.yMMMd().add_Hm().format(value.toLocal());
