import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_providers.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_session.dart';
import 'package:arptc_connect/modules/itsm/shared/data/trusted_command_gateways.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/approval.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/collaboration.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_agent.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/service_request_controller.dart';
import '../../application/support_providers.dart';
import '../../data/service_request_command_gateway.dart';
import '../../domain/service_request.dart';
import '../../domain/service_request_resources.dart';
import '../widgets/service_request_detail_view.dart';

class ServiceRequestDetailScreen extends ConsumerWidget {
  const ServiceRequestDetailScreen({
    required this.requestId,
    super.key,
    this.forceReadOnly = false,
  });

  final String requestId;
  final bool forceReadOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final detail = ref.watch(serviceRequestDetailProvider(requestId));
    final session = ref.watch(itsmSessionProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.itsmServiceRequests)),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorStateView(
          title: l10n.unableToLoad,
          description: error.toString(),
          onRetry: () =>
              ref.invalidate(serviceRequestDetailProvider(requestId)),
        ),
        data: (value) {
          if (value == null) {
            return EmptyStateView(
              icon: Icons.inbox_outlined,
              title: l10n.noDataAvailable,
              description: l10n.noDataDescription,
            );
          }
          final request = value.request;
          final isManager = !forceReadOnly && session?.role == ItsmRole.manager;
          final ownsRequest = session != null &&
              request.requestedForUserId == session.userId &&
              request.selfServiceVisible &&
              request.confidentiality != ItsmConfidentiality.restricted;
          final canSelfCancel = ownsRequest &&
              request.workflowAllowsCancellation &&
              !request.isTerminal &&
              request.status != ServiceRequestStatus.fulfilled;
          final canConfirmCompletion =
              ownsRequest && request.status == ServiceRequestStatus.fulfilled;
          return ServiceRequestDetailView(
            detail: value,
            isManager: isManager,
            canSelfCancel: canSelfCancel,
            canConfirmCompletion: canConfirmCompletion,
            onApprovalDecision: (approvalId, approved) => _decideApproval(
              context,
              ref,
              approvalId: approvalId,
              approved: approved,
              session: session,
            ),
            onAssign: isManager
                ? () => _assign(context, ref, request, session)
                : null,
            onCancel: isManager || canSelfCancel
                ? () => _cancel(context, ref, request, session)
                : null,
            onReject: isManager
                ? () => _reject(context, ref, request, session)
                : null,
            onTransition: isManager
                ? (status) =>
                    _transition(context, ref, request, session, status)
                : null,
            onTaskStatusChanged: isManager
                ? (task, status) =>
                    _updateTask(context, ref, task, status, session)
                : null,
            onAddComment:
                isManager ? () => _addComment(context, ref, session) : null,
            onAddLinkedRecord:
                isManager ? () => _linkRecord(context, ref, session) : null,
            onConfirmCompletion: canConfirmCompletion
                ? () => _confirmCompletion(context, ref, request, session)
                : null,
          );
        },
      ),
    );
  }

  Future<void> _assign(
    BuildContext context,
    WidgetRef ref,
    ServiceRequest request,
    ItsmSession? session,
  ) async {
    if (session == null) return;
    final agent = await showDialog<UserManagementAgent>(
      context: context,
      builder: (_) => const _AssignmentDialog(),
    );
    if (agent == null || !context.mounted) return;
    final commandContext = _commandContext(session, 'assign');
    await _run(
      context,
      ref,
      (controller) => controller.assign(
        AssignServiceRequestCommand(
          context: commandContext,
          requestId: request.id,
          expectedRevision: request.workflowRevision,
          assignedUserId: agent.id,
          assignedUserName: agent.displayName,
          assignedUserEmail: agent.email,
        ),
      ),
    );
  }

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    ServiceRequest request,
    ItsmSession? session,
  ) async {
    if (session == null) return;
    final reason = await _requiredReason(
      context,
      S.of(context).itsmCancelRequest,
    );
    if (reason == null || !context.mounted) return;
    final commandContext = _commandContext(session, 'cancel');
    await _run(
      context,
      ref,
      (controller) => controller.cancel(
        context: commandContext,
        request: request,
        transitionId: 'cancel',
        reason: reason,
      ),
    );
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    ServiceRequest request,
    ItsmSession? session,
  ) async {
    if (session == null) return;
    final reason = await _requiredReason(
      context,
      S.of(context).itsmRejectRequest,
    );
    if (reason == null || !context.mounted) return;
    await _run(
      context,
      ref,
      (controller) => controller.transitionOperational(
        TransitionServiceRequestCommand(
          context: _commandContext(session, 'reject'),
          request: request,
          transitionId: 'reject',
          targetStatus: ServiceRequestStatus.rejected,
          reason: reason,
        ),
      ),
    );
  }

  Future<void> _transition(
    BuildContext context,
    WidgetRef ref,
    ServiceRequest request,
    ItsmSession? session,
    ServiceRequestStatus status,
  ) async {
    if (session == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(S.of(context).confirm),
        content: Text(S.of(context).itsmConfirmStatusChange),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.of(context).confirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _run(
      context,
      ref,
      (controller) => controller.transitionOperational(
        TransitionServiceRequestCommand(
          context: _commandContext(session, status.value),
          request: request,
          transitionId: status.value,
          targetStatus: status,
        ),
      ),
    );
  }

  Future<void> _updateTask(
    BuildContext context,
    WidgetRef ref,
    ServiceRequestTaskSummary task,
    ItsmTaskStatus status,
    ItsmSession? session,
  ) async {
    if (session == null) return;
    final comment = await showDialog<String>(
      context: context,
      builder: (_) => _TextDialog(
        title: S.of(context).itsmUpdateTask,
        label: S.of(context).remarks,
      ),
    );
    if (comment == null || !context.mounted) return;
    await _run(
      context,
      ref,
      (controller) => controller.updateTask(
        UpdateServiceRequestTaskCommand(
          context: _commandContext(session, 'task-${task.id}-${status.name}'),
          requestId: requestId,
          taskId: task.id,
          status: status,
          comment: comment,
        ),
      ),
    );
  }

  Future<void> _addComment(
    BuildContext context,
    WidgetRef ref,
    ItsmSession? session,
  ) async {
    if (session == null) return;
    final result = await showDialog<_CommentResult>(
      context: context,
      builder: (_) => const _CommentDialog(),
    );
    if (result == null || !context.mounted) return;
    await _run(
      context,
      ref,
      (controller) => controller.addComment(
        AddServiceRequestCommentCommand(
          context: _commandContext(session, 'comment'),
          requestId: requestId,
          body: result.body,
          visibility: result.visibility,
        ),
      ),
    );
  }

  Future<void> _linkRecord(
    BuildContext context,
    WidgetRef ref,
    ItsmSession? session,
  ) async {
    if (session == null) return;
    final record = await showDialog<ServiceRequestLinkSummary>(
      context: context,
      builder: (_) => const _LinkedRecordDialog(),
    );
    if (record == null || !context.mounted) return;
    await _run(
      context,
      ref,
      (controller) => controller.linkRecord(
        LinkServiceRequestRecordCommand(
          context: _commandContext(session, 'link'),
          requestId: requestId,
          record: record,
        ),
      ),
    );
  }

  Future<void> _confirmCompletion(
    BuildContext context,
    WidgetRef ref,
    ServiceRequest request,
    ItsmSession? session,
  ) async {
    if (session == null) return;
    await _run(
      context,
      ref,
      (controller) => controller.confirmCompletion(
        context: _commandContext(session, 'confirm-completion'),
        request: request,
        transitionId: 'close',
      ),
    );
  }

  Future<void> _decideApproval(
    BuildContext context,
    WidgetRef ref, {
    required String approvalId,
    required bool approved,
    required ItsmSession? session,
  }) async {
    if (session == null) return;
    final comment = await showDialog<String>(
      context: context,
      builder: (_) => _TextDialog(
        title: approved ? S.of(context).approved : S.of(context).rejected,
        label: S.of(context).remarks,
        required: !approved,
      ),
    );
    if (comment == null ||
        (!approved && comment.trim().isEmpty) ||
        !context.mounted) {
      return;
    }
    await _run(
      context,
      ref,
      (controller) => controller.decideApproval(
        DecideServiceRequestApprovalCommand(
          context: _commandContext(session, 'approval-$approvalId'),
          requestId: requestId,
          approvalId: approvalId,
          decision:
              approved ? ApprovalDecision.approve : ApprovalDecision.reject,
          comment: comment,
        ),
      ),
    );
  }

  Future<String?> _requiredReason(BuildContext context, String title) {
    return showDialog<String>(
      context: context,
      builder: (_) => _TextDialog(
        title: title,
        label: S.of(context).reason,
        required: true,
      ),
    );
  }

  ItsmCommandContext _commandContext(ItsmSession session, String action) {
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    final safeAction = action.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '-');
    return ItsmCommandContext(
      idempotencyKey: 'service-request-$safeAction-$timestamp',
      correlationId: 'service-request-$requestId-$timestamp',
      actorUserId: session.userId,
      actorRole: session.role,
      actorDisplayName: session.displayName,
    );
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<Object?> Function(ServiceRequestController controller) action,
  ) async {
    try {
      final controller =
          await ref.read(serviceRequestControllerProvider.future);
      await action(controller);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).itsmActionCompleted)),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }
}

