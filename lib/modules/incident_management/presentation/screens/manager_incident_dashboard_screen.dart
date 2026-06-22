import 'package:arptc_connect/core/theme.dart';
import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_dashboard_stats.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_ticket.dart';
import 'package:arptc_connect/modules/incident_management/presentation/controllers/incident_providers.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_bar_chart.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_dashboard_layout.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_pie_chart.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_priority_badge.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_status_badge.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_ticket_card.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ManagerIncidentDashboardScreen extends ConsumerWidget {
  const ManagerIncidentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(managerIncidentDashboardStatsProvider);

    return Scaffold(
      body: ContentView(
        maxWidth: 1440,
        scrollable: true,
        child: statsAsync.when(
          data: (stats) => _ManagerDashboardContent(stats: stats),
          loading: () => LoadingStateView(
            message: S.of(context).loadingIncident,
          ),
          error: (error, _) => ErrorStateView(
            title: S.of(context).unableToLoadIncident,
            description: error.toString(),
            onRetry: () =>
                ref.invalidate(managerIncidentDashboardStatsProvider),
          ),
        ),
      ),
    );
  }
}

class _ManagerDashboardContent extends StatelessWidget {
  const _ManagerDashboardContent({required this.stats});

  final IncidentDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.corporateTheme;
    final l10n = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          title: l10n.incidentOperations,
          description: l10n.incidentOperationsDescription,
          actions: [
            OutlinedButton.icon(
              onPressed: () => context.go('/service/incidents/parameters'),
              icon: const Icon(Icons.tune_outlined),
              label: Text(l10n.parameters),
            ),
            FilledButton.icon(
              onPressed: () => context.go('/service/incidents/create'),
              icon: const Icon(Icons.add),
              label: Text(l10n.newIncident),
            ),
          ],
        ),
        const SizedBox(height: 18),
        IncidentResponsiveGrid(
          minItemWidth: 210,
          maxColumns: 4,
          children: [
            IncidentKpiCard(
              title: l10n.openTickets,
              value: stats.totalOpenCount.toString(),
              subtitle: l10n.openTicketsSubtitle,
              icon: Icons.inbox_outlined,
              color: scheme.primary,
              onTap: () => context.go(_queuePath('open')),
            ),
            IncidentKpiCard(
              title: l10n.unassignedTickets,
              value: stats.unassignedCount.toString(),
              subtitle: l10n.unassignedTicketsSubtitle,
              icon: Icons.person_off_outlined,
              color: tokens.warning,
              onTap: () => context.go(_queuePath('unassigned')),
            ),
            IncidentKpiCard(
              title: l10n.assignedToMe,
              value: stats.assignedToMeCount.toString(),
              icon: Icons.assignment_ind_outlined,
              color: scheme.secondary,
              onTap: () => context.go(_queuePath('assigned-to-me')),
            ),
            IncidentKpiCard(
              title: l10n.solvedTickets,
              value: stats.solvedCount.toString(),
              subtitle: l10n.solvedTicketsSubtitle,
              icon: Icons.task_alt_outlined,
              color: tokens.success,
              onTap: () => context.go(_queuePath('solved')),
            ),
          ],
        ),
        const SizedBox(height: 18),
        IncidentResponsiveGrid(
          minItemWidth: 360,
          maxColumns: 2,
          children: [
            IncidentPieChart(
              title: l10n.ticketsByPriority,
              data: stats.ticketsByPriority,
            ),
            IncidentBarChart(
              title: l10n.ticketsByAffectedService,
              data: stats.ticketsByService,
              orientation: IncidentBarChartOrientation.horizontal,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _OperationalQueue(tickets: stats.activeTicketQueue),
        if (stats.myAssignedTickets.isNotEmpty) ...[
          const SizedBox(height: 18),
          _AssignedTicketList(tickets: stats.myAssignedTickets),
        ],
      ],
    );
  }
}

String _queuePath(String queueKey) => '/service/incidents/queue/$queueKey';

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.description,
    required this.actions,
  });

  final String title;
  final String description;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 760;
        final backButton = IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            context.pop();
          },
        );
        final header = PageHeader(title: title, description: description);
        final actionBar = Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: isNarrow ? WrapAlignment.start : WrapAlignment.end,
          children: actions,
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  backButton,
                  const SizedBox(width: 8),
                  Expanded(child: header),
                ],
              ),
              const SizedBox(height: 12),
              actionBar,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            backButton,
            Expanded(child: header),
            const SizedBox(width: 16),
            actionBar,
          ],
        );
      },
    );
  }
}

