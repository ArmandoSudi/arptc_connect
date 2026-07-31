import 'package:arptc_connect/modules/task/application/task_mutation_service.dart';
import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/task/domain/task.dart';
import 'package:arptc_connect/modules/task/domain/task_access.dart';
import 'package:arptc_connect/modules/task/domain/task_attachment_upload.dart';
import 'package:arptc_connect/modules/task/domain/task_draft.dart';
import 'package:arptc_connect/modules/task/presentation/task_presentation_helpers.dart';
import 'package:arptc_connect/modules/task/presentation/widgets/task_attachment_field.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/page_header_simple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TaskEditor extends ConsumerStatefulWidget {
  const TaskEditor({
    super.key,
    required this.principal,
    this.initialTask,
  });

  final TaskPrincipal principal;
  final Task? initialTask;

  @override
  ConsumerState<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends ConsumerState<TaskEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _observationController;
  late final TextEditingController _senderController;
  late final TextEditingController _receiverController;
  late final TextEditingController _departmentController;
  late TaskStatus _status;
  late TaskType _type;
  TaskAttachmentUpload? _mailScanUpload;
  TaskAttachmentUpload? _reportUpload;
  bool _removeMailScan = false;
  bool _removeReport = false;
  bool _saving = false;

  bool get _isEditing => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _labelController = TextEditingController(text: task?.label ?? '');
    _observationController =
        TextEditingController(text: task?.observation ?? '');
    _senderController = TextEditingController(text: task?.sender ?? '');
    _receiverController = TextEditingController(text: task?.receiver ?? '');
    _departmentController = TextEditingController(
      text: task?.departmentName.trim().isNotEmpty == true
          ? task!.departmentName
          : widget.principal.departmentName.trim().isNotEmpty
              ? widget.principal.departmentName
              : task?.departmentId ?? widget.principal.departmentId,
    );
    _status = task?.status ?? TaskStatus.newTask;
    _type = task?.type ?? TaskType.task;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _observationController.dispose();
    _senderController.dispose();
    _receiverController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final task = widget.initialTask;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageHeaderSimple(
                    title: _isEditing ? l10n.editTask : l10n.newTask,
                    backRoute: _isEditing
                        ? '/service/tasks/${task!.id}'
                        : '/service/tasks',
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FormGrid(
                              children: [
                                CommonTextInput(
                                  label: l10n.activityObject,
                                  hintText: l10n.activityObjectHint,
                                  controller: _labelController,
                                  validator: _required,
                                ),
                                _DropdownField<TaskStatus>(
                                  label: l10n.status,
                                  value: _status,
                                  items: TaskStatus.values,
                                  labelBuilder: (status) =>
                                      taskStatusLabel(l10n, status),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _status = value);
                                    }
                                  },
                                ),
                                _DropdownField<TaskType>(
                                  label: l10n.type,
                                  value: _type,
                                  items: TaskType.values,
                                  labelBuilder: (type) =>
                                      taskTypeLabel(l10n, type),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _type = value);
                                    }
                                  },
                                ),
                                CommonTextInput(
                                  label: l10n.department,
                                  controller: _departmentController,
                                  readOnly: true,
                                  prefixIcon:
                                      const Icon(Icons.account_tree_outlined),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            CommonTextInput(
                              label: l10n.remarks,
                              hintText: l10n.remarksHint,
                              controller: _observationController,
                              isMultiline: true,
                              validator: _required,
                            ),
                            if (_type == TaskType.mail) ...[
                              const SizedBox(height: 20),
                              _FormGrid(
                                children: [
                                  CommonTextInput(
                                    label: l10n.sender,
                                    controller: _senderController,
                                    type: CommonTextInputType.name,
                                    validator: _required,
                                  ),
                                  CommonTextInput(
                                    label: l10n.receiver,
                                    controller: _receiverController,
                                    type: CommonTextInputType.name,
                                    validator: _required,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              TaskAttachmentField(
                                label: l10n.uploadMailScan,
                                currentAttachment: task?.mailScan,
                                selectedUpload: _mailScanUpload,
                                removed: _removeMailScan,
                                onChanged: (upload) {
                                  setState(() => _mailScanUpload = upload);
                                },
                                onRemoveChanged: (removed) {
                                  setState(() => _removeMailScan = removed);
                                },
                              ),
                            ],
                            const SizedBox(height: 20),
                            TaskAttachmentField(
                              label: l10n.uploadReport,
                              currentAttachment: task?.reportFile,
                              selectedUpload: _reportUpload,
                              removed: _removeReport,
                              onChanged: (upload) {
                                setState(() => _reportUpload = upload);
                              },
                              onRemoveChanged: (removed) {
                                setState(() => _removeReport = removed);
                              },
                            ),
                            const SizedBox(height: 20),
                            _ReadOnlyMetadata(
                              creationDate:
                                  task?.creationDate ?? DateTime.now(),
                              createdBy:
                                  task?.createdByName.trim().isNotEmpty == true
                                      ? task!.createdByName
                                      : widget.principal.displayName,
                            ),
                            const SizedBox(height: 28),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed:
                                      _saving ? null : () => context.pop(),
                                  child: Text(l10n.cancel),
                                ),
                                const SizedBox(width: 12),
                                FilledButton.icon(
                                  onPressed: _saving ? null : _submit,
                                  icon: _saving
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.save_outlined),
                                  label: Text(
                                    _saving ? l10n.saving : l10n.save,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return S.of(context).requiredField;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final principal = widget.principal;
    if (!principal.hasDepartment && widget.initialTask == null) {
      _showError(S.of(context).departmentRequired);
      return;
    }

    setState(() => _saving = true);
    try {
      final existing = widget.initialTask;
      final draft = TaskDraft(
        label: _labelController.text.trim(),
        observation: _observationController.text.trim(),
        status: _status,
        type: _type,
        sender: _type == TaskType.mail ? _senderController.text.trim() : '',
        receiver: _type == TaskType.mail ? _receiverController.text.trim() : '',
      );
      final result = await ref.read(taskMutationServiceProvider).save(
            principal: principal,
            draft: draft,
            existingTask: existing,
            mailScan: _mailScanUpload,
            removeMailScan: _removeMailScan,
            reportFile: _reportUpload,
            removeReportFile: _removeReport,
          );
      if (!mounted) return;
      if (result.created) {
        _showSuccess(S.of(context).taskCreated);
        context.go('/service/tasks/${result.taskId}');
      } else {
        _showSuccess(S.of(context).taskUpdated);
        context.pop();
      }
    } catch (error) {
      if (mounted) _showError(error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _FormGrid extends StatelessWidget {
  const _FormGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 680) {
          return Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1) const SizedBox(height: 20),
              ],
            ],
          );
        }

        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: children
              .map(
                (child) => SizedBox(
                  width: (constraints.maxWidth - 20) / 2,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T value) labelBuilder;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(labelBuilder(item)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ReadOnlyMetadata extends StatelessWidget {
  const _ReadOnlyMetadata({
    required this.creationDate,
    required this.createdBy,
  });

  final DateTime creationDate;
  final String createdBy;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Wrap(
      spacing: 24,
      runSpacing: 8,
      children: [
        _MetadataValue(
          icon: Icons.schedule,
          label: l10n.createdAt,
          value: DateFormat.yMMMd(Localizations.localeOf(context).toString())
              .add_Hm()
              .format(creationDate),
        ),
        _MetadataValue(
          icon: Icons.person_outline,
          label: l10n.createdBy,
          value: createdBy,
        ),
      ],
    );
  }
}

class _MetadataValue extends StatelessWidget {
  const _MetadataValue({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Text('$label: $value'),
      ],
    );
  }
}
