import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/domain/modules.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_agent.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_bureau.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_module.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/entity_details_providers.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/custom_filledbutton.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:arptc_connect/widgets/page_header_simple.dart';
import 'package:arptc_connect/widgets/yes_or_no_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AgentDetailsScreen extends ConsumerWidget {
  const AgentDetailsScreen({
    required this.agentId,
    super.key,
  });

  final String agentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentAsync = ref.watch(umAgentDetailsProvider(agentId));
    final departmentsAsync = ref.watch(umDepartmentsProvider);
    final servicesAsync = ref.watch(umServicesProvider);
    final bureauxAsync = ref.watch(umBureauxProvider);
    final modulesAsync = ref.watch(umModulesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: ContentView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeaderSimple(
              title: "Détails de l'agent",
            ),
            const SizedBox(height: 20),
            Expanded(
              child: agentAsync.when(
                data: (agent) {
                  final departmentName = departmentsAsync.maybeWhen(
                    data: (departments) {
                      for (final department in departments) {
                        if (department.id == agent.departmentId) {
                          return department.name;
                        }
                      }
                      return '-';
                    },
                    orElse: () => '-',
                  );
                  final serviceName = servicesAsync.maybeWhen(
                    data: (services) {
                      for (final service in services) {
                        if (service.id == agent.serviceId) {
                          return service.name;
                        }
                      }
                      return '-';
                    },
                    orElse: () => '-',
                  );
                  final bureauName = bureauxAsync.maybeWhen(
                    data: (bureaux) {
                      for (final bureau in bureaux) {
                        if (bureau.id == agent.bureauId) {
                          return bureau.name;
                        }
                      }
                      return '-';
                    },
                    orElse: () => '-',
                  );
                  final moduleDefinitions = modulesAsync.when(
                    data: _resolveModuleDefinitions,
                    error: (_, __) => Modules.all,
                    loading: () => Modules.all,
                  );

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeaderCard(
                          agent: agent,
                          onEdit: () {
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(18),
                                ),
                              ),
                              builder: (_) => _EditAgentSheet(
                                agent: agent,
                                modules: moduleDefinitions,
                              ),
                            );
                          },
                          onDelete: () async {
                            final confirm = await showAdaptiveYesNoDialog(
                              context,
                              'Delete User',
                              'Are you sure you want to delete "${agent.displayName}"?',
                              confirmText: 'Delete',
                              cancelText: 'Cancel',
                              isDestructive: true,
                            );
                            if (confirm != true) return;

                            await ref
                                .read(userManagementRepositoryProvider)
                                .deleteAgent(agent.id);

                            ref.invalidate(umAgentsProvider);
                            ref.invalidate(umAgentDetailsProvider(agent.id));

                            if (context.mounted) {
                              context.pop();
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        _InformationCard(
                          agent: agent,
                          theme: theme,
                          departmentName: departmentName,
                          serviceName: serviceName,
                          bureauName: bureauName,
                        ),
                        const SizedBox(height: 16),
                        _PermissionsCard(
                          agent: agent,
                          theme: theme,
                          modules: moduleDefinitions,
                        ),
                      ],
                    ),
                  );
                },
                error: (error, _) => ErrorStateView(
                  title: 'Unable to load user details',
                  description: error.toString(),
                  onRetry: () =>
                      ref.invalidate(umAgentDetailsProvider(agentId)),
                ),
                loading: () => const LoadingStateView(
                  message: 'Loading user details...',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.agent,
    required this.onEdit,
    required this.onDelete,
  });

  final UserManagementAgent agent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPicture =
        agent.profilePictureUrl != null && agent.profilePictureUrl!.isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 38,
              backgroundImage:
                  hasPicture ? NetworkImage(agent.profilePictureUrl!) : null,
              child: hasPicture
                  ? null
                  : Text(
                      _initialsFor(agent.firstName, agent.name),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    agent.displayName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    agent.email.isNotEmpty ? agent.email : 'No email',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatPosition(agent.position),
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.agent,
    required this.theme,
    required this.departmentName,
    required this.serviceName,
    required this.bureauName,
  });

  final UserManagementAgent agent;
  final ThemeData theme;
  final String departmentName;
  final String serviceName;
  final String bureauName;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'First name',
              value: agent.firstName,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Name',
              value: agent.name,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Post name',
              value: agent.postName,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Matricule',
              value: agent.matricule,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Email',
              value: agent.email,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Email (lower)',
              value: agent.emailLower,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'User ID',
              value: agent.id,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Profile picture URL',
              value: agent.profilePictureUrl ?? '-',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Position',
              value: _formatPosition(agent.position),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Department',
              value: '$departmentName (${agent.departmentId})',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Service',
              value: '$serviceName (${agent.serviceId})',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Bureau',
              value: '$bureauName (${agent.bureauId})',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Status',
              value: agent.isActive ? 'Active' : 'Inactive',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Created At',
              value: _formatDateTime(agent.createdAt),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Updated At',
              value: _formatDateTime(agent.updatedAt),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionsCard extends StatelessWidget {
  const _PermissionsCard({
    required this.agent,
    required this.theme,
    required this.modules,
  });

  final UserManagementAgent agent;
  final ThemeData theme;
  final List<ModuleDefinition> modules;

  @override
  Widget build(BuildContext context) {
    final permissionRows = _buildPermissionRows(
      agent.modulePermissions,
      modules,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permissions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (permissionRows.isEmpty)
              Text(
                'No permissions assigned.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: permissionRows.map((row) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _InfoRow(
                      label: row.moduleName,
                      value: Modules.roleLabel(row.roleValue),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _EditAgentSheet extends ConsumerStatefulWidget {
  const _EditAgentSheet({
    required this.agent,
    required this.modules,
  });

  final UserManagementAgent agent;
  final List<ModuleDefinition> modules;

  @override
  ConsumerState<_EditAgentSheet> createState() => _EditAgentSheetState();
}

class _EditAgentSheetState extends ConsumerState<_EditAgentSheet> {
  static const String _none = '__NONE__';
  static const List<String> _positions = [
    'DEPARTMENT_HEAD',
    'SERVICE_HEAD',
    'BUREAU_HEAD',
    'BUREAU_ATTACHE',
  ];

  late final TextEditingController _firstNameController;
  late final TextEditingController _nameController;
  late final TextEditingController _postNameController;
  late final TextEditingController _matriculeController;
  late final TextEditingController _emailController;
  late final TextEditingController _profilePictureController;
  late Map<String, String> _modulePermissions;

  late String _position;
  late String _departmentId;
  String? _serviceId;
  String? _bureauId;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.agent.firstName);
    _nameController = TextEditingController(text: widget.agent.name);
    _postNameController = TextEditingController(text: widget.agent.postName);
    _matriculeController = TextEditingController(text: widget.agent.matricule);
    _emailController = TextEditingController(text: widget.agent.email);
    _profilePictureController =
        TextEditingController(text: widget.agent.profilePictureUrl ?? '');
    _modulePermissions = _buildEditablePermissions(
      widget.agent.modulePermissions,
      widget.modules,
    );

    _position = widget.agent.position;
    _departmentId = widget.agent.departmentId;
    _serviceId =
        widget.agent.serviceId == _none ? null : widget.agent.serviceId;
    _bureauId = widget.agent.bureauId == _none ? null : widget.agent.bureauId;
    _isActive = widget.agent.isActive;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _nameController.dispose();
    _postNameController.dispose();
    _matriculeController.dispose();
    _emailController.dispose();
    _profilePictureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final departmentsAsync = ref.watch(umDepartmentsProvider);
    final servicesAsync = ref.watch(umServicesProvider);
    final bureauxAsync = ref.watch(umBureauxProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: departmentsAsync.when(
        data: (departments) {
          if (departments.isNotEmpty &&
              departments.any((department) => department.id == _departmentId) ==
                  false) {
            _departmentId = departments.first.id;
          }

          return servicesAsync.when(
            data: (services) {
              final filteredServices = services
                  .where((service) => service.departmentId == _departmentId)
                  .toList();

              if (filteredServices.isNotEmpty &&
                  filteredServices.any((service) => service.id == _serviceId) ==
                      false) {
                _serviceId = filteredServices.first.id;
              }

              return bureauxAsync.when(
                data: (bureaux) {
                  final filteredBureaux = _filterBureaux(
                    bureaux: bureaux,
                    departmentId: _departmentId,
                    serviceId: _serviceId ?? '',
                  );

                  if (filteredBureaux.isNotEmpty &&
                      filteredBureaux.any((bureau) => bureau.id == _bureauId) ==
                          false) {
                    _bureauId = filteredBureaux.first.id;
                  }

                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit User',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        CommonTextInput(
                          label: 'First name',
                          hintText: 'First name',
                          type: CommonTextInputType.name,
                          controller: _firstNameController,
                        ),
                        const SizedBox(height: 12),
                        CommonTextInput(
                          label: 'Name',
                          hintText: 'Name',
                          type: CommonTextInputType.name,
                          controller: _nameController,
                        ),
                        const SizedBox(height: 12),
                        CommonTextInput(
                          label: 'Post name',
                          hintText: 'Post name',
                          type: CommonTextInputType.name,
                          controller: _postNameController,
                        ),
                        const SizedBox(height: 12),
                        CommonTextInput(
                          label: 'Matricule',
                          hintText: 'Matricule',
                          type: CommonTextInputType.text,
                          controller: _matriculeController,
                        ),
                        const SizedBox(height: 12),
                        CommonTextInput(
                          label: 'Email',
                          hintText: 'user@organisation.com',
                          type: CommonTextInputType.email,
                          controller: _emailController,
                        ),
                        const SizedBox(height: 12),
                        CommonTextInput(
                          label: 'Profile picture URL',
                          hintText: 'https://...',
                          type: CommonTextInputType.url,
                          controller: _profilePictureController,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Position',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _position,
                          isExpanded: true,
                          items: _positions.map((position) {
                            return DropdownMenuItem<String>(
                              value: position,
                              child: Text(_formatPosition(position)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _position = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _SectionDropdown(
                          label: 'Department',
                          value: _departmentId,
                          items: departments
                              .map((department) => DropdownMenuItem<String>(
                                    value: department.id,
                                    child: Text(department.name),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _departmentId = value;
                              _serviceId = null;
                              _bureauId = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _SectionDropdown(
                          label: 'Service',
                          value:
                              _isServiceOptional(_position) ? null : _serviceId,
                          items: filteredServices
                              .map((service) => DropdownMenuItem<String>(
                                    value: service.id,
                                    child: Text(service.name),
                                  ))
                              .toList(),
                          enabled: !_isServiceOptional(_position),
                          hintText: 'Select service',
                          onChanged: filteredServices.isEmpty
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _serviceId = value;
                                    _bureauId = null;
                                  });
                                },
                        ),
                        const SizedBox(height: 12),
                        _SectionDropdown(
                          label: 'Bureau',
                          value:
                              _isBureauOptional(_position) ? null : _bureauId,
                          items: filteredBureaux
                              .map((bureau) => DropdownMenuItem<String>(
                                    value: bureau.id,
                                    child: Text(bureau.name),
                                  ))
                              .toList(),
                          enabled: !_isBureauOptional(_position),
                          hintText: 'Select bureau',
                          onChanged: filteredBureaux.isEmpty
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _bureauId = value;
                                  });
                                },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Module Permissions',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        ...widget.modules.map(
                          (module) {
                            final moduleKey =
                                Modules.normalizeModuleKey(module.key);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ModulePermissionField(
                                moduleName: module.name,
                                availableRoles: module.availableRoles,
                                value: _modulePermissions[moduleKey] ??
                                    ModuleAccessRole.none.value,
                                onChanged: (value) {
                                  setState(() {
                                    _modulePermissions[moduleKey] = value;
                                  });
                                },
                              ),
                            );
                          },
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
                                onPressed: _isSaving
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                error: (error, _) => SizedBox(
                  height: 220,
                  child: ErrorStateView(
                    title: 'Unable to load bureaux',
                    description: error.toString(),
                    onRetry: () => ref.invalidate(umBureauxProvider),
                  ),
                ),
                loading: () => const SizedBox(
                  height: 180,
                  child: LoadingStateView(message: 'Loading bureaux...'),
                ),
              );
            },
            error: (error, _) => SizedBox(
              height: 220,
              child: ErrorStateView(
                title: 'Unable to load services',
                description: error.toString(),
                onRetry: () => ref.invalidate(umServicesProvider),
              ),
            ),
            loading: () => const SizedBox(
              height: 180,
              child: LoadingStateView(message: 'Loading services...'),
            ),
          );
        },
        error: (error, _) => SizedBox(
          height: 220,
          child: ErrorStateView(
            title: 'Unable to load departments',
            description: error.toString(),
            onRetry: () => ref.invalidate(umDepartmentsProvider),
          ),
        ),
        loading: () => const SizedBox(
          height: 180,
          child: LoadingStateView(message: 'Loading departments...'),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final firstName = _firstNameController.text.trim();
    final name = _nameController.text.trim();
    final postName = _postNameController.text.trim();
    final matricule = _matriculeController.text.trim();
    final email = _emailController.text.trim();
    if (firstName.isEmpty ||
        name.isEmpty ||
        postName.isEmpty ||
        matricule.isEmpty ||
        email.isEmpty ||
        _departmentId.isEmpty) {
      return;
    }

    String serviceId = _serviceId ?? _none;
    String bureauId = _bureauId ?? _none;

    if (_position == 'DEPARTMENT_HEAD') {
      serviceId = _none;
      bureauId = _none;
    } else if (_position == 'SERVICE_HEAD') {
      if (_serviceId == null || _serviceId!.isEmpty) return;
      serviceId = _serviceId!;
      bureauId = _none;
    } else {
      if (_serviceId == null || _serviceId!.isEmpty) return;
      if (_bureauId == null || _bureauId!.isEmpty) return;
      serviceId = _serviceId!;
      bureauId = _bureauId!;
    }

    setState(() {
      _isSaving = true;
    });

    final normalizedPermissions = Modules.normalizePermissions(
      _buildEditablePermissions(
        _modulePermissions,
        widget.modules,
      ),
      includeDefaultModules: false,
    );

    final updated = UserManagementAgent(
      id: widget.agent.id,
      firstName: firstName,
      name: name,
      postName: postName,
      matricule: matricule,
      email: email,
      emailLower: email.toLowerCase(),
      profilePictureUrl: _profilePictureController.text.trim().isEmpty
          ? null
          : _profilePictureController.text.trim(),
      position: _position,
      departmentId: _departmentId,
      serviceId: serviceId,
      bureauId: bureauId,
      isActive: _isActive,
      modulePermissions: normalizedPermissions,
      createdAt: widget.agent.createdAt,
      updatedAt: DateTime.now(),
    );

    await ref.read(userManagementRepositoryProvider).updateAgent(updated);
    ref.invalidate(umAgentsProvider);
    ref.invalidate(umAgentDetailsProvider(widget.agent.id));

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  List<UserManagementBureau> _filterBureaux({
    required List<UserManagementBureau> bureaux,
    required String departmentId,
    required String serviceId,
  }) {
    return bureaux.where((bureau) {
      final departmentMatches = bureau.departmentId == departmentId;
      final serviceMatches =
          serviceId.isEmpty ? true : bureau.serviceId == serviceId;
      return departmentMatches && serviceMatches;
    }).toList();
  }

  bool _isServiceOptional(String position) => position == 'DEPARTMENT_HEAD';

  bool _isBureauOptional(String position) =>
      position == 'DEPARTMENT_HEAD' || position == 'SERVICE_HEAD';
}

class _SectionDropdown extends StatelessWidget {
  const _SectionDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
    this.hintText,
  });

  final String label;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;
  final bool enabled;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: enabled ? onChanged : null,
          hint: hintText == null ? null : Text(hintText!),
        ),
      ],
    );
  }
}

class _ModulePermissionField extends StatelessWidget {
  const _ModulePermissionField({
    required this.moduleName,
    required this.availableRoles,
    required this.value,
    required this.onChanged,
  });

  final String moduleName;
  final List<ModuleAccessRole> availableRoles;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final effectiveValue = ModuleAccessRole.fromValue(value).value;

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            moduleName,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: DropdownButtonFormField<String>(
            value: effectiveValue,
            isExpanded: true,
            items: availableRoles
                .map(
                  (role) => DropdownMenuItem<String>(
                    value: role.value,
                    child: Text(role.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              onChanged(value);
            },
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
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
    );
  }
}

String _initialsFor(String firstName, String name) {
  final first =
      firstName.trim().isNotEmpty ? firstName.trim()[0].toUpperCase() : '';
  final second = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '';
  final initials = '$first$second';
  if (initials.isNotEmpty) {
    return initials;
  }
  return '?';
}

String _formatPosition(String position) {
  final words = position
      .trim()
      .split('_')
      .where((word) => word.isNotEmpty)
      .map(
        (word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .toList();

  if (words.isEmpty) {
    return position;
  }
  return words.join(' ');
}

ModuleDefinition _toModuleDefinition(UserManagementModule module) {
  return ModuleDefinition(
    key: module.key,
    name: module.name,
    availableRoles: module.accessRolesWithNone,
  );
}

List<ModuleDefinition> _resolveModuleDefinitions(
  List<UserManagementModule> configuredModules,
) {
  final merged = <String, ModuleDefinition>{};

  for (final configured in configuredModules) {
    merged[configured.key] = _toModuleDefinition(configured);
  }

  for (final module in Modules.all) {
    merged.putIfAbsent(module.key, () => module);
  }

  return merged.values.toList()
    ..sort(
      (left, right) => left.name.toLowerCase().compareTo(
            right.name.toLowerCase(),
          ),
    );
}

class _PermissionRow {
  const _PermissionRow({
    required this.moduleName,
    required this.roleValue,
  });

  final String moduleName;
  final String roleValue;
}

Map<String, String> _buildEditablePermissions(
  Map<String, dynamic> rawPermissions,
  List<ModuleDefinition> modules,
) {
  final rawNormalized = Modules.normalizePermissions(
    rawPermissions,
    includeDefaultModules: false,
  );
  final editable = <String, String>{};

  for (final module in modules) {
    final key = Modules.normalizeModuleKey(module.key);
    if (key.isEmpty) {
      continue;
    }
    editable[key] = ModuleAccessRole.fromValue(rawNormalized[key]).value;
  }

  for (final entry in rawNormalized.entries) {
    editable.putIfAbsent(
      entry.key,
      () => ModuleAccessRole.fromValue(entry.value).value,
    );
  }

  return editable;
}

List<_PermissionRow> _buildPermissionRows(
  Map<String, String> modulePermissions,
  List<ModuleDefinition> modules,
) {
  final normalized = Modules.normalizePermissions(
    modulePermissions,
    includeDefaultModules: false,
  );
  final moduleByKey = <String, ModuleDefinition>{
    for (final module in modules)
      Modules.normalizeModuleKey(module.key): module,
  };

  final orderedKeys = <String>[
    ...moduleByKey.keys,
    ...normalized.keys.where((key) => !moduleByKey.containsKey(key)),
  ];

  return orderedKeys.map((moduleKey) {
    final moduleName =
        moduleByKey[moduleKey]?.name ?? Modules.moduleName(moduleKey);
    final roleValue = normalized[moduleKey] ?? ModuleAccessRole.none.value;
    return _PermissionRow(
      moduleName: moduleName,
      roleValue: roleValue,
    );
  }).toList();
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return '-';
  }
  return value.toIso8601String();
}
