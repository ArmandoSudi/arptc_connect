import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_service.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/custom_filledbutton.dart';
import 'package:arptc_connect/widgets/custom_form_field.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ServicesManagementScreen extends ConsumerWidget {
  const ServicesManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(umServicesProvider);
    final departmentsAsync = ref.watch(umDepartmentsProvider);
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
                  title: 'Services',
                  description: 'List of services by department',
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
                      builder: (_) => const _AddServiceSheet(),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Service'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: servicesAsync.when(
                data: (services) {
                  if (services.isEmpty) {
                    return const EmptyStateView(
                      icon: Icons.workspaces_outline,
                      title: 'No service found',
                      description: 'Add at least one service to get started.',
                    );
                  }

                  final departmentById = departmentsAsync.maybeWhen(
                    data: (departments) => {
                      for (final department in departments)
                        department.id: department.name,
                    },
                    orElse: () => <String, String>{},
                  );

                  return ListView.separated(
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final service = services[index];
                      final departmentName =
                          departmentById[service.departmentId] ?? '-';

                      return ListTile(
                        leading: const Icon(Icons.work_outline),
                        title: Text(
                          service.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Department: $departmentName',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing:
                            service.code.isEmpty ? null : Text(service.code),
                        onTap: () => context.push(
                          '/service/usermanagement/services/${service.id}',
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 1),
                  );
                },
                error: (error, _) => ErrorStateView(
                  title: 'Unable to load services',
                  description: error.toString(),
                  onRetry: () => ref.invalidate(umServicesProvider),
                ),
                loading: () =>
                    const LoadingStateView(message: 'Loading services...'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddServiceSheet extends ConsumerStatefulWidget {
  const _AddServiceSheet();

  @override
  ConsumerState<_AddServiceSheet> createState() => _AddServiceSheetState();
}

class _AddServiceSheetState extends ConsumerState<_AddServiceSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  String? _selectedDepartmentId;
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
                description: 'Create a department first.',
              ),
            );
          }

          _selectedDepartmentId ??= departments.first.id;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Service',
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
                  });
                },
              ),
              const SizedBox(height: 12),
              CustomFormField(
                label: 'Service name',
                hintText: 'Enter service name',
                textInputType: TextInputType.name,
                controller: _nameController,
              ),
              const SizedBox(height: 12),
              CustomFormField(
                label: 'Code (optional)',
                hintText: 'SRV_PROC',
                textInputType: TextInputType.text,
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
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(),
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

    if (name.isEmpty || departmentId.isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await ref.read(userManagementRepositoryProvider).addService(
          UserManagementService(
            id: '',
            code: _codeController.text.trim(),
            name: name,
            nameLower: name.toLowerCase(),
            departmentId: departmentId,
            headUserId: null,
            isActive: true,
          ),
        );

    ref.invalidate(umServicesProvider);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
