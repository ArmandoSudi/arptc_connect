import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/domain/modules.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_query.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_agent.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/entity_details_providers.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/utils/user_management_command_feedback.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/organization_agent_dialogs.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/organization_assignment_history_card.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/organization_dialogs.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/user_management_access_gate.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/user_management_section_scaffold.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AgentDetailsScreen extends ConsumerWidget {
  const AgentDetailsScreen({required this.agentId, super.key});

  final String agentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final agent = ref.watch(umAgentDetailsProvider(agentId));
    final policy = ref.watch(userManagementAccessPolicyProvider);
    return UserManagementAccessGate(
      requirePrivateProfiles: true,
      child: UserManagementSectionScaffold(
        selectedIndex: 2,
        title: l10n.lookup('umAgentDetails'),
        subtitle: l10n.lookup('umAgentsDescription'),
        primaryAction: agent.maybeWhen(
          data: (value) => FilledButton.icon(
            onPressed: () => _editAgent(context, ref, value),
            icon: const Icon(Icons.edit_outlined),
            label: Text(l10n.edit),
          ),
          orElse: () => null,
        ),
        body: agent.when(
          loading: () => LoadingStateView(message: l10n.lookup('umLoading')),
          error: (error, _) => ErrorStateView(
            title: l10n.lookup('umNotFound'),
            description: error.toString(),
            onRetry: () => ref.invalidate(umAgentDetailsProvider(agentId)),
          ),
          data: (value) => _AgentDetailsContent(
            agent: value,
            canManage: policy.canManageOrganization,
            onBack: () => context.go('/service/usermanagement/agents'),
            onTransfer: () => _transferAgent(context, ref, value),
            onDeactivate: () => _deactivateAgent(context, ref, value),
          ),
        ),
      ),
    );
  }

  Future<void> _editAgent(
    BuildContext context,
    WidgetRef ref,
    UserManagementAgent agent,
  ) async {
    final l10n = S.of(context);
    final result = await showEditOrganizationAgentDialog(
      context,
      agent: agent,
      onSubmit: (form) => ref
          .read(umOrganizationCommandControllerProvider.notifier)
          .runOrThrow<void>(
            action: 'updateAgentAccount',
            command: () => ref
                .read(userManagementRepositoryProvider)
                .updateAgent(_copyProfile(agent, form)),
          ),
      submissionErrorBuilder: (error) =>
          userManagementCommandErrorMessage(l10n, error),
      onSubmissionError: (error, stackTrace) =>
          reportUserManagementCommandError(
        context,
        operation: 'updateAgentAccount',
        error: error,
        stackTrace: stackTrace,
      ),
    );
    if (result == null || !context.mounted) return;
    _feedback(context, ref, l10n.lookup('umAgentProfileUpdated'));
  }

  Future<void> _transferAgent(
    BuildContext context,
    WidgetRef ref,
    UserManagementAgent agent,
  ) async {
    final units = await ref.read(
        umCompleteOrganizationHierarchyProvider(agent.organizationId).future);
    if (!context.mounted) return;
    final result = await showTransferOrganizationAgentDialog(
      context,
      units: units,
      currentUnitId: agent.primaryOrganizationUnitId,
      onSubmit: (form) => ref
          .read(umOrganizationCommandControllerProvider.notifier)
          .runOrThrow<void>(
            action: 'transferAgentOrganization',
            command: () => ref
                .read(userManagementRepositoryProvider)
                .assignAgentOrganization(
                  agentId: agent.id,
                  organizationId: agent.organizationId,
                  unitId: form.unitId,
                  startsAt: form.startsAt,
                  reason: form.reason,
                  transfer: true,
                  assignAsHead: form.assignAsHead,
                ),
          ),
      submissionErrorBuilder: (error) =>
          userManagementCommandErrorMessage(S.of(context), error),
      onSubmissionError: (error, stackTrace) =>
          reportUserManagementCommandError(
        context,
        operation: 'transferAgentOrganization',
        error: error,
        stackTrace: stackTrace,
      ),
    );
    if (result == null || !context.mounted) return;
    _feedback(context, ref, S.of(context).lookup('umAgentTransferred'));
  }

  Future<void> _deactivateAgent(
    BuildContext context,
    WidgetRef ref,
    UserManagementAgent agent,
  ) async {
    final l10n = S.of(context);
    final reason = await showOrganizationReasonDialog(
      context,
      title: l10n.lookup('umDeactivateAgent'),
      description: l10n.lookup('umDeactivateAgentDescription'),
      reasonLabel: l10n.lookup('umDeactivateReason'),
      confirmLabel: l10n.lookup('umDeactivateAgent'),
      destructive: true,
    );
    if (reason == null || !context.mounted) return;
    final success = await ref
        .read(umOrganizationCommandControllerProvider.notifier)
        .runVoid(
          action: 'deactivateAgentAccount',
          command: () =>
              ref.read(userManagementRepositoryProvider).deactivateAgent(
                    agentId: agent.id,
                    organizationId: agent.organizationId,
                    effectiveAt: DateTime.now(),
                    reason: reason,
                  ),
        );
    if (!context.mounted) return;
    _feedback(
      context,
      ref,
      success ? l10n.lookup('umAgentDeactivated') : null,
    );
  }
}

