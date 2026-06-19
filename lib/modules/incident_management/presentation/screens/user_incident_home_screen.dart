import 'package:arptc_connect/generated/l10n.dart';
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

class UserIncidentHomeScreen extends ConsumerStatefulWidget {
  const UserIncidentHomeScreen({super.key});

  @override
  ConsumerState<UserIncidentHomeScreen> createState() =>
      _UserIncidentHomeScreenState();
}

class _UserIncidentHomeScreenState
    extends ConsumerState<UserIncidentHomeScreen> {
  String _query = '';
  String _status = '';

  @override
  Widget build(BuildContext context) {
    final activeTickets = ref.watch(myOpenIncidentTicketsProvider);
    final closedTickets = ref.watch(myClosedAndArchivedIncidentTicketsProvider);
    final l10n = S.of(context);

    return Scaffold(
      body: ContentView(
        child: DefaultTabController(
          length: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: PageHeader(
                      title: l10n.incidentManagement,
                      description: l10n.createAndFollowIncidents,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.go('/service/incidents/create'),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.newIncident),
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
              TabBar(
                tabs: [
                  Tab(text: l10n.activeIncidents),
                  Tab(text: l10n.closedAndArchived),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  children: [
                    _TicketList(
                      ticketsAsync: activeTickets,
                      query: _query,
                      status: _status,
                      emptyTitle: l10n.noActiveIncident,
                      emptyDescription: l10n.noActiveIncidentUserDescription,
                      onRefresh: () =>
                          ref.invalidate(myOpenIncidentTicketsProvider),
                      detailsPath: (ticket) =>
                          '/service/incidents/my/${ticket.id}',
                    ),
                    _TicketList(
                      ticketsAsync: closedTickets,
                      query: _query,
                      status: _status,
                      emptyTitle: l10n.noClosedIncident,
                      emptyDescription: l10n.closedAndArchivedDescription,
                      onRefresh: () => ref.invalidate(
                        myClosedAndArchivedIncidentTicketsProvider,
                      ),
                      detailsPath: (ticket) =>
                          '/service/incidents/my/${ticket.id}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketList extends StatelessWidget {
  const _TicketList({
    required this.ticketsAsync,
    required this.query,
    required this.status,
    required this.emptyTitle,
    required this.emptyDescription,
    required this.onRefresh,
    required this.detailsPath,
  });

  final AsyncValue<List<IncidentTicket>> ticketsAsync;
  final String query;
  final String status;
  final String emptyTitle;
  final String emptyDescription;
  final VoidCallback onRefresh;
  final String Function(IncidentTicket ticket) detailsPath;

  @override
  Widget build(BuildContext context) {
    return ticketsAsync.when(
      data: (tickets) {
        final filtered = filterIncidentTickets<IncidentTicket>(
          tickets: tickets,
          query: query,
          status: status,
          statusValue: (ticket) => ticket.status,
          searchText: (ticket) => [
            ticket.ticketNumber,
            ticket.title,
            ticket.description,
            ticket.affectedServiceName,
          ].join(' '),
        );

        if (filtered.isEmpty) {
          return EmptyStateView(
            icon: Icons.confirmation_number_outlined,
            title: emptyTitle,
            description: emptyDescription,
          );
        }

        return ListView.separated(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final ticket = filtered[index];
            return IncidentTicketCard(
              ticket: ticket,
              onTap: () => context.go(detailsPath(ticket)),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 8),
        );
      },
      loading: () => LoadingStateView(message: S.of(context).loadingIncidents),
      error: (error, _) => ErrorStateView(
        title: S.of(context).unableToLoadIncidents,
        description: error.toString(),
        onRetry: onRefresh,
      ),
    );
  }
}
