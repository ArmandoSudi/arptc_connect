import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_enums.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_resolution_code.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_ticket.dart';
import 'package:arptc_connect/modules/incident_management/presentation/incident_localizations.dart';
import 'package:arptc_connect/modules/incident_management/presentation/controllers/incident_providers.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_priority_badge.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_status_badge.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_timeline.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MyIncidentDetailsScreen extends ConsumerWidget {
  const MyIncidentDetailsScreen({
    required this.ticketId,
    this.showInternalNotes = false,
    super.key,
  });

  final String ticketId;
  final bool showInternalNotes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(incidentTicketProvider(ticketId));
    final commentsAsync = ref.watch(incidentCommentsProvider(ticketId));
    final logsAsync = ref.watch(incidentAuditLogsProvider(ticketId));
    final resolutionCodes =
        ref.watch(incidentResolutionCodesProvider).valueOrNull ?? [];
    final l10n = S.of(context);

    return Scaffold(
      body: ContentView(
        maxWidth: 980,
        child: ticketAsync.when(
          data: (ticket) {
            if (ticket == null) {
              return EmptyStateView(
                icon: Icons.confirmation_number_outlined,
                title: l10n.incidentNotFound,
              );
            }
            return SingleChildScrollView(
              child: Column(
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
                          title: ticket.ticketNumber.isEmpty
                              ? l10n.ticketDetails
                              : ticket.ticketNumber,
                          description: ticket.title,
                        ),
                      ),
                      IncidentStatusBadge(status: ticket.status),
                      const SizedBox(width: 8),
                      IncidentPriorityBadge(priority: ticket.priority),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DetailsCard(
                    ticket: ticket,
                    resolutionCodes: resolutionCodes,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.timeline,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          IncidentTimeline(
                            comments: commentsAsync.valueOrNull ?? const [],
                            auditLogs: logsAsync.valueOrNull ?? const [],
                            showInternalNotes: showInternalNotes,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => LoadingStateView(message: l10n.loadingIncident),
          error: (error, _) => ErrorStateView(
            title: l10n.unableToLoadIncident,
            description: error.toString(),
            onRetry: () => ref.invalidate(incidentTicketProvider(ticketId)),
          ),
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.ticket,
    required this.resolutionCodes,
  });

  final IncidentTicket ticket;
  final List<IncidentResolutionCode> resolutionCodes;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ticket.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            _FieldGrid(
              rows: [
                _FieldValue(l10n.createdBy, ticket.createdByName),
                _FieldValue(l10n.email, ticket.createdByEmail),
                _FieldValue(l10n.department, ticket.createdByDepartmentName),
                _FieldValue(l10n.service, ticket.createdByServiceName),
                _FieldValue(l10n.affectedService, ticket.affectedServiceName),
                _FieldValue(l10n.location, ticket.location),
                _FieldValue(l10n.deviceType, ticket.deviceType),
                _FieldValue(l10n.assetId, ticket.assetId),
                _FieldValue(
                  l10n.blocking,
                  ticket.isBlocking ? l10n.yes : l10n.no,
                ),
                _FieldValue(l10n.category, ticket.categoryName),
                _FieldValue(l10n.subcategory, ticket.subcategoryName),
                _FieldValue(
                  l10n.impact,
                  _localizedImpactValue(l10n, ticket.impact),
                ),
                _FieldValue(
                  l10n.urgency,
                  _localizedUrgencyValue(l10n, ticket.urgency),
                ),
                _FieldValue(l10n.assignedTo, ticket.assignedToName),
                _FieldValue(
                  l10n.resolutionCode,
                  _localizedResolutionCode(
                    context,
                    ticket.resolutionCode,
                    resolutionCodes,
                  ),
                ),
                _FieldValue(l10n.resolutionSummary, ticket.resolutionSummary),
                _FieldValue(l10n.createdAt, _formatDate(ticket.createdAt)),
                _FieldValue(l10n.closedAt, _formatDate(ticket.closedAt)),
                _FieldValue(
                  l10n.archiveEligible,
                  _formatDate(ticket.archiveEligibleAt),
                ),
              ],
            ),
            if (ticket.userImpactDescription.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.impactDescription,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(ticket.userImpactDescription),
            ],
          ],
        ),
      ),
    );
  }
}

class _FieldGrid extends StatelessWidget {
  const _FieldGrid({
    required this.rows,
  });

  final List<_FieldValue> rows;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 720 ? 2 : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: columns == 2 ? 5.2 : 7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 8,
          children: rows
              .where((row) => row.value.trim().isNotEmpty)
              .map(
                (row) => _InfoTile(
                  label: row.label,
                  value: row.value,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _FieldValue {
  const _FieldValue(this.label, this.value);

  final String label;
  final String value;
}

String _formatDate(DateTime? date) {
  if (date == null) {
    return '';
  }
  return DateFormat('dd MMM yyyy HH:mm').format(date);
}

String _localizedImpactValue(S l10n, String value) {
  final impact = IncidentImpact.fromValue(value);
  return impact == null ? value : localizedIncidentImpactLabel(l10n, impact);
}

String _localizedUrgencyValue(S l10n, String value) {
  final urgency = IncidentUrgency.fromValue(value);
  return urgency == null ? value : localizedIncidentUrgencyLabel(l10n, urgency);
}

String _localizedResolutionCode(
  BuildContext context,
  String value,
  List<IncidentResolutionCode> resolutionCodes,
) {
  final normalized = IncidentResolutionCode.normalizeCode(value);
  if (normalized.isEmpty) {
    return '';
  }
  IncidentResolutionCode? resolutionCode;
  for (final item in resolutionCodes) {
    if (item.code == normalized) {
      resolutionCode = item;
      break;
    }
  }
  return resolutionCode?.labelForLanguageCode(
        Localizations.localeOf(context).languageCode,
      ) ??
      normalized;
}
