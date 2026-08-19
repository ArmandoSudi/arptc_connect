import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/application/organization_timeline_accumulator.dart';
import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_assignment.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_query.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/organization_load_more_button.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrganizationAssignmentHistoryCard extends ConsumerStatefulWidget {
  const OrganizationAssignmentHistoryCard({
    required this.query,
    this.showAgentId = false,
    super.key,
  });

  final OrganizationAssignmentQuery query;
  final bool showAgentId;

  @override
  ConsumerState<OrganizationAssignmentHistoryCard> createState() =>
      _OrganizationAssignmentHistoryCardState();
}

class _OrganizationAssignmentHistoryCardState
    extends ConsumerState<OrganizationAssignmentHistoryCard> {
  late final OrganizationTimelineAccumulator<OrganizationAssignment> _pages;
  bool _loadingMore = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _pages = OrganizationTimelineAccumulator(idOf: (item) => item.id);
  }

  @override
  void didUpdateWidget(covariant OrganizationAssignmentHistoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _pages.reset();
      _loadError = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final firstPage = ref.watch(
      widget.query.isAgentQuery
          ? umAgentOrganizationAssignmentsProvider(widget.query)
          : umUnitOrganizationAssignmentsProvider(widget.query),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.lookup('umAssignmentHistory'),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            firstPage.when(
              loading: () => LoadingStateView(
                message: l10n.lookup('umLoading'),
              ),
              error: (error, _) => ErrorStateView(
                title: l10n.lookup('umCommandFailed'),
                description: error.toString(),
              ),
              data: _buildHistory,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory(List<OrganizationAssignment> firstPage) {
    final l10n = S.of(context);
    _pages.seedCursor(
      firstPage: firstPage,
      pageSize: widget.query.limit,
      timestampOf: (item) => item.startsAt,
    );
    final assignments = _pages.mergeFirstPage(firstPage);
    if (assignments.isEmpty) {
      return Text(l10n.lookup('umNoAssignmentHistory'));
    }
    return Column(
      children: [
        for (final assignment in assignments)
          _AssignmentHistoryTile(
            assignment: assignment,
            showAgentId: widget.showAgentId,
          ),
        if (_pages.hasMore || _loadError != null)
          OrganizationLoadMoreButton(
            loading: _loadingMore,
            error: _loadError,
            onPressed: _loadMore,
          ),
      ],
    );
  }

  Future<void> _loadMore() async {
    final cursor = _pages.nextCursor;
    if (_loadingMore || cursor == null) return;
    setState(() {
      _loadingMore = true;
      _loadError = null;
    });
    try {
      final page = await ref
          .read(userManagementRepositoryProvider)
          .fetchOrganizationAssignmentsPage(
            query: widget.query,
            page: OrganizationTimelinePageRequest(
              limit: widget.query.limit,
              afterTimestamp: cursor.timestamp,
              afterId: cursor.id,
            ),
          );
      if (mounted) setState(() => _pages.append(page));
    } catch (error) {
      if (mounted) setState(() => _loadError = error.toString());
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }
}

class _AssignmentHistoryTile extends StatelessWidget {
  const _AssignmentHistoryTile({
    required this.assignment,
    required this.showAgentId,
  });

  final OrganizationAssignment assignment;
  final bool showAgentId;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final dates = MaterialLocalizations.of(context);
    final title = showAgentId ? assignment.agentId : assignment.unitName;
    final end = assignment.endsAt == null
        ? ''
        : ' – ${dates.formatShortDate(assignment.endsAt!.toLocal())}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        assignment.assignmentType == OrganizationAssignmentType.head
            ? Icons.workspace_premium_outlined
            : Icons.badge_outlined,
      ),
      title: Text(title.isEmpty ? assignment.unitId : title),
      subtitle: Text(
        '${assignment.assignmentType.value} · ${assignment.status.value}\n'
        '${dates.formatShortDate(assignment.startsAt.toLocal())}$end'
        '${assignment.reason.isEmpty ? '' : ' · ${assignment.reason}'}',
      ),
      isThreeLine: true,
      trailing: assignment.isActing
          ? Tooltip(
              message: l10n.lookup('umActingHead'),
              child: const Icon(Icons.history_toggle_off),
            )
          : null,
    );
  }
}
