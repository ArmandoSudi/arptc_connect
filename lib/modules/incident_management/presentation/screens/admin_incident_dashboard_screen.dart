import 'package:arptc_connect/core/theme.dart';
import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_dashboard_stats.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_ticket.dart';
import 'package:arptc_connect/modules/incident_management/presentation/controllers/incident_providers.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_bar_chart.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_dashboard_layout.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_line_chart.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_pie_chart.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_ticket_card.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminIncidentDashboardScreen extends ConsumerWidget {
  const AdminIncidentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminIncidentDashboardStatsProvider);

    return Scaffold(
      body: ContentView(
        maxWidth: 1440,
        scrollable: true,
        child: statsAsync.when(
          data: (stats) => _AdminDashboardContent(stats: stats),
          loading: () => LoadingStateView(
            message: S.of(context).loadingIncident,
          ),
          error: (error, _) => ErrorStateView(
            title: S.of(context).unableToLoadIncident,
            description: error.toString(),
            onRetry: () => ref.invalidate(adminIncidentDashboardStatsProvider),
          ),
        ),
      ),
    );
  }
}

class _AdminDashboardContent extends StatelessWidget {
  const _AdminDashboardContent({required this.stats});

  final IncidentDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.corporateTheme;
    final l10n = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: l10n.incidentSupervision,
          description: l10n.incidentSupervisionDescription,
        ),
        const SizedBox(height: 18),
        IncidentResponsiveGrid(
          minItemWidth: 210,
          maxColumns: 5,
          children: [
            IncidentKpiCard(
              title: l10n.totalIncidentsThisMonth,
              value: stats.totalThisMonthCount.toString(),
              icon: Icons.calendar_month_outlined,
              color: scheme.primary,
            ),
            IncidentKpiCard(
              title: l10n.openTickets,
              value: stats.openCount.toString(),
              icon: Icons.inbox_outlined,
              color: tokens.warning,
            ),
            IncidentKpiCard(
              title: l10n.incidentStatusClosed,
              value: stats.closedCount.toString(),
              icon: Icons.check_circle_outline,
              color: tokens.success,
            ),
            IncidentKpiCard(
              title: l10n.incidentStatusArchived,
              value: stats.archivedCount.toString(),
              icon: Icons.archive_outlined,
              color: scheme.onSurfaceVariant,
            ),
            IncidentKpiCard(
              title: l10n.averageResolutionTime,
              value: _formatResolutionTime(stats.averageResolutionTimeMinutes),
              icon: Icons.timer_outlined,
              color: scheme.secondary,
            ),
          ],
        ),
        const SizedBox(height: 18),
        IncidentResponsiveGrid(
          minItemWidth: 360,
          maxColumns: 2,
          children: [
            IncidentLineChart(
              title: l10n.monthlyIncidentTrend,
              points: stats.monthlyIncidentTrend,
            ),
            IncidentPieChart(
              title: l10n.ticketsByPriority,
              data: stats.ticketsByPriority,
            ),
            IncidentBarChart(
              title: l10n.ticketsByService,
              data: stats.ticketsByService,
              orientation: IncidentBarChartOrientation.horizontal,
            ),
            IncidentBarChart(
              title: l10n.ticketsByCategory,
              data: stats.ticketsByCategory,
            ),
            IncidentBarChart(
              title: l10n.ticketsByDepartment,
              data: stats.ticketsByDepartment,
              orientation: IncidentBarChartOrientation.horizontal,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _RecentCriticalTickets(tickets: stats.recentCriticalTickets),
      ],
    );
  }
}

class _RecentCriticalTickets extends StatelessWidget {
  const _RecentCriticalTickets({required this.tickets});

  final List<IncidentTicket> tickets;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return IncidentDashboardPanel(
      title: l10n.recentCriticalTickets,
      subtitle: l10n.recentCriticalTicketsDescription,
      child: tickets.isEmpty
          ? SizedBox(
              height: 220,
              child: EmptyStateView(
                icon: Icons.verified_outlined,
                title: l10n.criticalTickets,
                description: l10n.criticalTicketsWillAppearHere,
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < tickets.length; index++) ...[
                  IncidentTicketCard(
                    ticket: tickets[index],
                    onTap: () => context.go(
                      '/service/incidents/admin/${tickets[index].id}',
                    ),
                  ),
                  if (index != tickets.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }
}

String _formatResolutionTime(double minutes) {
  if (minutes <= 0) {
    return '-';
  }
  final hours = minutes / 60;
  if (hours < 24) {
    return '${hours.toStringAsFixed(1)}h';
  }
  final days = hours / 24;
  return '${days.toStringAsFixed(1)}d';
}
