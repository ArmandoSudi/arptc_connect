import 'package:arptc_connect/modules/task/application/task_mutation_service.dart';
import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/task/domain/task.dart';
import 'package:arptc_connect/modules/task/domain/task_access.dart';
import 'package:arptc_connect/modules/task/presentation/task_presentation_helpers.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/page_header_simple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class TaskDetailsView extends ConsumerStatefulWidget {
  const TaskDetailsView({
    super.key,
    required this.task,
    required this.principal,
  });

  final Task task;
  final TaskPrincipal principal;

  @override
  ConsumerState<TaskDetailsView> createState() => _TaskDetailsState();
}

class _TaskDetailsState extends ConsumerState<TaskDetailsView> {
  bool _deleting = false;

  bool get _canMutate {
    return TaskAccessPolicy.canMutateTask(widget.principal, widget.task);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final task = widget.task;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TaskDetailsHeader(
                task: task,
                canMutate: _canMutate,
                deleting: _deleting,
                onDelete: _confirmDelete,
              ),
              if (widget.principal.role.isReadOnly) ...[
                const SizedBox(height: 16),
                _ReadOnlyBanner(message: l10n.adminReadOnlyTask),
              ],
              const SizedBox(height: 24),
              _TaskHeroCard(task: task),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final details = _TaskInformationCard(task: task);
                  final metadata = _TaskMetadataCard(task: task);
                  if (constraints.maxWidth < 760) {
                    return Column(
                      children: [
                        details,
                        const SizedBox(height: 18),
                        metadata,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: details),
                      const SizedBox(width: 18),
                      Expanded(flex: 2, child: metadata),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              _DocumentsCard(task: task),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final l10n = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.delete_outline),
          title: Text(l10n.deleteTask),
          content: Text(l10n.deleteTaskConfirmation(widget.task.label)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(taskMutationServiceProvider).delete(
            principal: widget.principal,
            task: widget.task,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.taskDeleted)),
      );
      context.go('/service/tasks');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.taskDeleteFailed(error)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }
}

class _TaskDetailsHeader extends StatelessWidget {
  const _TaskDetailsHeader({
    required this.task,
    required this.canMutate,
    required this.deleting,
    required this.onDelete,
  });

