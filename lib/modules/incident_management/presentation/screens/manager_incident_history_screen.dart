import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_enums.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_ticket.dart';
import 'package:arptc_connect/modules/incident_management/presentation/controllers/incident_providers.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_ticket_card.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ManagerIncidentHistoryScreen extends ConsumerStatefulWidget {
  const ManagerIncidentHistoryScreen({super.key});

  @override
  ConsumerState<ManagerIncidentHistoryScreen> createState() =>
      _ManagerIncidentHistoryScreenState();
}

class _ManagerIncidentHistoryScreenState
    extends ConsumerState<ManagerIncidentHistoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final roleAsync = ref.watch(currentUserIncidentRoleProvider);

    return Scaffold(
      body: ContentView(
        maxWidth: 1080,
        child: roleAsync.when(
          data: (role) {
            if (role != IncidentRole.manager) {
              return EmptyStateView(
                icon: Icons.lock_outline,
                title: l10n.noIncidentDashboardAccess,
              );
            }
            return _HistoryContent(
              query: _query,
              searchController: _searchController,
              onQueryChanged: (value) => setState(() => _query = value),
            );
          },
          loading: () => LoadingStateView(
            message: l10n.loadingIncidentAccess,
          ),
          error: (error, _) => ErrorStateView(
            title: l10n.unableToLoadIncidentAccess,
            description: error.toString(),
            onRetry: () => ref.invalidate(currentUserIncidentRoleProvider),
          ),
        ),
      ),
    );
  }
}

class _HistoryContent extends ConsumerWidget {
  const _HistoryContent({
    required this.query,
    required this.searchController,
    required this.onQueryChanged,
  });

  final String query;
  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final ticketsAsync = ref.watch(managerClosedIncidentTicketsProvider);

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
                title: l10n.closedTicketHistory,
                description: l10n.closedTicketHistoryDescription,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CommonTextInput(
          label: l10n.searchIncidents,
          type: CommonTextInputType.text,
          controller: searchController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: onQueryChanged,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ticketsAsync.when(
            data: (tickets) {
              final filteredTickets =
                  filterAndSortClosedIncidentTickets(tickets, query);
              if (filteredTickets.isEmpty) {
                return EmptyStateView(
                  icon: Icons.history_outlined,
                  title: query.trim().isEmpty
                      ? l10n.noClosedTicketsHistory
                      : l10n.noTicketsFound,
                  description: query.trim().isEmpty
                      ? l10n.noClosedTicketsHistoryDescription
                      : l10n.tryAnotherSearchOrStatus,
                );
              }

              return ListView.separated(
                itemCount: filteredTickets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final ticket = filteredTickets[index];
                  return IncidentTicketCard(
                    ticket: ticket,
                    onTap: () => context.go(
                      '/service/incidents/manager/${ticket.id}',
                    ),
                  );
                },
              );
            },
            loading: () => LoadingStateView(
              message: l10n.loadingIncidents,
            ),
            error: (error, _) => ErrorStateView(
              title: l10n.unableToLoadIncidents,
              description: error.toString(),
              onRetry: () =>
                  ref.invalidate(managerClosedIncidentTicketsProvider),
            ),
          ),
        ),
      ],
    );
  }
}

@visibleForTesting
List<IncidentTicket> filterAndSortClosedIncidentTickets(
  List<IncidentTicket> tickets,
  String query,
) {
  final normalizedQuery = query.trim().toLowerCase();
  final filtered = tickets.where((ticket) {
    if (normalizedQuery.isEmpty) {
      return true;
    }
    return [
      ticket.ticketNumber,
      ticket.title,
      ticket.description,
      ticket.affectedServiceName,
      ticket.categoryName,
      ticket.createdByName,
      ticket.assignedToName,
      ticket.resolutionSummary,
      ticket.resolutionCode,
    ].join(' ').toLowerCase().contains(normalizedQuery);
  }).toList();

  filtered.sort((left, right) {
    final leftDate = left.closedAt ?? left.updatedAt ?? left.createdAt;
    final rightDate = right.closedAt ?? right.updatedAt ?? right.createdAt;
    if (leftDate == null && rightDate == null) {
      return left.ticketNumber.compareTo(right.ticketNumber);
    }
    if (leftDate == null) {
      return 1;
    }
    if (rightDate == null) {
      return -1;
    }
    return rightDate.compareTo(leftDate);
  });
  return filtered;
}