class MyRequestDetailScreen extends StatelessWidget {
  const MyRequestDetailScreen({required this.requestId, super.key});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    return ServiceRequestDetailScreen(
      requestId: requestId,
      forceReadOnly: true,
    );
  }
}

class _AssignmentDialog extends ConsumerStatefulWidget {
  const _AssignmentDialog();

  @override
  ConsumerState<_AssignmentDialog> createState() => _AssignmentDialogState();
}

class _AssignmentDialogState extends ConsumerState<_AssignmentDialog> {
  var _search = '';

  @override
  Widget build(BuildContext context) {
    final agents = ref.watch(
      serviceRequestAgentSearchProvider(ServiceRequestAgentSearch(_search)),
    );
    return AlertDialog(
      title: Text(S.of(context).itsmAssignRequest),
      content: SizedBox(
        width: 560,
        height: 420,
        child: Column(
          children: [
            CommonTextInput(
              label: S.of(context).search,
              prefixIcon: const Icon(Icons.search),
              onChanged: (value) => setState(() => _search = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: agents.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(error.toString())),
                data: (values) => ListView.builder(
                  itemCount: values.length,
                  itemBuilder: (context, index) {
                    final agent = values[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(agent.displayName),
                      subtitle: Text(agent.email),
                      onTap: () => Navigator.pop(context, agent),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(S.of(context).cancel),
        ),
      ],
    );
  }
}

class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.label,
    this.required = false,
  });

  final String title;
  final String label;
  final bool required;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valid = !widget.required || _controller.text.trim().isNotEmpty;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        child: CommonTextInput(
          controller: _controller,
          label: widget.label,
          isMultiline: true,
          onChanged: (_) => setState(() {}),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(S.of(context).cancel),
        ),
        FilledButton(
          onPressed: valid
              ? () => Navigator.pop(context, _controller.text.trim())
              : null,
          child: Text(S.of(context).confirm),
        ),
      ],
    );
  }
}