class _OperationalQueue extends StatelessWidget {
  const _OperationalQueue({required this.tickets});

  final List<IncidentTicket> tickets;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return IncidentDashboardPanel(
      title: l10n.operationalQueue,
      subtitle: l10n.operationalQueueDescription,
      child: tickets.isEmpty
          ? SizedBox(
              height: 220,
              child: EmptyStateView(
                icon: Icons.inbox_outlined,
                title: l10n.noActiveIncident,
                description: l10n.newOperationalTicketsWillAppearHere,
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 920) {
                  return Column(
                    children: [
                      for (var index = 0; index < tickets.length; index++) ...[
                        IncidentTicketCard(
                          ticket: tickets[index],
                          onTap: () => context.go(
                            '/service/incidents/manager/${tickets[index].id}',
                          ),
                        ),
                        if (index != tickets.length - 1)
                          const SizedBox(height: 8),
                      ],
                    ],
                  );
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingTextStyle:
                        Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                    columns: [
                      DataColumn(label: Text(l10n.ticket)),
                      DataColumn(label: Text(l10n.title)),
                      DataColumn(label: Text(l10n.service)),
                      DataColumn(label: Text(l10n.category)),
                      DataColumn(label: Text(l10n.priority)),
                      DataColumn(label: Text(l10n.status)),
                      DataColumn(label: Text(l10n.createdBy)),
                      DataColumn(label: Text(l10n.assignedTo)),
                      DataColumn(label: Text(l10n.age)),
                      DataColumn(label: Text(l10n.createdAtColumn)),
                    ],
                    rows: tickets.map((ticket) {
                      return DataRow(
                        onSelectChanged: (_) => context.go(
                          '/service/incidents/manager/${ticket.id}',
                        ),
                        cells: [
                          DataCell(
                              Text(_dashFallback(ticket.ticketNumber, l10n))),
                          DataCell(
                            SizedBox(
                              width: 220,
                              child: Text(
                                _dashFallback(ticket.title, l10n),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(_dashFallback(
                              ticket.affectedServiceName,
                              l10n,
                            )),
                          ),
                          DataCell(Text(_dashFallback(
                            ticket.categoryName,
                            l10n,
                          ))),
                          DataCell(
                              IncidentPriorityBadge(priority: ticket.priority)),
                          DataCell(IncidentStatusBadge(status: ticket.status)),
                          DataCell(Text(_dashFallback(
                            ticket.createdByName,
                            l10n,
                          ))),
                          DataCell(
                            Text(_unassignedFallback(
                              ticket.assignedToName,
                              l10n,
                            )),
                          ),
                          DataCell(Text(_ageSince(ticket.createdAt))),
                          DataCell(Text(_formatDate(ticket.createdAt))),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }
}

class _AssignedTicketList extends StatelessWidget {
  const _AssignedTicketList({required this.tickets});

  final List<IncidentTicket> tickets;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return IncidentDashboardPanel(
      title: l10n.myAssignedTickets,
      subtitle: l10n.myAssignedTicketsDescription,
      child: Column(
        children: [
          for (var index = 0; index < tickets.length; index++) ...[
            IncidentTicketCard(
              ticket: tickets[index],
              onTap: () => context.go(
                '/service/incidents/manager/${tickets[index].id}',
              ),
            ),
            if (index != tickets.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

String _dashFallback(String value, S l10n) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? l10n.dash : trimmed;
}

String _unassignedFallback(String value, S l10n) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? l10n.unassigned : trimmed;
}

String _formatDate(DateTime? date) {
  if (date == null) {
    return '-';
  }
  return DateFormat('dd MMM yyyy HH:mm').format(date.toLocal());
}

String _ageSince(DateTime? date) {
  if (date == null) {
    return '-';
  }
  final age = DateTime.now().difference(date.toLocal());
  if (age.inMinutes < 60) {
    return '${age.inMinutes}m';
  }
  if (age.inHours < 24) {
    return '${age.inHours}h';
  }
  return '${age.inDays}d';
}
