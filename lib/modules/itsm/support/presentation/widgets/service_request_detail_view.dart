import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/collaboration.dart';
import 'package:arptc_connect/widgets/corporate_components.dart';
import 'package:flutter/material.dart';

import '../../domain/service_request.dart';
import '../../domain/service_request_resources.dart';

class ServiceRequestDetailView extends StatelessWidget {
  const ServiceRequestDetailView({
    required this.detail,
    required this.isManager,
    required this.onApprovalDecision,
    super.key,
    this.canSelfCancel = false,
    this.canConfirmCompletion = false,
    this.onAssign,
    this.onCancel,
    this.onReject,
    this.onTransition,
    this.onTaskStatusChanged,
    this.onAddComment,
    this.onAddLinkedRecord,
    this.onConfirmCompletion,
  });

  final ServiceRequestDetail detail;
  final bool isManager;
  final bool canSelfCancel;
  final bool canConfirmCompletion;
  final void Function(String approvalId, bool approved) onApprovalDecision;
  final VoidCallback? onAssign;
  final VoidCallback? onCancel;
  final VoidCallback? onReject;
  final ValueChanged<ServiceRequestStatus>? onTransition;
  final void Function(ServiceRequestTaskSummary, ItsmTaskStatus)?
      onTaskStatusChanged;
  final VoidCallback? onAddComment;
  final VoidCallback? onAddLinkedRecord;
  final VoidCallback? onConfirmCompletion;

  @override
  Widget build(BuildContext context) {
    final request = detail.request;
    final l10n = S.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final primary = [
          CorporateSurfaceCard(
            title: request.title,
            subtitle: request.requestNumber,
            accentColor: Theme.of(context).colorScheme.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DetailRow(label: l10n.status, value: request.status.value),
                _DetailRow(
                  label: l10n.requester,
                  value: request.requestedForName,
                ),
                _DetailRow(
                  label: l10n.service,
                  value: request.catalogueItemName,
                ),
                _DetailRow(
                  label: l10n.assignedTo,
                  value: request.assignedUserName ?? '',
                ),
                _DetailRow(
                  label: l10n.description,
                  value: request.description,
                ),
              ],
            ),
          ),
          if (isManager || canSelfCancel || canConfirmCompletion)
            CorporateSurfaceCard(
              title: l10n.actions,
              child: _RequestActions(
                request: request,
                isManager: isManager,
                canSelfCancel: canSelfCancel,
                canConfirmCompletion: canConfirmCompletion,
                onAssign: onAssign,
                onCancel: onCancel,
                onReject: onReject,
                onTransition: onTransition,
                onConfirmCompletion: onConfirmCompletion,
              ),
            ),
          if (request.responses.isNotEmpty)
            CorporateSurfaceCard(
              title: l10n.agentInformation,
              child: Column(
                children: request.responses.entries
                    .map(
                      (entry) => _DetailRow(
                        label: entry.key,
                        value: _displayValue(entry.value),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          CorporateSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionHeading(
                  title: l10n.remarks,
                  action: isManager && onAddComment != null
                      ? IconButton(
                          tooltip: l10n.itsmAddComment,
                          onPressed: onAddComment,
                          icon: const Icon(Icons.add_comment_outlined),
                        )
                      : null,
                ),
                if (detail.comments
                    .where((comment) => isManager || !comment.isInternal)
                    .isEmpty)
                  Text(l10n.noDataAvailable)
                else
                  ...detail.comments
                      .where((comment) => isManager || !comment.isInternal)
                      .map(
                        (comment) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.chat_bubble_outline),
                          title: Text(comment.body),
                          subtitle: Text(comment.authorDisplayName),
                        ),
                      ),
              ],
            ),
          ),
          CorporateSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionHeading(
                  title: l10n.itsmLinkedRecords,
                  action: isManager && onAddLinkedRecord != null
                      ? IconButton(
                          tooltip: l10n.itsmLinkRecord,
                          onPressed: onAddLinkedRecord,
                          icon: const Icon(Icons.add_link),
                        )
                      : null,
                ),
                if (request.relatedRecords.isEmpty)
                  Text(l10n.noDataAvailable)
                else
                  ...request.relatedRecords.map(
                    (record) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.link),
                      title: Text(record.reference),
                      subtitle: Text(record.title),
                    ),
                  ),
              ],
            ),
          ),
        ];
        final secondary = [
          CorporateSurfaceCard(
            title: l10n.status,
            child: _RequestProgress(status: request.status),
          ),
          if (detail.approvals.isNotEmpty)
            CorporateSurfaceCard(
              title: l10n.confirmation,
              child: Column(
                children: detail.approvals.map((approval) {
                  final pending = approval.status.name == 'pending';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.approval_outlined),
                    title: Text(approval.status.name),
                    subtitle: approval.comment.isEmpty
                        ? null
                        : Text(approval.comment),
                    trailing: isManager && pending
                        ? Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                tooltip: l10n.approved,
                                onPressed: () =>
                                    onApprovalDecision(approval.id, true),
                                icon: const Icon(Icons.check_circle_outline),
                              ),
                              IconButton(
                                tooltip: l10n.rejected,
                                onPressed: () =>
                                    onApprovalDecision(approval.id, false),
                                icon: const Icon(Icons.cancel_outlined),
                              ),
                            ],
                          )
                        : null,
                  );
                }).toList(growable: false),
              ),
            ),
          if (detail.tasks.isNotEmpty)
            CorporateSurfaceCard(
              title: l10n.tasks,
              child: Column(
                children: detail.tasks
                    .map(
                      (task) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.task_alt_outlined),
                        title: Text(task.title),
                        subtitle: Text(task.status.name),
                        trailing: isManager && onTaskStatusChanged != null
                            ? PopupMenuButton<ItsmTaskStatus>(
                                tooltip: l10n.itsmUpdateTask,
                                onSelected: (status) =>
                                    onTaskStatusChanged!(task, status),
                                itemBuilder: (_) => ItsmTaskStatus.values
                                    .map(
                                      (status) => PopupMenuItem(
                                        value: status,
                                        child: Text(status.name),
                                      ),
                                    )
                                    .toList(growable: false),
                              )
                            : null,
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          if (detail.attachments.isNotEmpty)
            CorporateSurfaceCard(
              title: l10n.documents,
              child: Column(
                children: detail.attachments
                    .where((attachment) => isManager || !attachment.isInternal)
                    .map(
                      (attachment) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.attach_file),
                        title: Text(attachment.fileName),
                        subtitle: Text(attachment.contentType),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
        ];
        final content = wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _SectionList(children: primary)),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _SectionList(children: secondary)),
                ],
              )
            : _SectionList(children: [...primary, ...secondary]);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: content,
        );
      },
    );
  }
}

