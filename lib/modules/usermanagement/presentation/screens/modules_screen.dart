import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/domain/modules.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_module.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/custom_filledbutton.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ModulesManagementScreen extends ConsumerWidget {
  const ModulesManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesAsync = ref.watch(umModulesProvider);
    final theme = Theme.of(context);

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
                  title: 'Modules',
                  description: 'List of application modules',
                ),
                const Spacer(),
                modulesAsync.when(
                  data: (modules) => FilledButton.icon(
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(18)),
                        ),
                        builder: (_) =>
                            _AddModuleSheet(existingModules: modules),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Module'),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: modulesAsync.when(
                data: (modules) {
                  if (modules.isEmpty) {
                    return const EmptyStateView(
                      icon: Icons.widgets_outlined,
                      title: 'No module found',
                      description: 'Add modules to configure permissions.',
                    );
                  }

                  return ListView.separated(
                    itemCount: modules.length,
                    itemBuilder: (context, index) {
                      final module = modules[index];
                      final rolesLabel = module.accessRoles
                          .map((role) => role.label)
                          .join(', ');

                      return ListTile(
                        leading: const Icon(Icons.extension_outlined),
                        title: Text(
                          module.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${module.key} • ${module.isActive ? 'Active' : 'Inactive'} • $rolesLabel',
                          style: theme.textTheme.bodySmall,
                        ),
                        onTap: () => context.push(
                          '/service/usermanagement/modules/${module.id}',
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 1),
                  );
                },
                error: (error, _) => ErrorStateView(
                  title: 'Unable to load modules',
                  description: error.toString(),
                  onRetry: () => ref.invalidate(umModulesProvider),
                ),
                loading: () =>
                    const LoadingStateView(message: 'Loading modules...'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddModuleSheet extends ConsumerStatefulWidget {
  const _AddModuleSheet({
    required this.existingModules,
  });

  final List<UserManagementModule> existingModules;

  @override
  ConsumerState<_AddModuleSheet> createState() => _AddModuleSheetState();
}

class _AddModuleSheetState extends ConsumerState<_AddModuleSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isActive = true;
  bool _isSaving = false;
  String? _selectedKey;
  final Set<String> _selectedRoleValues = {
    ModuleAccessRole.admin.value,
    ModuleAccessRole.manager.value,
    ModuleAccessRole.user.value,
  };

  @override
  void initState() {
    super.initState();
    final availableKeys = _availableDefaultKeys;
    if (availableKeys.isNotEmpty) {
      _selectedKey = availableKeys.first;
      final defaultDefinition = _definitionForKey(_selectedKey!);
      if (defaultDefinition != null) {
        _nameController.text = defaultDefinition.name;
        _selectedRoleValues
          ..clear()
          ..addAll(
            defaultDefinition.availableRoles
                .where((role) => role != ModuleAccessRole.none)
                .map((role) => role.value),
          );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<String> get _availableDefaultKeys {
    final existingKeys =
        widget.existingModules.map((module) => module.key).toSet();
    return Modules.all
        .map((module) => module.key)
        .where((key) => !existingKeys.contains(key))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final availableKeys = _availableDefaultKeys;
    final noKeyAvailable = availableKeys.isEmpty;

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
              'Add Module',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            if (noKeyAvailable)
              const EmptyStateView(
                icon: Icons.info_outline,
                title: 'No module key available',
                description:
                    'All default module keys are already used. Delete one first to add another.',
              )
            else ...[
              Text(
                'Module Key',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedKey,
                isExpanded: true,
                items: availableKeys
                    .map(
                      (key) => DropdownMenuItem<String>(
                        value: key,
                        child: Text(key),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  final defaultDefinition = _definitionForKey(value);
                  setState(() {
                    _selectedKey = value;
                    if (defaultDefinition != null) {
                      _nameController.text = defaultDefinition.name;
                      _selectedRoleValues
                        ..clear()
                        ..addAll(
                          defaultDefinition.availableRoles
                              .where((role) => role != ModuleAccessRole.none)
                              .map((role) => role.value),
                        );
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              CommonTextInput(
                label: 'Module name',
                hintText: 'Tasks',
                type: CommonTextInputType.name,
                controller: _nameController,
              ),
              const SizedBox(height: 12),
              CommonTextInput(
                label: 'Description (optional)',
                hintText: 'Tasks & activities management',
                type: CommonTextInputType.text,
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
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CustomFilledButton(
                    text: _isSaving ? 'Saving...' : 'Save',
                    onPressed: noKeyAvailable || _isSaving ? null : _save,
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
    final key = _selectedKey?.trim().toLowerCase() ?? '';
    final name = _nameController.text.trim();
    if (key.isEmpty || name.isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await ref.read(userManagementRepositoryProvider).addModule(
          UserManagementModule(
            id: '',
            key: key,
            name: name,
            nameLower: name.toLowerCase(),
            description: _descriptionController.text.trim(),
            availableRoles: _selectedRoleValues.toList(),
            isActive: _isActive,
          ),
        );

    ref.invalidate(umModulesProvider);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  ModuleDefinition? _definitionForKey(String key) {
    for (final definition in Modules.all) {
      if (definition.key == key) {
        return definition;
      }
    }
    return null;
  }
}
