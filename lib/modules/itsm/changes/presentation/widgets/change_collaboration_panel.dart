import 'package:arptc_connect/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/domain/collaboration.dart';
import '../../../shared/domain/itsm_audit_event.dart';
import 'change_page_shell.dart';

class ChangeCollaborationPanel extends StatelessWidget {
  const ChangeCollaborationPanel({
    required this.comments,
    required this.attachments,
    required this.activity,
    required this.showOperationalVisibility,
    required this.onRetryComments,
    required this.onRetryAttachments,
    required this.onRetryActivity,
    super.key,
  });

  final AsyncValue<List<ItsmComment>> comments;
  final AsyncValue<List<ItsmAttachment>> attachments;
  final AsyncValue<List<ItsmAuditEvent>> activity;
  final bool showOperationalVisibility;
  final VoidCallback onRetryComments;
  final VoidCallback onRetryAttachments;
  final VoidCallback onRetryActivity;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChangeSurfaceCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.readOnlyAccess,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.changeCollaborationReadOnlyDescription),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final itemWidth = width >= 1050
                ? (width - 36) / 3
                : width >= 680
                    ? (width - 18) / 2
                    : width;
            return Wrap(
              spacing: 18,
              runSpacing: 18,
              children: [
                SizedBox(
                  width: itemWidth,
                  child: ChangeSurfaceCard(
                    title: l10n.changeComments,
                    child: _AsyncSection<ItsmComment>(
                      value: comments,
                      emptyLabel: l10n.noChangeComments,
                      errorLabel: l10n.unableToLoadChangeCollaboration,
                      retryLabel: l10n.retry,
                      onRetry: onRetryComments,
                      itemBuilder: (comment) => _CommentTile(
                        comment: comment,
                        showVisibility: showOperationalVisibility,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: ChangeSurfaceCard(
                    title: l10n.changeAttachments,
                    child: _AsyncSection<ItsmAttachment>(
                      value: attachments,
                      emptyLabel: l10n.noChangeAttachments,
                      errorLabel: l10n.unableToLoadChangeCollaboration,
                      retryLabel: l10n.retry,
                      onRetry: onRetryAttachments,
                      itemBuilder: (attachment) => _AttachmentTile(
                        attachment: attachment,
                        showVisibility: showOperationalVisibility,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: ChangeSurfaceCard(
                    title: l10n.changeActivityTimeline,
                    child: _AsyncSection<ItsmAuditEvent>(
                      value: activity,
                      emptyLabel: l10n.noChangeActivity,
                      errorLabel: l10n.unableToLoadChangeCollaboration,
                      retryLabel: l10n.retry,
                      onRetry: onRetryActivity,
                      itemBuilder: (event) => _ActivityTile(event: event),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AsyncSection<T> extends StatelessWidget {
  const _AsyncSection({
    required this.value,
    required this.emptyLabel,
    required this.errorLabel,
    required this.retryLabel,
    required this.onRetry,
    required this.itemBuilder,
  });

  final AsyncValue<List<T>> value;
  final String emptyLabel;
  final String errorLabel;
  final String retryLabel;
  final VoidCallback onRetry;
  final Widget Function(T item) itemBuilder;

  @override
  Widget build(BuildContext context) => value.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(errorLabel, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                TextButton(onPressed: onRetry, child: Text(retryLabel)),
              ],
            ),
          ),
        ),
        data: (items) => items.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  emptyLabel,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            : Column(
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    itemBuilder(items[index]),
                    if (index != items.length - 1) const Divider(height: 24),
                  ],
                ],
              ),
      );
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.showVisibility,
  });

  final ItsmComment comment;
  final bool showVisibility;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  comment.authorDisplayName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (showVisibility)
                _VisibilityChip(
                  internal:
                      comment.visibility == ItsmCommentVisibility.internal,
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(comment.body),
          const SizedBox(height: 6),
          Text(
            _formatDate(comment.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.attachment,
    required this.showVisibility,
  });

  final ItsmAttachment attachment;
  final bool showVisibility;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.attach_file_rounded),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatBytes(attachment.sizeBytes)} · ${_formatDate(attachment.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (showVisibility)
            _VisibilityChip(
              internal:
                  attachment.visibility == ItsmAttachmentVisibility.internal,
            ),
        ],
      );
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.event});

  final ItsmAuditEvent event;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              event.representsTransition
                  ? Icons.swap_horiz_rounded
                  : Icons.history_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.action.replaceAll('_', ' '),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (event.actorDisplayName.trim().isNotEmpty)
                  Text(event.actorDisplayName),
                if (event.representsTransition)
                  Text('${event.fromState} → ${event.toState}'),
                Text(
                  _formatDate(event.occurredAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      );
}

class _VisibilityChip extends StatelessWidget {
  const _VisibilityChip({required this.internal});

  final bool internal;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: internal ? colors.tertiaryContainer : colors.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        internal
            ? S.of(context).internalVisibility
            : S.of(context).requesterVisible,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

String _formatDate(DateTime date) => DateFormat.yMMMd().add_Hm().format(date);

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kilobytes = bytes / 1024;
  if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(1)} KB';
  return '${(kilobytes / 1024).toStringAsFixed(1)} MB';
}
