import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_dashboard_stats.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_ticket.dart';
import 'package:arptc_connect/modules/incident_management/presentation/controllers/incident_providers.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_filter_bar.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_ticket_card.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ManagerIncidentQueueScreen extends ConsumerStatefulWidget {
  const ManagerIncidentQueueScreen({
    required this.queueKey,
    super.key,
  });

  final String queueKey;

  @override
  ConsumerState<ManagerIncidentQueueScreen> createState() =>
      _ManagerIncidentQueueScreenState();
}

class _ManagerIncidentQueueScreenState
    extends ConsumerState<ManagerIncidentQueueScreen> {
  String _query = '';
  String _status = '';
  bool _emptyToastShown = false;

  @override
  void didUpdateWidget(covariant ManagerIncidentQueueScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.queueKey != widget.queueKey) {
      _query = '';
      _status = '';
      _emptyToastShown = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(managerIncidentDashboardStatsProvider);
    final l10n = S.of(context);

    return Scaffold(
      body: ContentView(
        maxWidth: 1080,
        child: statsAsync.when(
          data: (stats) {
            final queue = _IncidentQueueConfig.fromKey(widget.queueKey, l10n);
            final tickets = queue.resolveTickets(stats);
            final filtered = filterIncidentTickets<IncidentTicket>(
              tickets: tickets,
              query: _query,
              status: _status,
              statusValue: (ticket) => ticket.status,
              searchText: (ticket) => [
                ticket.ticketNumber,
                ticket.title,
                ticket.description,
                ticket.affectedServiceName,
                ticket.categoryName,
                ticket.createdByName,
                ticket.assignedToName,
              ].join(' '),
            );

            if (tickets.isEmpty && !_emptyToastShown) {
              _emptyToastShown = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.thereIsNoQueueItem(queue.toastLabel)),
                  ),
                );
              });
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: PageHeader(
                        title: queue.title,
                        description: queue.description,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                IncidentFilterBar(
                  query: _query,
                  status: _status,
                  onQueryChanged: (value) => setState(() => _query = value),
                  onStatusChanged: (value) => setState(() => _status = value),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyStateView(
                          icon: Icons.inbox_outlined,
                          title: l10n.noTicketsFound,
                          description: tickets.isEmpty
                              ? l10n.queueEmpty
                              : l10n.tryAnotherSearchOrStatus,
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final ticket = filtered[index];
                            return IncidentTicketCard(
                              ticket: ticket,
                              onTap: () => context.go(
                                '/service/incidents/manager/${ticket.id}',
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
          loading: () => LoadingStateView(
            message: l10n.loadingIncidents,
          ),
          error: (error, _) => ErrorStateView(
            title: l10n.unableToLoadIncidents,
            description: error.toString(),
            onRetry: () =>
                ref.invalidate(managerIncidentDashboardStatsProvider),
          ),
        ),
      ),
    );
  }
}

class _IncidentQueueConfig {
  const _IncidentQueueConfig({
    required this.key,
    required this.title,
    required this.description,
    required this.toastLabel,
    required this.resolveTickets,
  });

  final String key;
  final String title;
  final String description;
  final String toastLabel;
  final List<IncidentTicket> Function(IncidentDashboardStats stats)
      resolveTickets;

  static _IncidentQueueConfig fromKey(String key, S l10n) {
    for (final queue in _queues(l10n)) {
      if (queue.key == key) {
        return queue;
      }
    }
    return _queues(l10n).first;
  }

  static List<_IncidentQueueConfig> _queues(S l10n) => <_IncidentQueueConfig>[
        _IncidentQueueConfig(
          key: 'open',
          title: l10n.openTickets,
          description: l10n.openTicketsQueueDescription,
          toastLabel: l10n.openTickets.toLowerCase(),
          resolveTickets: (stats) => stats.openTickets,
        ),
        _IncidentQueueConfig(
          key: 'unassigned',
          title: l10n.unassignedTickets,
          description: l10n.unassignedTicketsQueueDescription,
          toastLabel: l10n.unassignedTickets.toLowerCase(),
          resolveTickets: (stats) => stats.unassignedTickets,
        ),
        _IncidentQueueConfig(
          key: 'assigned-to-me',
          title: l10n.assignedToMe,
          description: l10n.assignedToMeQueueDescription,
          toastLabel: l10n.assignedToMe.toLowerCase(),
          resolveTickets: (stats) => stats.myAssignedTickets,
        ),
        _IncidentQueueConfig(
          key: 'solved',
          title: l10n.solvedTickets,
          description: l10n.solvedTicketsQueueDescription,
          toastLabel: l10n.solvedTickets.toLowerCase(),
          resolveTickets: (stats) => stats.solvedTickets,
        ),
      ];
}