class _RequestActions extends StatelessWidget {
  const _RequestActions({
    required this.request,
    required this.isManager,
    required this.canSelfCancel,
    required this.canConfirmCompletion,
    this.onAssign,
    this.onCancel,
    this.onReject,
    this.onTransition,
    this.onConfirmCompletion,
  });

  final ServiceRequest request;
  final bool isManager;
  final bool canSelfCancel;
  final bool canConfirmCompletion;
  final VoidCallback? onAssign;
  final VoidCallback? onCancel;
  final VoidCallback? onReject;
  final ValueChanged<ServiceRequestStatus>? onTransition;
  final VoidCallback? onConfirmCompletion;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final buttons = <Widget>[];
    if (isManager) {
      if (request.status == ServiceRequestStatus.submitted ||
          request.status == ServiceRequestStatus.approved) {
        buttons.add(
          FilledButton.tonalIcon(
            onPressed: onAssign,
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: Text(l10n.assign),
          ),
        );
      }
      if (request.status == ServiceRequestStatus.submitted ||
          request.status == ServiceRequestStatus.awaitingApproval) {
        buttons.add(
          OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.block_outlined),
            label: Text(l10n.rejected),
          ),
        );
      }
      if (request.status == ServiceRequestStatus.assigned ||
          request.status == ServiceRequestStatus.approved) {
        buttons.add(
          FilledButton.icon(
            onPressed: () =>
                onTransition?.call(ServiceRequestStatus.inFulfilment),
            icon: const Icon(Icons.play_arrow),
            label: Text(l10n.itsmStartFulfilment),
          ),
        );
      }
      if (request.status == ServiceRequestStatus.inFulfilment ||
          request.status == ServiceRequestStatus.awaitingUser) {
        buttons.add(
          FilledButton.icon(
            onPressed: () => onTransition?.call(ServiceRequestStatus.fulfilled),
            icon: const Icon(Icons.task_alt),
            label: Text(l10n.itsmMarkFulfilled),
          ),
        );
      }
      if (request.status == ServiceRequestStatus.fulfilled) {
        buttons.add(
          FilledButton.icon(
            onPressed: () => onTransition?.call(ServiceRequestStatus.closed),
            icon: const Icon(Icons.archive_outlined),
            label: Text(l10n.close),
          ),
        );
      }
    }
    if (isManager || canSelfCancel) {
      buttons.add(
        TextButton.icon(
          onPressed: onCancel,
          icon: const Icon(Icons.cancel_outlined),
          label: Text(l10n.cancel),
        ),
      );
    }
    if (canConfirmCompletion) {
      buttons.add(
        FilledButton.icon(
          onPressed: onConfirmCompletion,
          icon: const Icon(Icons.verified_outlined),
          label: Text(l10n.itsmConfirmCompletion),
        ),
      );
    }
    return buttons.isEmpty
        ? Text(l10n.noDataAvailable)
        : Wrap(spacing: 8, runSpacing: 8, children: buttons);
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _SectionList extends StatelessWidget {
  const _SectionList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index < children.length - 1) const SizedBox(height: 16),
        ],
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
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Expanded(child: Text(value.isEmpty ? S.of(context).dash : value)),
        ],
      ),
    );
  }
}

class _RequestProgress extends StatelessWidget {
  const _RequestProgress({required this.status});

  final ServiceRequestStatus status;

  @override
  Widget build(BuildContext context) {
    const sequence = [
      ServiceRequestStatus.submitted,
      ServiceRequestStatus.awaitingApproval,
      ServiceRequestStatus.approved,
      ServiceRequestStatus.assigned,
      ServiceRequestStatus.inFulfilment,
      ServiceRequestStatus.fulfilled,
      ServiceRequestStatus.closed,
    ];
    final current = sequence.indexOf(status);
    return Column(
      children: sequence.map((step) {
        final index = sequence.indexOf(step);
        final complete = current >= index && current >= 0;
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            complete ? Icons.check_circle : Icons.circle_outlined,
            color: complete ? Theme.of(context).colorScheme.primary : null,
          ),
          title: Text(step.value.replaceAll('_', ' ')),
        );
      }).toList(growable: false),
    );
  }
}

String _displayValue(Object? value) {
  if (value is Iterable) return value.join(', ');
  return value?.toString() ?? '';
}
