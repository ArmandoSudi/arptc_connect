import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_department.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/entity_details_providers.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/custom_filledbutton.dart';
import 'package:arptc_connect/widgets/custom_form_field.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:arptc_connect/widgets/yes_or_no_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DepartmentDetailsScreen extends ConsumerWidget {
  const DepartmentDetailsScreen({
    required this.departmentId,
    super.key,
  });

  final String departmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departmentAsync =
        ref.watch(umDepartmentDetailsProvider(departmentId));

    return Scaffold(
      body: ContentView(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => context.pop(),
                ),
                const PageHeader(
                  title: 'Department Details',
                  description: 'View and edit department fields',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: departmentAsync.when(
                data: (department) => SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    department.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () {
                                      showModalBottomSheet<void>(
                                        context: context,
                                        isScrollControlled: true,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(18),
                                          ),
                                        ),
                                        builder: (_) => _EditDepartmentSheet(
                                          department: department,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      final confirm =
                                          await showAdaptiveYesNoDialog(
                                        context,
                                        'Delete Department',
                                        'Are you sure you want to delete "${department.name}"?',
                                        confirmText: 'Delete',
                                        cancelText: 'Cancel',
                                        isDestructive: true,
                                      );
                                      if (confirm != true) return;

                                      await ref
                                          .read(
                                              userManagementRepositoryProvider)
                                          .deleteDepartment(department.id);

                                      ref.invalidate(umDepartmentsProvider);
                                      ref.invalidate(
                                        umDepartmentDetailsProvider(
                                            department.id),
                                      );

                                      if (context.mounted) {
                                        context.pop();
                                      }
                                    },
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _FieldRow(label: 'ID', value: department.id),
                              _FieldRow(label: 'Name', value: department.name),
                              _FieldRow(
                                label: 'Name (lower)',
                                value: department.nameLower,
                              ),
                              _FieldRow(label: 'Code', value: department.code),
                              _FieldRow(
                                label: 'Head User ID',
                                value: department.headUserId ?? '-',
                              ),
                              _FieldRow(
                                label: 'Status',
                                value:
                                    department.isActive ? 'Active' : 'Inactive',
                              ),
                              _FieldRow(
                                label: 'Created At',
                                value: _formatDateTime(department.createdAt),
                              ),
                              _FieldRow(
                                label: 'Updated At',
                                value: _formatDateTime(department.updatedAt),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                error: (error, _) => ErrorStateView(
                  title: 'Unable to load department',
                  description: error.toString(),
                  onRetry: () =>
                      ref.invalidate(umDepartmentDetailsProvider(departmentId)),
                ),
                loading: () => const LoadingStateView(
                  message: 'Loading department details...',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditDepartmentSheet extends ConsumerStatefulWidget {
  const _EditDepartmentSheet({required this.department});

  final UserManagementDepartment department;

  @override
  ConsumerState<_EditDepartmentSheet> createState() =>
      _EditDepartmentSheetState();
}

class _EditDepartmentSheetState extends ConsumerState<_EditDepartmentSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _headUserController;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.department.name);
    _codeController = TextEditingController(text: widget.department.code);
    _headUserController =
        TextEditingController(text: widget.department.headUserId ?? '');
    _isActive = widget.department.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _headUserController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Department',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          CustomFormField(
            label: 'Name',
            hintText: 'Department name',
            textInputType: TextInputType.name,
            controller: _nameController,
          ),
          const SizedBox(height: 12),
          CustomFormField(
            label: 'Code',
            hintText: 'DEP_FIN',
            textInputType: TextInputType.text,
            controller: _codeController,
          ),
          const SizedBox(height: 12),
          CustomFormField(
            label: 'Head user ID',
            hintText: 'uid_123',
            textInputType: TextInputType.text,
            controller: _headUserController,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _isActive,
            title: const Text('Active'),
            contentPadding: EdgeInsets.zero,
            onChanged: (value) {
              setState(() {
                _isActive = value;
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CustomFilledButton(
                  text: _isSaving ? 'Saving...' : 'Save',
                  onPressed: _isSaving ? null : _save,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton(
                  onPressed:
                      _isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updated = UserManagementDepartment(
      id: widget.department.id,
      code: _codeController.text.trim(),
      name: name,
      nameLower: name.toLowerCase(),
      headUserId: _headUserController.text.trim().isEmpty
          ? null
          : _headUserController.text.trim(),
      isActive: _isActive,
      createdAt: widget.department.createdAt,
      updatedAt: DateTime.now(),
    );

    await ref.read(userManagementRepositoryProvider).updateDepartment(updated);
    ref.invalidate(umDepartmentsProvider);
    ref.invalidate(umDepartmentDetailsProvider(widget.department.id));

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value.isEmpty ? '-' : value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return '-';
  }
  return value.toIso8601String();
}