class _CommentResult {
  const _CommentResult(this.body, this.visibility);

  final String body;
  final ItsmCommentVisibility visibility;
}

class _CommentDialog extends StatefulWidget {
  const _CommentDialog();

  @override
  State<_CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends State<_CommentDialog> {
  final _controller = TextEditingController();
  var _visibility = ItsmCommentVisibility.requesterVisible;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).itsmAddComment),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CommonTextInput(
              controller: _controller,
              label: S.of(context).remarks,
              isMultiline: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ItsmCommentVisibility>(
              value: _visibility,
              decoration: InputDecoration(labelText: S.of(context).visibility),
              items: ItsmCommentVisibility.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.name),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) setState(() => _visibility = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(S.of(context).cancel),
        ),
        FilledButton(
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => Navigator.pop(
                    context,
                    _CommentResult(_controller.text.trim(), _visibility),
                  ),
          child: Text(S.of(context).confirm),
        ),
      ],
    );
  }
}

class _LinkedRecordDialog extends StatefulWidget {
  const _LinkedRecordDialog();

  @override
  State<_LinkedRecordDialog> createState() => _LinkedRecordDialogState();
}

class _LinkedRecordDialogState extends State<_LinkedRecordDialog> {
  final _id = TextEditingController();
  final _reference = TextEditingController();
  final _title = TextEditingController();
  var _type = ServiceRequestLinkType.incident;

  @override
  void dispose() {
    _id.dispose();
    _reference.dispose();
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valid = _id.text.trim().isNotEmpty &&
        _reference.text.trim().isNotEmpty &&
        _title.text.trim().isNotEmpty;
    return AlertDialog(
      title: Text(S.of(context).itsmLinkRecord),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ServiceRequestLinkType>(
              value: _type,
              decoration:
                  InputDecoration(labelText: S.of(context).itsmWorkItemType),
              items: ServiceRequestLinkType.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.value.replaceAll('_', ' ')),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 12),
            CommonTextInput(
              controller: _id,
              label: S.of(context).id,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            CommonTextInput(
              controller: _reference,
              label: S.of(context).reference,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            CommonTextInput(
              controller: _title,
              label: S.of(context).title,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(S.of(context).cancel),
        ),
        FilledButton(
          onPressed: valid
              ? () => Navigator.pop(
                    context,
                    ServiceRequestLinkSummary(
                      type: _type,
                      recordId: _id.text.trim(),
                      reference: _reference.text.trim(),
                      title: _title.text.trim(),
                    ),
                  )
              : null,
          child: Text(S.of(context).confirm),
        ),
      ],
    );
  }
}