class _AgentDetailsContent extends ConsumerWidget {
  const _AgentDetailsContent({
    required this.agent,
    required this.canManage,
    required this.onBack,
    required this.onTransfer,
    required this.onDeactivate,
  });

  final UserManagementAgent agent;
  final bool canManage;
  final VoidCallback onBack;
  final VoidCallback onTransfer;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentQuery = OrganizationAssignmentQuery.agent(
      organizationId: agent.organizationId,
      agentId: agent.id,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            label: Text(S.of(context).back),
          ),
        ),
        const SizedBox(height: 8),
        _ProfileCard(agent: agent),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 840;
          final placement = _PlacementCard(agent: agent);
          final permissions = _PermissionsCard(agent: agent);
          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                placement,
                const SizedBox(height: 16),
                permissions,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: placement),
              const SizedBox(width: 16),
              Expanded(child: permissions),
            ],
          );
        }),
        const SizedBox(height: 16),
        OrganizationAssignmentHistoryCard(query: assignmentQuery),
        if (canManage && agent.isActive) ...[
          const SizedBox(height: 16),
          _AgentActions(
            onTransfer: onTransfer,
            onDeactivate: onDeactivate,
          ),
        ],
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.agent});
  final UserManagementAgent agent;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final hasPhoto = agent.profilePictureUrl?.isNotEmpty == true;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Wrap(
          spacing: 22,
          runSpacing: 20,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CircleAvatar(
              radius: 42,
              backgroundImage:
                  hasPhoto ? NetworkImage(agent.profilePictureUrl!) : null,
              child: hasPhoto
                  ? null
                  : Text(
                      _initials(agent.displayName),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 260, maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          agent.displayName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Chip(
                        avatar: Icon(
                          agent.isActive ? Icons.check_circle : Icons.block,
                          size: 18,
                        ),
                        label: Text(agent.isActive
                            ? l10n.lookup('umActive')
                            : l10n.lookup('umInactive')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(agent.jobTitle),
                  const SizedBox(height: 10),
                  _IconText(icon: Icons.mail_outline, value: agent.email),
                  _IconText(
                    icon: Icons.badge_outlined,
                    value: '${l10n.matricule}: ${agent.matricule}',
                  ),
                  _IconText(
                    icon: Icons.person_outline,
                    value: '${l10n.lookup('umSex')}: '
                        '${_agentSexLabel(l10n, agent.sex)}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlacementCard extends StatelessWidget {
  const _PlacementCard({required this.agent});
  final UserManagementAgent agent;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return _SectionCard(
      title: l10n.lookup('umCurrentPlacement'),
      icon: Icons.account_tree_outlined,
      children: [
        _DetailRow(
          label: l10n.lookup('umOrganizations'),
          value: agent.organizationName.isEmpty
              ? agent.organizationId
              : agent.organizationName,
        ),
        _DetailRow(
          label: l10n.lookup('umOrganizationUnit'),
          value: agent.primaryOrganizationUnitName,
        ),
        _DetailRow(
          label: l10n.lookup('umUnitType'),
          value: agent.primaryOrganizationUnitType,
        ),
        _DetailRow(
          label: l10n.lookup('umOrganizationPath'),
          value: agent.organizationPathNames.isEmpty
              ? '-'
              : agent.organizationPathNames.join(' / '),
        ),
      ],
    );
  }
}

class _PermissionsCard extends StatelessWidget {
  const _PermissionsCard({required this.agent});
  final UserManagementAgent agent;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final permissions = Modules.normalizePermissions(agent.modulePermissions);
    return _SectionCard(
      title: l10n.lookup('umAccessPermissions'),
      icon: Icons.admin_panel_settings_outlined,
      children: Modules.all
          .map((module) => _DetailRow(
                label: module.name,
                value: Modules.roleLabel(permissions[module.key] ?? 'NONE'),
              ))
          .toList(growable: false),
    );
  }
}

class _AgentActions extends StatelessWidget {
  const _AgentActions({
    required this.onTransfer,
    required this.onDeactivate,
  });
  final VoidCallback onTransfer;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: onTransfer,
              icon: const Icon(Icons.move_up_outlined),
              label: Text(l10n.lookup('umTransferAgent')),
            ),
            TextButton.icon(
              onPressed: onDeactivate,
              icon: const Icon(Icons.person_off_outlined),
              label: Text(l10n.lookup('umDeactivateAgent')),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(icon: icon, title: title),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Flexible(child: Text(value)),
        ],
      ),
    );
  }
}

