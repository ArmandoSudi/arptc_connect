import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_bureau.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_service.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/widgets/app_search_bar.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/custom_filledbutton.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:arptc_connect/widgets/page_header_simple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BureauxManagementScreen extends ConsumerStatefulWidget {
  const BureauxManagementScreen({super.key});

  @override
  ConsumerState<BureauxManagementScreen> createState() =>
      _BureauxManagementScreenState();
}

class _BureauxManagementScreenState
    extends ConsumerState<BureauxManagementScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    ref.read(umBureauSearchQueryProvider.notifier).state = '';
  }

  @override
  void dispose() {
    ref.read(umBureauSearchQueryProvider.notifier).state = '';
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bureauxAsync = ref.watch(filteredUmBureauxProvider);
    final servicesAsync = ref.watch(umServicesProvider);
    final departmentsAsync = ref.watch(umDepartmentsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: ContentView(
        child: Column(
          children: [
            Row(
              children: [
                // IconButton(
                //   icon: const Icon(Icons.arrow_back_ios),
                //   onPressed: () => context.pop(),
                // ),
                const PageHeaderSimple(
                  title: 'Bureaux',
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
                      builder: (_) => const _AddBureauSheet(),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Bureau'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppSearchBar(
              controller: _searchController,
              hintText: 'Search bureau by name',
              onChanged: (value) {
                ref.read(umBureauSearchQueryProvider.notifier).state = value;
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: bureauxAsync.when(
                data: (bureaux) {
                  if (bureaux.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.business_outlined,
                      title: 'No bureau found',
                      description: _searchController.text.isEmpty
                          ? 'Create your first bureau.'
                          : 'Try another name in the search bar.',
                    );
                  }

                  final servicesById = servicesAsync.maybeWhen(
                    data: (services) => {
                      for (final service in services) service.id: service,
                    },
                    orElse: () => <String, UserManagementService>{},
                  );

                  final departmentById = departmentsAsync.maybeWhen(
                    data: (departments) => {
                      for (final department in departments)
                        department.id: department.name,
                    },
                    orElse: () => <String, String>{},
                  );

                  return Card(
                    child: ListView.separated(
                      itemCount: bureaux.length,
                      itemBuilder: (context, index) {
                        final bureau = bureaux[index];
                        final service = servicesById[bureau.serviceId];
                        final departmentName =
                            departmentById[bureau.departmentId] ?? '-';

                        return ListTile(
                          leading: const Icon(Icons.account_balance_outlined),
                          title: Text(
                            bureau.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Department: $departmentName • Service: ${service?.name ?? '-'}',
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing:
                              bureau.code.isEmpty ? null : Text(bureau.code),
                          onTap: () => context.push(
                            '/service/usermanagement/bureaux/${bureau.id}',
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const Divider(height: 1),
                    ),
                  );
                },
                error: (error, _) => ErrorStateView(
                  title: 'Unable to load bureaux',
                  description: error.toString(),
                  onRetry: () => ref.invalidate(umBureauxProvider),
                ),
                loading: () =>
                    const LoadingStateView(message: 'Loading bureaux...'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddBureauSheet extends ConsumerStatefulWidget {
  const _AddBureauSheet();

  @override
  ConsumerState<_AddBureauSheet> createState() => _AddBureauSheetState();
}

class _AddBureauSheetState extends ConsumerState<_AddBureauSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  String? _selectedDepartmentId;
  String? _selectedServiceId;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final departmentsAsync = ref.watch(umDepartmentsProvider);
    final servicesAsync = ref.watch(umServicesProvider);

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
                description: 'Create a department before creating a bureau.',
              ),
            );
          }

          _selectedDepartmentId ??= departments.first.id;

          return servicesAsync.when(
            data: (services) {
              final filteredServices = services
                  .where((service) =>
                      service.departmentId == _selectedDepartmentId)
                  .toList();

              if (filteredServices.isNotEmpty &&
                  (filteredServices
                          .any((service) => service.id == _selectedServiceId) ==
                      false)) {
                _selectedServiceId = filteredServices.first.id;
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Bureau',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Department',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedDepartmentId,
                    isExpanded: true,
                    items: departments.map((department) {
                      return DropdownMenuItem<String>(
                        value: department.id,
                        child: Text(department.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedDepartmentId = value;
                        _selectedServiceId = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Service',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: filteredServices.isEmpty ? null : _selectedServiceId,
                    isExpanded: true,
                    items: filteredServices.map((service) {
                      return DropdownMenuItem<String>(
                        value: service.id,
                        child: Text(service.name),
                      );
                    }).toList(),
                    onChanged: filteredServices.isEmpty
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedServiceId = value;
                            });
                          },
                    hint: const Text('Select service'),
                  ),
                  if (filteredServices.isEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'No service found for this department.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  CommonTextInput(
                    label: 'Bureau name',
                    hintText: 'Enter bureau name',
                    type: CommonTextInputType.name,
                    controller: _nameController,
                  ),
                  const SizedBox(height: 12),
                  CommonTextInput(
                    label: 'Code (optional)',
                    hintText: 'BUR_LOCAL',
                    type: CommonTextInputType.text,
                    controller: _codeController,
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
    final name = _nameController.text.trim();
    final departmentId = _selectedDepartmentId ?? '';
    final serviceId = _selectedServiceId ?? '';

    if (name.isEmpty || departmentId.isEmpty || serviceId.isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await ref.read(userManagementRepositoryProvider).addBureau(
          UserManagementBureau(
            id: '',
            code: _codeController.text.trim(),
            name: name,
            nameLower: name.toLowerCase(),
            departmentId: departmentId,
            serviceId: serviceId,
            headUserId: null,
            isActive: true,
          ),
        );

    ref.invalidate(umBureauxProvider);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
