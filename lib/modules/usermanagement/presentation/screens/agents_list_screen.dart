import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/domain/modules.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_agent.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_bureau.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/widgets/app_search_bar.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/custom_filledbutton.dart';
import 'package:arptc_connect/widgets/custom_form_field.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:arptc_connect/widgets/page_header_simple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AgentsManagementScreen extends ConsumerStatefulWidget {
  const AgentsManagementScreen({super.key});

  @override
  ConsumerState<AgentsManagementScreen> createState() =>
      _AgentsManagementScreenState();
}

class _AgentsManagementScreenState
    extends ConsumerState<AgentsManagementScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    ref.read(umAgentSearchQueryProvider.notifier).state = '';
  }

  @override
  void dispose() {
    ref.read(umAgentSearchQueryProvider.notifier).state = '';
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agentsAsync = ref.watch(filteredUmAgentsProvider);
    final departmentsAsync = ref.watch(umDepartmentsProvider);
    final servicesAsync = ref.watch(umServicesProvider);
    final bureauxAsync = ref.watch(umBureauxProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: ContentView(
        child: Column(
          children: [
            Row(
              children: [

                // PAGE HADER WITH ADD BUTTON
                const PageHeaderSimple(
                  title: 'Liste des agents',
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(18)),
                      ),
                      builder: (_) => const AddAgentSheet(),
                    );

                    // context.push('/service/usermanagement/agents/add');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un Agent'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // SEARCH BAR
            AppSearchBar(
              controller: _searchController,
              hintText: 'Rechercher un agent par son nom',
              onChanged: (value) {
                ref.read(umAgentSearchQueryProvider.notifier).state = value;
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: agentsAsync.when(
                data: (agents) {

                  if (agents.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.group_outlined,
                      title: 'No agent found',
                      description: _searchController.text.isEmpty
                          ? 'Add the first agent.'
                          : 'Try another search term.',
                    );
                  }

                  final departmentsById = departmentsAsync.maybeWhen(
                    data: (departments) => {
                      for (final department in departments)
                        department.id: department.name,
                    },
                    orElse: () => <String, String>{},
                  );
                  final servicesById = servicesAsync.maybeWhen(
                    data: (services) => {
                      for (final service in services) service.id: service.name,
                    },
                    orElse: () => <String, String>{},
                  );
                  final bureauxById = bureauxAsync.maybeWhen(
                    data: (bureaux) => {
                      for (final bureau in bureaux) bureau.id: bureau.name,
                    },
                    orElse: () => <String, String>{},
                  );

                  return ListView.separated(
                    itemCount: agents.length,
                    itemBuilder: (context, index) {
                      final agent = agents[index];
                      final department =
                          departmentsById[agent.departmentId] ?? '-';
                      final service = servicesById[agent.serviceId] ?? '-';
                      final bureau = bureauxById[agent.bureauId] ?? '-';

                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(_initials(agent)),
                        ),
                        title: Text(
                          agent.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${_formatPosition(agent.position)} • $department ',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing:
                            agent.matricule.isEmpty ? null : Text(agent.matricule),
                        onTap: () => context.push(
                          '/service/usermanagement/agents/${agent.id}',
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 1),
                  );
                },
                error: (error, _) => ErrorStateView(
                  title: 'Unable to load agents',
                  description: error.toString(),
                  onRetry: () => ref.invalidate(umAgentsProvider),
                ),
                loading: () =>
                    const LoadingStateView(message: 'Loading agents...'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddAgentSheet extends ConsumerStatefulWidget {
  const AddAgentSheet({super.key});

  @override
  ConsumerState<AddAgentSheet> createState() => AddAgentSheetState();
}

class AddAgentSheetState extends ConsumerState<AddAgentSheet> {
  static const String _none = '__NONE__';
  static const List<String> _positions = [
    'DEPARTMENT_HEAD',
    'SERVICE_HEAD',
    'BUREAU_HEAD',
    'BUREAU_ATTACHE',
  ];

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _postNameController = TextEditingController();
  final TextEditingController _matriculeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String _position = _positions.last;
  String? _selectedDepartmentId;
  String? _selectedServiceId;
  String? _selectedBureauId;
  bool _isSaving = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _nameController.dispose();
    _postNameController.dispose();
    _matriculeController.dispose();
    _emailController.dispose();
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
          if (departments.isEmpty) {
            return const SizedBox(
              height: 220,
              child: EmptyStateView(
                icon: Icons.account_tree_outlined,
                title: 'No department available',
                description: 'Create departments before adding agents.',
              ),
            );
          }

          _selectedDepartmentId ??= departments.first.id;

          return servicesAsync.when(
            data: (services) {
              final servicesByDepartment = services
                  .where((service) =>
                      service.departmentId == _selectedDepartmentId)
                  .toList();

              if (servicesByDepartment.isNotEmpty &&
                  servicesByDepartment
                          .any((service) => service.id == _selectedServiceId) ==
                      false) {
                _selectedServiceId = servicesByDepartment.first.id;
              }

              return bureauxAsync.when(
                data: (bureaux) {
                  final bureauxByService = _filterBureaux(
                    bureaux: bureaux,
                    departmentId: _selectedDepartmentId ?? '',
                    serviceId: _selectedServiceId ?? '',
                  );

                  if (bureauxByService.isNotEmpty &&
                      bureauxByService.any(
                              (bureau) => bureau.id == _selectedBureauId) ==
                          false) {
                    _selectedBureauId = bureauxByService.first.id;
                  }

                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Agent',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        CustomFormField(
                          label: 'First name',
                          hintText: 'Enter first name',
                          textInputType: TextInputType.name,
                          controller: _firstNameController,
                        ),
                        const SizedBox(height: 12),
                        CustomFormField(
                          label: 'Name',
                          hintText: 'Enter name',
                          textInputType: TextInputType.name,
                          controller: _nameController,
                        ),
                        const SizedBox(height: 12),
                        CustomFormField(
                          label: 'Post name',
                          hintText: 'Enter post name',
                          textInputType: TextInputType.name,
                          controller: _postNameController,
                        ),
                        const SizedBox(height: 12),
                        CustomFormField(
                          label: 'Matricule',
                          hintText: 'Enter matricule',
                          textInputType: TextInputType.text,
                          controller: _matriculeController,
                        ),
                        const SizedBox(height: 12),
                        CustomFormField(
                          label: 'Email',
                          hintText: 'agent@organisation.com',
                          textInputType: TextInputType.emailAddress,
                          controller: _emailController,
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
                          value: _selectedDepartmentId,
                          items: departments
                              .map((department) => DropdownMenuItem<String>(
                                    value: department.id,
                                    child: Text(department.name),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedDepartmentId = value;
                              _selectedServiceId = null;
                              _selectedBureauId = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _SectionDropdown(
                          label: 'Service',
                          value: servicesByDepartment.isEmpty
                              ? null
                              : _selectedServiceId,
                          items: servicesByDepartment
                              .map((service) => DropdownMenuItem<String>(
                                    value: service.id,
                                    child: Text(service.name),
                                  ))
                              .toList(),
                          enabled: !_isServiceOptional(_position),
                          hintText: 'Select service',
                          onChanged: servicesByDepartment.isEmpty
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _selectedServiceId = value;
                                    _selectedBureauId = null;
                                  });
                                },
                        ),
                        const SizedBox(height: 12),
                        _SectionDropdown(
                          label: 'Bureau',
                          value: bureauxByService.isEmpty
                              ? null
                              : _selectedBureauId,
                          items: bureauxByService
                              .map((bureau) => DropdownMenuItem<String>(
                                    value: bureau.id,
                                    child: Text(bureau.name),
                                  ))
                              .toList(),
                          enabled: !_isBureauOptional(_position),
                          hintText: 'Select bureau',
                          onChanged: bureauxByService.isEmpty
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _selectedBureauId = value;
                                  });
                                },
                        ),
                        const SizedBox(height: 16),
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
        email.isEmpty) {
      return;
    }

    final departmentId = _selectedDepartmentId ?? '';
    if (departmentId.isEmpty) {
      return;
    }

    String serviceId = _selectedServiceId ?? _none;
    String bureauId = _selectedBureauId ?? _none;

    if (_position == 'DEPARTMENT_HEAD') {
      serviceId = _none;
      bureauId = _none;
    } else if (_position == 'SERVICE_HEAD') {
      if (_selectedServiceId == null || _selectedServiceId!.isEmpty) return;
      bureauId = _none;
      serviceId = _selectedServiceId!;
    } else {
      if (_selectedServiceId == null || _selectedServiceId!.isEmpty) return;
      if (_selectedBureauId == null || _selectedBureauId!.isEmpty) return;
      serviceId = _selectedServiceId!;
      bureauId = _selectedBureauId!;
    }

    setState(() {
      _isSaving = true;
    });

    Map<String, String> modulePermissions = Modules.emptyPermissions();
    try {
      final configuredModules = await ref.read(umModulesProvider.future);
      if (configuredModules.isNotEmpty) {
        modulePermissions = {
          for (final module in configuredModules)
            if (module.isActive) module.key: ModuleAccessRole.none.value,
        };
        if (modulePermissions.isEmpty) {
          modulePermissions = Modules.emptyPermissions();
        }
      }
    } catch (_) {
      modulePermissions = Modules.emptyPermissions();
    }

    await ref.read(userManagementRepositoryProvider).addAgent(
          UserManagementAgent(
            id: '',
            firstName: firstName,
            name: name,
            postName: postName,
            matricule: matricule,
            email: email,
            emailLower: email.toLowerCase(),
            profilePictureUrl: null,
            position: _position,
            departmentId: departmentId,
            serviceId: serviceId,
            bureauId: bureauId,
            isActive: true,
            modulePermissions: modulePermissions,
          ),
        );

    ref.invalidate(umAgentsProvider);

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

String _initials(UserManagementAgent agent) {
  final first = agent.firstName.trim().isNotEmpty
      ? agent.firstName.trim()[0].toUpperCase()
      : '';
  final second =
      agent.name.trim().isNotEmpty ? agent.name.trim()[0].toUpperCase() : '';
  final initials = '$first$second';
  return initials.isEmpty ? '?' : initials;
}

String _formatPosition(String position) {
  final words = position
      .trim()
      .split('_')
      .where((word) => word.isNotEmpty)
      .map((word) =>
          '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
      .toList();

  if (words.isEmpty) {
    return position;
  }

  return words.join(' ');
}
