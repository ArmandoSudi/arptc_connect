import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/domain/modules.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_module.dart';
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

class ModuleDetailsScreen extends ConsumerWidget {
  const ModuleDetailsScreen({
    required this.moduleId,
    super.key,
  });

  final String moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moduleAsync = ref.watch(umModuleDetailsProvider(moduleId));

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
                  title: 'Module Details',
                  description: 'View and edit module fields',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: moduleAsync.when(
                data: (module) => SingleChildScrollView(
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
                                  Expanded(
                                    child: Text(
                                      module.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
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
                                        builder: (_) =>
                                            _EditModuleSheet(module: module),
                                      );
                                    },
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      final confirm =
                                          await showAdaptiveYesNoDialog(
                                        context,
                                        'Delete Module',
                                        'Are you sure you want to delete "${module.name}"?',
                                        confirmText: 'Delete',
                                        cancelText: 'Cancel',
                                        isDestructive: true,
                                      );
                                      if (confirm != true) return;

                                      await ref
                                          .read(
                                              userManagementRepositoryProvider)
                                          .deleteModule(module.id);

                                      ref.invalidate(umModulesProvider);
                                      ref.invalidate(
                                        umModuleDetailsProvider(module.id),
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
                              _FieldRow(label: 'ID', value: module.id),
                              _FieldRow(label: 'Key', value: module.key),
                              _FieldRow(label: 'Name', value: module.name),
                              _FieldRow(
                                label: 'Name (lower)',
                                value: module.nameLower,
                              ),
                              _FieldRow(
                                label: 'Description',
                                value: module.description,
                              ),
                              _FieldRow(
                                label: 'Status',
                                value: module.isActive ? 'Active' : 'Inactive',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Available Roles',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: module.accessRolesWithNone
                                    .map(
                                      (role) => Chip(label: Text(role.label)),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 12),
                              _FieldRow(
                                label: 'Created At',
                                value: _formatDateTime(module.createdAt),
                              ),
                              _FieldRow(
                                label: 'Updated At',
                                value: _formatDateTime(module.updatedAt),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                error: (error, _) => ErrorStateView(
                  title: 'Unable to load module',
                  description: error.toString(),
                  onRetry: () =>
                      ref.invalidate(umModuleDetailsProvider(moduleId)),
                ),
                loading: () => const LoadingStateView(
                  message: 'Loading module details...',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditModuleSheet extends ConsumerStatefulWidget {
  const _EditModuleSheet({
    required this.module,
  });

  final UserManagementModule module;

  @override
  ConsumerState<_EditModuleSheet> createState() => _EditModuleSheetState();
}

class _EditModuleSheetState extends ConsumerState<_EditModuleSheet> {
  late final TextEditingController _keyController;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late bool _isActive;
  late Set<String> _selectedRoleValues;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.module.key);
    _nameController = TextEditingController(text: widget.module.name);
    _descriptionController =
        TextEditingController(text: widget.module.description);
    _isActive = widget.module.isActive;
    _selectedRoleValues = widget.module.accessRoles
        .map((role) => role.value)
        .where((value) => value != ModuleAccessRole.none.value)
        .toSet();
  }

  @override
  void dispose() {
    _keyController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Module',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            CustomFormField(
              label: 'Module key',
              hintText: 'tasks',
              textInputType: TextInputType.text,
              controller: _keyController,
              enable: false,
            ),
            const SizedBox(height: 12),
            CustomFormField(
              label: 'Module name',
              hintText: 'Tasks',
              textInputType: TextInputType.name,
              controller: _nameController,
            ),
            const SizedBox(height: 12),
            CustomFormField(
              label: 'Description (optional)',
              hintText: 'Tasks & activities management',
              textInputType: TextInputType.text,
              controller: _descriptionController,
            ),
            const SizedBox(height: 12),
            Text(
              'Available Roles',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ModuleAccessRole.values
                  .where((role) => role != ModuleAccessRole.none)
                  .map(
                    (role) => FilterChip(
                      label: Text(role.label),
                      selected: _selectedRoleValues.contains(role.value),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedRoleValues.add(role.value);
                          } else {
                            _selectedRoleValues.remove(role.value);
                          }
                        });
                      },
                    ),
                  )
                  .toList(),
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

    final updated = UserManagementModule(
      id: widget.module.id,
      key: widget.module.key,
      name: name,
      nameLower: name.toLowerCase(),
      description: _descriptionController.text.trim(),
      availableRoles: _selectedRoleValues.toList(),
      isActive: _isActive,
      createdAt: widget.module.createdAt,
      updatedAt: DateTime.now(),
    );

    await ref.read(userManagementRepositoryProvider).updateModule(updated);
    ref.invalidate(umModulesProvider);
    ref.invalidate(umModuleDetailsProvider(widget.module.id));

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
