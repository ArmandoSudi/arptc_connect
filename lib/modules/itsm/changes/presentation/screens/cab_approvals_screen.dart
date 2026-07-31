import 'package:arptc_connect/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/changes_application.dart';
import '../../data/change_repository.dart';
import '../../domain/changes_domain.dart';
import '../../../shared/application/itsm_providers.dart';
import '../../../shared/data/trusted_command_gateways.dart';
import '../change_presentation_strings.dart';
import '../widgets/change_action_dialogs.dart';
import '../widgets/change_async_view.dart';
import '../widgets/change_page_shell.dart';
import '../widgets/change_request_views.dart';

class CabApprovalsScreen extends ConsumerStatefulWidget {
  const CabApprovalsScreen({super.key, this.onBack, this.onSelected});

  final VoidCallback? onBack;
  final ValueChanged<ChangeRequest>? onSelected;

  @override
  ConsumerState<CabApprovalsScreen> createState() => _CabApprovalsScreenState();
}

class _CabApprovalsScreenState extends ConsumerState<CabApprovalsScreen> {
  String? _submittingChangeId;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    const query = ChangeRequestQuery(
      scope: ChangeRequestScope.managerActive,
      status: ChangeStatus.awaitingApproval,
    );
    const request = ChangeFirstPageRequest(query: query, limit: 50);
    final changes = ref.watch(changeFirstPageProvider(request));
    return ChangePageShell(
      title: l10n.cabApprovalsTitle,
      subtitle: l10n.cabApprovalsSubtitle,
      onBack: widget.onBack,
      child: ChangeAsyncView<List<ChangeRequest>>(
        value: changes,
        loadingLabel: l10n.loading,
        retryLabel: l10n.retry,
        onRetry: () => ref.invalidate(changeFirstPageProvider(request)),
        data: (items) {
          if (items.isEmpty) {
            return ChangeRequestListView(
              changes: items,
              onSelected: (_) {},
            );
          }
          return Column(
            children: [
              for (final change in items) ...[
                ChangeSurfaceCard(
                  title: change.title,
                  subtitle: '${change.changeNumber} • '
                      '${l10n.changeRiskLabel(change.risk)}',
                  trailing: ChangeStatusBadge(status: change.status),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(change.justification),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: widget.onSelected == null
                                ? null
                                : () => widget.onSelected!(change),
                            child: Text(l10n.changeRequestDetails),
                          ),
                          FilledButton.icon(
                            onPressed: _submittingChangeId == change.id
                                ? null
                                : () => _decide(change),
                            icon: const Icon(Icons.how_to_vote_outlined),
                            label: Text(l10n.approveChange),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _decide(ChangeRequest change) async {
    final approvalId = change.activeApprovalId;
    if (approvalId == null || approvalId.isEmpty) return;
    final decision = await showChangeDecisionDialog(
      context,
      title: S.of(context).cabApprovalsTitle,
      decisions: const ['approved', 'rejected', 'clarification_requested'],
    );
    if (decision == null) return;
    setState(() => _submittingChangeId = change.id);
    try {
      final session = await ref.read(itsmSessionProvider.future);
      if (session == null) return;
      final controller = await ref.read(changeCommandControllerProvider.future);
      final nonce = DateTime.now().microsecondsSinceEpoch;
      await controller.execute(
        ChangeCommand(
          context: ItsmCommandContext(
            idempotencyKey: 'change-approval-${change.id}-$nonce',
            correlationId: change.id,
            actorUserId: session.userId,
            actorRole: session.role,
            actorDisplayName: session.displayName,
          ),
          type: ChangeCommandType.decideApproval,
          payload: {
            'changeId': change.id,
            'approvalId': approvalId,
            'expectedRevision': change.revision,
            'decision': decision['decision'],
            'comment': decision['comment'],
            'conditions': decision['conditions'],
          },
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).changeCommandSuccessful)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _submittingChangeId = null);
    }
  }
}