  final Task task;
  final bool canMutate;
  final bool deleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final actions = <Widget>[
      OutlinedButton.icon(
        onPressed: deleting
            ? null
            : () => context.push('/service/tasks/${task.id}/edit'),
        icon: const Icon(Icons.edit_outlined),
        label: Text(l10n.edit),
      ),
      FilledButton.tonalIcon(
        onPressed: deleting ? null : onDelete,
        icon: deleting
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.delete_outline),
        label: Text(l10n.delete),
        style: FilledButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!canMutate || constraints.maxWidth >= 650) {
          return PageHeaderSimple(
            title: l10n.taskDetails,
            backRoute: '/service/tasks',
            actions: canMutate
                ? [actions.first, const SizedBox(width: 8), actions.last]
                : null,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeaderSimple(
              title: l10n.taskDetails,
              backRoute: '/service/tasks',
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TaskHeroCard extends StatelessWidget {
  const _TaskHeroCard({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 24,
        runSpacing: 18,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimary.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    task.type == TaskType.mail
                        ? Icons.mail_outline
                        : Icons.task_alt_outlined,
                    color: theme.colorScheme.onPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        taskTypeLabel(l10n, task.type),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimary.withOpacity(0.82),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        task.label,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _HeroStatus(status: task.status),
        ],
      ),
    );
  }
}

class _HeroStatus extends StatelessWidget {
  const _HeroStatus({required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        taskStatusLabel(S.of(context), status),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TaskInformationCard extends StatelessWidget {
  const _TaskInformationCard({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return _SectionCard(
      title: l10n.taskInformation,
      icon: Icons.info_outline,
      child: Column(
        children: [
          _DetailRow(
            label: l10n.type,
            value: taskTypeLabel(l10n, task.type),
          ),
          const Divider(height: 28),
          _DetailRow(
            label: l10n.status,
            value: taskStatusLabel(l10n, task.status),
          ),
          const Divider(height: 28),
          _DetailRow(label: l10n.remarks, value: task.observation),
          if (task.type == TaskType.mail) ...[
            const Divider(height: 28),
            _DetailRow(label: l10n.sender, value: task.sender),
            const Divider(height: 28),
            _DetailRow(label: l10n.receiver, value: task.receiver),
          ],
        ],
      ),
    );
  }
}

class _TaskMetadataCard extends StatelessWidget {
  const _TaskMetadataCard({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return _SectionCard(
      title: l10n.metadata,
      icon: Icons.manage_search_outlined,
      child: Column(
        children: [
          _DetailRow(label: l10n.taskIdentifier, value: task.id),
          const Divider(height: 28),
          _DetailRow(
            label: l10n.department,
            value: task.departmentName.trim().isNotEmpty
                ? task.departmentName
                : task.departmentId,
          ),
          const Divider(height: 28),
          _DetailRow(
            label: l10n.departmentIdentifier,
            value: task.departmentId,
          ),
          const Divider(height: 28),
          _DetailRow(
            label: l10n.createdAt,
            value: formatTaskDate(context, task.creationDate),
          ),
          const Divider(height: 28),
          _DetailRow(
            label: l10n.updatedAt,
            value: task.updatedAt == null
                ? l10n.notAvailable
                : formatTaskDate(context, task.updatedAt!),
          ),
          const Divider(height: 28),
          _DetailRow(
            label: l10n.createdBy,
            value: task.createdByName.trim().isEmpty
                ? task.createdByEmail
                : task.createdByName,
          ),
          const Divider(height: 28),
          _DetailRow(
            label: l10n.email,
            value: task.createdByEmail,
          ),
          const Divider(height: 28),
          _DetailRow(
            label: l10n.creatorIdentifier,
            value: task.createdByUserId,
          ),
        ],
      ),
    );
  }
}

class _DocumentsCard extends StatelessWidget {
  const _DocumentsCard({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final documents = <({String label, TaskAttachment attachment})>[
      if (task.type == TaskType.mail && task.mailScan?.isAvailable == true)
        (label: l10n.mailScan, attachment: task.mailScan!),
      if (task.reportFile?.isAvailable == true)
        (label: l10n.reportFile, attachment: task.reportFile!),
    ];

    return _SectionCard(
      title: l10n.documents,
      icon: Icons.folder_copy_outlined,
      child: documents.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(l10n.noDocuments),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth < 680
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 14) / 2;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: documents
                      .map(
                        (document) => SizedBox(
                          width: width,
                          child: _DocumentTile(
                            label: document.label,
                            attachment: document.attachment,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.label,
    required this.attachment,
  });

  final String label;
  final TaskAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileName = attachment.fileName.trim().isNotEmpty
        ? attachment.fileName
        : S.of(context).document;
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _previewAttachment(context, attachment),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  isTaskAttachmentImage(attachment)
                      ? Icons.image_outlined
                      : Icons.description_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (attachment.contentType.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        attachment.contentType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (attachment.storagePath.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${S.of(context).storagePath}: '
                        '${attachment.storagePath}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: S.of(context).preview,
                onPressed: () => _previewAttachment(context, attachment),
                icon: const Icon(Icons.open_in_new),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value.trim().isEmpty ? S.of(context).notAvailable : value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyBanner extends StatelessWidget {
  const _ReadOnlyBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.visibility_outlined, color: scheme.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _previewAttachment(
  BuildContext context,
  TaskAttachment attachment,
) async {
  if (isTaskAttachmentImage(attachment)) {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 760),
            child: Stack(
              children: [
                InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5,
                  child: Center(
                    child: Image.network(
                      attachment.url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => ErrorStateView(
                        title: S.of(dialogContext).documentPreviewFailed,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton.filledTonal(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    return;
  }

  final uri = Uri.tryParse(attachment.url);
  if (uri == null ||
      !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).documentPreviewFailed)),
    );
  }
}