UserManagementAgent _copyProfile(
  UserManagementAgent agent,
  OrganizationAgentEditResult result,
) {
  return UserManagementAgent(
    id: agent.id,
    firstName: result.firstName,
    name: result.name,
    postName: result.postName,
    matricule: result.matricule,
    sex: result.sex,
    email: result.email,
    emailLower: result.email.toLowerCase(),
    profilePictureUrl: agent.profilePictureUrl,
    jobTitle: result.jobTitle,
    department: agent.department,
    departmentId: agent.departmentId,
    service: agent.service,
    serviceId: agent.serviceId,
    bureau: agent.bureau,
    bureauId: agent.bureauId,
    organizationSchemaVersion: agent.organizationSchemaVersion,
    organizationId: agent.organizationId,
    organizationName: agent.organizationName,
    primaryOrganizationUnitId: agent.primaryOrganizationUnitId,
    primaryOrganizationUnitName: agent.primaryOrganizationUnitName,
    primaryOrganizationUnitType: agent.primaryOrganizationUnitType,
    primaryAssignmentId: agent.primaryAssignmentId,
    organizationAncestorUnitIds: agent.organizationAncestorUnitIds,
    organizationPathUnitIds: agent.organizationPathUnitIds,
    organizationPathNames: agent.organizationPathNames,
    scopeKeys: agent.scopeKeys,
    isActive: agent.isActive,
    modulePermissions: result.modulePermissions,
    createdAt: agent.createdAt,
    updatedAt: agent.updatedAt,
  );
}

String _agentSexLabel(S l10n, AgentSex? sex) {
  return switch (sex) {
    AgentSex.male => l10n.lookup('umMale'),
    AgentSex.female => l10n.lookup('umFemale'),
    null => '-',
  };
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

void _feedback(
  BuildContext context,
  WidgetRef ref,
  String? successMessage,
) {
  final error = ref.read(umOrganizationCommandControllerProvider).errorMessage;
  final message = error ?? successMessage;
  if (message == null || message.isEmpty) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
