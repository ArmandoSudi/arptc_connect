import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_query.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_unit.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/utils/user_management_command_feedback.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/organization_unit_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<bool> assignOrganizationUnitLeadership(
  BuildContext context,
  WidgetRef ref, {
  required OrganizationUnit unit,
}) async {
  final allowPermanent = (unit.headAssignmentId ?? '').trim().isEmpty;
  final allowActing = (unit.actingHeadAssignmentId ?? '').trim().isEmpty;
  if (!allowPermanent && !allowActing) return false;

  final l10n = S.of(context);
  try {
    final agents = await ref.read(
      umFilteredAgentDirectoryProvider(
        AgentDirectoryListQuery(
          organizationId: unit.organizationId,
          scopeUnitId: unit.id,
          status: AgentDirectoryStatusFilter.active,
          limit: OrganizationPageRequest.maximumLimit,
        ),
      ).future,
    );
    if (!context.mounted) return false;
    if (agents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.lookup('umNoAgents'))),
      );
      return false;
    }

    final result = await showOrganizationHeadDialog(
      context,
      agents: agents,
      allowPermanent: allowPermanent,
      allowActing: allowActing,
      onSubmit: (form) => ref
          .read(umOrganizationCommandControllerProvider.notifier)
          .runOrThrow<void>(
            action: 'setOrganizationUnitHead',
            command: () => ref
                .read(userManagementRepositoryProvider)
                .setOrganizationUnitHead(
                  organizationId: unit.organizationId,
                  unitId: unit.id,
                  agentId: form.agentId,
                  startsAt: form.startsAt,
                  endsAt: form.endsAt,
                  isActing: form.isActing,
                  reason: form.reason,
                ),
          ),
      submissionErrorBuilder: (error) =>
          userManagementCommandErrorMessage(l10n, error),
      onSubmissionError: (error, stackTrace) =>
          reportUserManagementCommandError(
        context,
        operation: 'setOrganizationUnitHead',
        error: error,
        stackTrace: stackTrace,
      ),
    );
    if (result == null || !context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.lookup('umLeadershipUpdated'))),
    );
    return true;
  } catch (error, stackTrace) {
    if (context.mounted) {
      reportUserManagementCommandError(
        context,
        operation: 'loadOrganizationLeadershipCandidates',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return false;
  }
}
