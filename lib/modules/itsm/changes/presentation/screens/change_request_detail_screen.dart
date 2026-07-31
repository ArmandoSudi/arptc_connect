import 'package:arptc_connect/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/changes_application.dart';
import '../../domain/changes_domain.dart';
import '../../../shared/application/itsm_providers.dart';
import '../../../shared/data/trusted_command_gateways.dart';
import '../../../shared/domain/itsm_common.dart';
import '../change_presentation_strings.dart';
import '../widgets/change_action_dialogs.dart';
import '../widgets/change_async_view.dart';
import '../widgets/change_collaboration_panel.dart';
import '../widgets/change_page_shell.dart';
import '../widgets/change_request_views.dart';

class ChangeRequestDetailScreen extends ConsumerStatefulWidget {
  const ChangeRequestDetailScreen({
    required this.changeId,
    super.key,
    this.onBack,
  });

  final String changeId;
  final VoidCallback? onBack;

  @override
  ConsumerState<ChangeRequestDetailScreen> createState() =>
      _ChangeRequestDetailScreenState();
}

class _ChangeRequestDetailScreenState
    extends ConsumerState<ChangeRequestDetailScreen> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final change = ref.watch(changeRequestProvider(widget.changeId));
    return ChangePageShell(
      title: l10n.changeRequestDetails,
      subtitle: l10n.changeManagementSubtitle,
      onBack: widget.onBack,
      child: ChangeAsyncView<ChangeRequest?>(
        value: change,
        loadingLabel: l10n.loading,
        retryLabel: l10n.retry,
        onRetry: () => ref.invalidate(changeRequestProvider(widget.changeId)),
        data: (value) => value == null
            ? ChangeSurfaceCard(
                child: Text(
                  l10n.changeEmptyDescription,
                  textAlign: TextAlign.center,
                ),
              )
            : _buildDetail(context, value),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, ChangeRequest change) {
    final l10n = S.of(context);
    final session = ref.watch(itsmSessionProvider).valueOrNull;
    final manager = session?.role == ItsmRole.manager;
    final actions = _actions(context, change, manager);
    final collaborationRequest = ChangeCollaborationRequest(
      changeId: change.id,
    );
    final comments = ref.watch(changeCommentsProvider(collaborationRequest));
    final attachments =
        ref.watch(changeAttachmentsProvider(collaborationRequest));
    final activity =
        ref.watch(changeAuditTimelineProvider(collaborationRequest));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChangeSurfaceCard(
          title: change.title,
          subtitle: change.changeNumber,
          trailing: ChangeStatusBadge(status: change.status),
          child: LayoutBuilder(
            builder: (context, constraints) => Stepper(
              type: constraints.maxWidth < 780
                  ? StepperType.vertical
                  : StepperType.horizontal,
              currentStep: _stepFor(change.status),
              controlsBuilder: (_, __) => const SizedBox.shrink(),
              steps: [
                _step(l10n.changeStatusDraft, 0, change.status),
                _step(l10n.changeStatusAssessment, 1, change.status),
                _step(l10n.changeStatusAwaitingApproval, 2, change.status),
                _step(l10n.changeStatusScheduled, 3, change.status),
                _step(l10n.changeStatusImplementation, 4, change.status),
                _step(l10n.changeStatusReview, 5, change.status),
                _step(l10n.changeStatusClosed, 6, change.status),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        ChangeSurfaceCard(
          child: Wrap(
            spacing: 28,
            runSpacing: 18,
            children: [
              _fact(l10n.changeType, l10n.changeTypeLabel(change.type)),
              _fact(l10n.changeRequester, change.requester.name),
              _fact(l10n.changeOwner, change.owner?.name ?? '-'),
              _fact(l10n.impact, change.impact.value),
              _fact(l10n.urgency, change.urgency.value),
              _fact(l10n.changeRisk, l10n.changeRiskLabel(change.risk)),
              _fact(l10n.changeRevision, '${change.revision}'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ChangeSurfaceCard(
          title: l10n.description,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(change.description),
              const SizedBox(height: 16),
              Text(
                l10n.changeJustification,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(change.justification),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ChangeSurfaceCard(
          title: l10n.implementationPlan,
          child: _plans(change),
        ),
        if (_hasRelatedRecords(change)) ...[
          const SizedBox(height: 18),
          ChangeSurfaceCard(
            title: l10n.changeRelatedRecords,
            child: Wrap(
              spacing: 28,
              runSpacing: 16,
              children: [
                if (change.affectedServices.isNotEmpty)
                  _fact(
                    l10n.affectedServices,
                    change.affectedServices.map((item) => item.name).join(', '),
                  ),
                if (change.affectedCiIds.isNotEmpty)
                  _fact(
                    l10n.affectedConfigurationItems,
                    change.affectedCiIds.join(', '),
                  ),
                if (change.affectedAssetIds.isNotEmpty)
                  _fact(
                      l10n.affectedAssets, change.affectedAssetIds.join(', ')),
                if (change.relatedIncidentIds.isNotEmpty)
                  _fact(l10n.relatedIncidentIds,
                      change.relatedIncidentIds.join(', ')),
                if (change.relatedRequestIds.isNotEmpty)
                  _fact(l10n.relatedRequestIds,
                      change.relatedRequestIds.join(', ')),
              ],
            ),
          ),
        ],
        if (change.plannedWindow != null) ...[
          const SizedBox(height: 18),
          ChangeSurfaceCard(
            title: l10n.changeCalendarTitle,
            child: Wrap(
              spacing: 28,
              runSpacing: 16,
              children: [
                _fact(
                  l10n.plannedStart,
                  _date(change.plannedWindow!.startsAt),
                ),
                _fact(l10n.plannedEnd, _date(change.plannedWindow!.endsAt)),
                _fact(
                  l10n.expectedDowntime,
                  '${change.plannedWindow!.expectedDowntimeMinutes}',
                ),
              ],
            ),
          ),
        ],
        if (change.implementationResult != null) ...[
          const SizedBox(height: 18),
          ChangeSurfaceCard(
            title: l10n.changeImplementationResult,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.changeImplementationOutcomeLabel(
                    change.implementationResult!.outcome,
                  ),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(change.implementationResult!.summary),
              ],
            ),
          ),
        ],
        if (change.postImplementationReview != null) ...[
          const SizedBox(height: 18),
          ChangeSurfaceCard(
            title: l10n.changePostImplementationReview,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.changeReviewOutcomeLabel(
                    change.postImplementationReview!.outcome,
                  ),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(change.postImplementationReview!.summary),
              ],
            ),
          ),
        ],
        if (manager) ...[
          const SizedBox(height: 18),
          _cabMeetings(change),
        ],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 18),
          ChangeSurfaceCard(
            child: Wrap(spacing: 10, runSpacing: 10, children: actions),
          ),
        ],
        const SizedBox(height: 18),
        ChangeCollaborationPanel(
          comments: comments,
          attachments: attachments,
          activity: activity,
          showOperationalVisibility: manager,
          onRetryComments: () =>
              ref.invalidate(changeCommentsProvider(collaborationRequest)),
          onRetryAttachments: () =>
              ref.invalidate(changeAttachmentsProvider(collaborationRequest)),
          onRetryActivity: () =>
              ref.invalidate(changeAuditTimelineProvider(collaborationRequest)),
        ),
      ],
    );
  }

  bool _hasRelatedRecords(ChangeRequest change) =>
      change.affectedServices.isNotEmpty ||
      change.affectedCiIds.isNotEmpty ||
      change.affectedAssetIds.isNotEmpty ||
      change.relatedIncidentIds.isNotEmpty ||
      change.relatedRequestIds.isNotEmpty;

  Widget _cabMeetings(ChangeRequest change) {
    final l10n = S.of(context);
    final meetings = ref.watch(changeCabMeetingsProvider(change.id));
    return ChangeSurfaceCard(
      title: l10n.cabMeetings,
      child: ChangeAsyncView<List<CabMeeting>>(
        value: meetings,
        loadingLabel: l10n.loading,
        retryLabel: l10n.retry,
        onRetry: () => ref.invalidate(changeCabMeetingsProvider(change.id)),
        data: (items) {
          if (items.isEmpty) return Text(l10n.noCabMeetings);
          return Column(
            children: [
              for (final meeting in items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.groups_2_outlined),
                  title: Text(meeting.title),
                  subtitle: Text(
                    '${_date(meeting.scheduledAt)} • '
                    '${meeting.participants.map((item) => item.name).join(', ')}',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _plans(ChangeRequest change) {
    final l10n = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _plan(l10n.implementationPlan, change.plans.implementationPlan),
        _plan(l10n.testPlan, change.plans.testPlan),
        _plan(l10n.communicationPlan, change.plans.communicationPlan),
        _plan(l10n.rollbackPlan, change.plans.rollbackPlan),
      ],
    );
  }

  Widget _plan(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(value.trim().isEmpty ? '-' : value),
          ],
        ),
      );

  List<Widget> _actions(
    BuildContext context,
    ChangeRequest change,
    bool manager,
  ) {
    final l10n = S.of(context);
    final actions = <Widget>[];
    if (change.status == ChangeStatus.draft) {
      actions.add(
        FilledButton.icon(
          onPressed: _submitting
              ? null
              : () => _execute(change, ChangeCommandType.submit),
          icon: const Icon(Icons.send_outlined),
          label: Text(l10n.submitChange),
        ),
      );
    }
    if (manager &&
        (change.status == ChangeStatus.submitted ||
            change.status == ChangeStatus.assessment)) {
      actions.add(
        FilledButton.icon(
          onPressed: _submitting ? null : () => _assess(change),
          icon: const Icon(Icons.fact_check_outlined),
          label: Text(l10n.assessChange),
        ),
      );
    }
    if (manager && change.status == ChangeStatus.assessment) {
      actions.add(
        FilledButton.icon(
          onPressed: _submitting
              ? null
              : () => _execute(change, ChangeCommandType.requestApproval),
          icon: const Icon(Icons.approval_outlined),
          label: Text(l10n.requestChangeApproval),
        ),
      );
    }
    if (manager && change.status == ChangeStatus.awaitingApproval) {
      actions.add(
        OutlinedButton.icon(
          onPressed: _submitting ? null : () => _saveCabMeeting(change),
          icon: const Icon(Icons.groups_2_outlined),
          label: Text(l10n.scheduleCabMeeting),
        ),
      );
    }
    if (manager && change.status == ChangeStatus.approved) {
      actions.add(
        FilledButton.icon(
          onPressed: _submitting ? null : () => _schedule(change),
          icon: const Icon(Icons.event_available_outlined),
          label: Text(l10n.scheduleChange),
        ),
      );
    }
    if (manager && change.status == ChangeStatus.scheduled) {
      actions.add(
        FilledButton.icon(
          onPressed: _submitting
              ? null
              : () => _execute(
                    change,
                    ChangeCommandType.startImplementation,
                    payload: const {'comment': ''},
                  ),
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(l10n.startImplementation),
        ),
      );
    }
    if (manager && change.status == ChangeStatus.implementation) {
      actions.add(
        FilledButton.icon(
          onPressed: _submitting ? null : () => _implementation(change),
          icon: const Icon(Icons.task_alt_rounded),
          label: Text(l10n.recordImplementation),
        ),
      );
    }
    if (manager && change.status == ChangeStatus.review) {
      actions.add(
        FilledButton.icon(
          onPressed: _submitting ? null : () => _review(change),
          icon: const Icon(Icons.rate_review_outlined),
          label: Text(l10n.recordPostImplementationReview),
        ),
      );
      if (change.postImplementationReview != null) {
        actions.add(
          OutlinedButton.icon(
            onPressed: _submitting
                ? null
                : () => _execute(
                      change,
                      ChangeCommandType.close,
                      payload: const {'comment': ''},
                    ),
            icon: const Icon(Icons.lock_outline_rounded),
            label: Text(l10n.closeChange),
          ),
        );
      }
    }
    if (!change.isTerminal) {
      actions.add(
        TextButton.icon(
          onPressed: _submitting ? null : () => _cancel(change),
          icon: const Icon(Icons.cancel_outlined),
          label: Text(l10n.cancelChange),
        ),
      );
    }
    return actions;
  }

  Future<void> _assess(ChangeRequest change) async {
    final payload = await showChangeAssessmentDialog(context, change);
    if (payload != null) {
      await _execute(change, ChangeCommandType.assess, payload: payload);
    }
  }

  Future<void> _saveCabMeeting(ChangeRequest change) async {
    final payload = await showCabMeetingDialog(context);
    if (payload != null) {
      await _execute(change, ChangeCommandType.saveCabMeeting,
          payload: payload);
    }
  }

  Future<void> _schedule(ChangeRequest change) async {
    final payload = await showChangeScheduleDialog(context);
    if (payload != null) {
      await _execute(change, ChangeCommandType.schedule, payload: payload);
    }
  }

  Future<void> _implementation(ChangeRequest change) async {
    final payload = await showChangeDecisionDialog(
      context,
      title: S.of(context).recordImplementation,
      decisions: const ['succeeded', 'failed', 'rolled_back'],
    );
    if (payload == null) return;
    await _execute(
      change,
      ChangeCommandType.recordImplementationResult,
      payload: {
        'outcome': payload['decision'],
        'summary': payload['comment'],
        'evidenceAttachmentIds': <String>[],
      },
    );
  }

  Future<void> _review(ChangeRequest change) async {
    final payload = await showChangeDecisionDialog(
      context,
      title: S.of(context).recordPostImplementationReview,
      decisions: const ['successful', 'partial', 'unsuccessful'],
    );
    if (payload == null) return;
    await _execute(
      change,
      ChangeCommandType.recordPostImplementationReview,
      payload: {
        'outcome': payload['decision'],
        'summary': payload['comment'],
        'lessonsLearned': '',
        'followUpActions': payload['conditions'],
        'evidenceAttachmentIds': <String>[],
      },
    );
  }

  Future<void> _cancel(ChangeRequest change) async {
    final reason = await showChangeReasonDialog(
      context,
      title: S.of(context).cancelChange,
    );
    if (reason != null) {
      await _execute(
        change,
        ChangeCommandType.cancel,
        payload: {'reason': reason},
      );
    }
  }

  Future<void> _execute(
    ChangeRequest change,
    ChangeCommandType type, {
    Map<String, Object?> payload = const {},
  }) async {
    setState(() => _submitting = true);
    try {
      final session = await ref.read(itsmSessionProvider.future);
      if (session == null) return;
      final controller = await ref.read(changeCommandControllerProvider.future);
      final nonce = DateTime.now().microsecondsSinceEpoch;
      await controller.execute(
        ChangeCommand(
          context: ItsmCommandContext(
            idempotencyKey: '${type.command}-${change.id}-$nonce',
            correlationId: change.id,
            actorUserId: session.userId,
            actorRole: session.role,
            actorDisplayName: session.displayName,
          ),
          type: type,
          payload: {
            'changeId': change.id,
            'expectedRevision': change.revision,
            ...payload,
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  Step _step(String title, int index, ChangeStatus status) {
    final current = _stepFor(status);
    return Step(
      title: Text(title),
      content: const SizedBox.shrink(),
      isActive: current >= index,
      state: current > index ? StepState.complete : StepState.indexed,
    );
  }

  int _stepFor(ChangeStatus status) => switch (status) {
        ChangeStatus.draft || ChangeStatus.submitted => 0,
        ChangeStatus.assessment => 1,
        ChangeStatus.awaitingApproval || ChangeStatus.approved => 2,
        ChangeStatus.scheduled => 3,
        ChangeStatus.implementation ||
        ChangeStatus.failed ||
        ChangeStatus.rolledBack =>
          4,
        ChangeStatus.review => 5,
        ChangeStatus.closed ||
        ChangeStatus.rejected ||
        ChangeStatus.cancelled =>
          6,
      };

  Widget _fact(String label, String value) => SizedBox(
        width: 190,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      );

  String _date(DateTime value) => DateFormat.yMMMd().add_Hm().format(value);
}
