import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_assignment.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_query.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_unit.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/utils/organization_leadership_action.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/utils/user_management_command_feedback.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/organization_dialogs.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/organization_assignment_history_card.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/organization_unit_dialogs.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/user_management_access_gate.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/user_management_section_scaffold.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OrganizationUnitDetailsScreen extends ConsumerWidget {
  const OrganizationUnitDetailsScreen({
    required this.organizationId,
    required this.unitId,
    super.key,
  });

  final String organizationId;
  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final unit = ref.watch(umOrganizationUnitDetailsProvider(
      OrganizationUnitIdentity(
        organizationId: organizationId,
        unitId: unitId,
      ),
    ));
    final assignments = ref.watch(umUnitOrganizationAssignmentsProvider(
      OrganizationAssignmentQuery.unit(
        organizationId: organizationId,
        unitId: unitId,
      ),
    ));
    return UserManagementAccessGate(
      requirePrivateProfiles: true,
      child: UserManagementSectionScaffold(
        selectedIndex: 1,
        title: l10n.lookup('umOrganizationUnit'),
        subtitle: l10n.lookup('umStructureDescription'),
        primaryAction: OutlinedButton.icon(
          onPressed: () => context.go('/service/usermanagement/structure'),
          icon: const Icon(Icons.arrow_back),
          label: Text(l10n.back),
        ),
        primaryActionIsNavigation: true,
        body: unit.when(
          loading: () => LoadingStateView(message: l10n.lookup('umLoading')),
          error: (error, _) => ErrorStateView(
            title: l10n.lookup('umCommandFailed'),
            description: error.toString(),
          ),
          data: (unit) => assignments.when(
              loading: () =>
                  LoadingStateView(message: l10n.lookup('umLoading')),
              error: (error, _) => ErrorStateView(
                title: l10n.lookup('umCommandFailed'),
                description: error.toString(),
              ),
              data: (history) => _UnitDetailsBody(
                unit: unit,
                assignments: history,
                canManage: ref
                    .watch(userManagementAccessPolicyProvider)
                    .canManageOrganization,
                onEdit: () => _edit(context, ref, unit),
                onAssignLeadership: () => assignOrganizationUnitLeadership(
                  context,
                  ref,
                  unit: unit,
                ),
                onEndLeadership: (assignment) =>
                    _endLeadership(context, ref, assignment),
              ),
            ),
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    OrganizationUnit unit,
  ) async {
    final l10n = S.of(context);
    final result = await showOrganizationUnitFormDialog(
      context,
      type: unit.type,
      unit: unit,
      onSubmit: (form) => ref
          .read(umOrganizationCommandControllerProvider.notifier)
          .runOrThrow<void>(
            action: 'updateOrganizationUnit',
            command: () => ref
                .read(userManagementRepositoryProvider)
                .updateOrganizationUnit(_updatedUnit(unit, form)),
          ),
      submissionErrorBuilder: (error) =>
          userManagementCommandErrorMessage(l10n, error),
      onSubmissionError: (error, stackTrace) =>
          reportUserManagementCommandError(
        context,
        operation: 'updateOrganizationUnit',
        error: error,
        stackTrace: stackTrace,
      ),
    );
    if (result == null || !context.mounted) return;
    _feedback(context, ref, l10n.lookup('umUnitUpdated'));
  }

  Future<void> _endLeadership(
    BuildContext context,
    WidgetRef ref,
    OrganizationAssignment assignment,
  ) async {
    final l10n = S.of(context);
    final reason = await showOrganizationReasonDialog(
      context,
      title: l10n.lookup('umEndLeadership'),
      description: l10n.lookup('umLeadership'),
      reasonLabel: l10n.lookup('umLeadershipReason'),
      confirmLabel: l10n.confirm,
    );
    if (reason == null || !context.mounted) return;
    await ref.read(umOrganizationCommandControllerProvider.notifier).run<void>(
          action: 'endOrganizationUnitHead',
          command: () => ref
              .read(userManagementRepositoryProvider)
              .endOrganizationUnitHead(
                organizationId: organizationId,
                assignmentId: assignment.id,
                reason: reason,
              ),
        );
    if (context.mounted) {
      _feedback(context, ref, l10n.lookup('umLeadershipUpdated'));
    }
  }
}

OrganizationUnit _updatedUnit(
  OrganizationUnit unit,
  OrganizationUnitFormResult result,
) {
  return OrganizationUnit(
    id: unit.id,
    organizationId: unit.organizationId,
    type: unit.type,
    code: result.code,
    name: result.name,
    description: result.description,
    parentUnitId: unit.parentUnitId,
    parentUnitType: unit.parentUnitType,
    ancestorUnitIds: unit.ancestorUnitIds,
    pathUnitIds: unit.pathUnitIds,
    pathNames: unit.pathNames,
    depth: unit.depth,
    scopeKeys: unit.scopeKeys,
    status: result.status,
    headUserId: unit.headUserId,
    headAssignmentId: unit.headAssignmentId,
    actingHeadUserId: unit.actingHeadUserId,
    actingHeadAssignmentId: unit.actingHeadAssignmentId,
    actingHeadEndsAt: unit.actingHeadEndsAt,
  );
}

class _UnitDetailsBody extends StatelessWidget {
  const _UnitDetailsBody({
    required this.unit,
    required this.assignments,
    required this.canManage,
    required this.onEdit,
    required this.onAssignLeadership,
    required this.onEndLeadership,
  });

  final OrganizationUnit unit;
  final List<OrganizationAssignment> assignments;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onAssignLeadership;
  final ValueChanged<OrganizationAssignment> onEndLeadership;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(child: Icon(_unitIcon(unit.type))),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unit.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(unit.breadcrumb),
                        ],
                      ),
                    ),
                    if (canManage)
                      IconButton(
                        tooltip: l10n.edit,
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                  ],
                ),
                const Divider(height: 32),
                _Info(label: l10n.lookup('umUnitCode'), value: unit.code),
                _Info(label: l10n.lookup('umUnitType'), value: unit.type.value),
                _Info(
                  label: l10n.lookup('umParentUnit'),
                  value: unit.parentUnitId ?? '-',
                ),
                _Info(
                  label: l10n.lookup('umOrganizationDescription'),
                  value: unit.description.isEmpty ? '-' : unit.description,
                ),
                _Info(label: l10n.status, value: unit.status.value),
                _Info(label: 'ID', value: unit.id),
                _Info(
                  label: l10n.lookup('umOrganizationPath'),
                  value: unit.breadcrumb,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.lookup('umLeadership'),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (canManage &&
                        ((unit.headAssignmentId ?? '').trim().isEmpty ||
                            (unit.actingHeadAssignmentId ?? '').trim().isEmpty))
                      FilledButton.tonalIcon(
                        key: const Key('assign-unit-leadership'),
                        onPressed: onAssignLeadership,
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        label: Text(l10n.lookup('umAssignHead')),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                ...assignments
                    .where((assignment) =>
                        assignment.assignmentType ==
                        OrganizationAssignmentType.head)
                    .map((assignment) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(assignment.isActing
                              ? Icons.history_toggle_off
                              : Icons.workspace_premium_outlined),
                          title: Text(assignment.agentId),
                          subtitle: Text(
                            '${assignment.isActing ? l10n.lookup('umActingHead') : l10n.lookup('umPermanentHead')} · '
                            '${assignment.status.value}',
                          ),
                          trailing: canManage && assignment.isCurrent
                              ? TextButton(
                                  onPressed: () => onEndLeadership(assignment),
                                  child: Text(l10n.lookup('umEndLeadership')),
                                )
                              : null,
                        )),
                if (!assignments.any((assignment) =>
                    assignment.assignmentType ==
                    OrganizationAssignmentType.head))
                  Text(l10n.lookup('umNoAssignmentHistory')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        OrganizationAssignmentHistoryCard(
          query: OrganizationAssignmentQuery.unit(
            organizationId: unit.organizationId,
            unitId: unit.id,
          ),
          showAgentId: true,
        ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

void _feedback(BuildContext context, WidgetRef ref, String success) {
  final error = ref.read(umOrganizationCommandControllerProvider).errorMessage;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error ?? success)),
  );
}

IconData _unitIcon(OrganizationUnitType type) => switch (type) {
      OrganizationUnitType.department => Icons.apartment_outlined,
      OrganizationUnitType.service => Icons.hub_outlined,
      OrganizationUnitType.bureau => Icons.meeting_room_outlined,
      OrganizationUnitType.custom => Icons.account_tree_outlined,
    };
