import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_service.dart';
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

class ServiceDetailsScreen extends ConsumerWidget {
  const ServiceDetailsScreen({
    required this.serviceId,
    super.key,
  });

  final String serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(umServiceDetailsProvider(serviceId));
    final departmentsAsync = ref.watch(umDepartmentsProvider);

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
                  title: 'Service Details',
                  description: 'View and edit service fields',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: serviceAsync.when(
                data: (service) {
                  final departmentName = departmentsAsync.maybeWhen(
                    data: (departments) {
                      for (final department in departments) {
                        if (department.id == service.departmentId) {
                          return department.name;
                        }
                      }
                      return '-';
                    },
                    orElse: () => '-',
                  );

                  return SingleChildScrollView(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  service.name,
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
                                      builder: (_) =>
                                          _EditServiceSheet(service: service),
                                    );
                                  },
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final confirm =
                                        await showAdaptiveYesNoDialog(
                                      context,
                                      'Delete Service',
                                      'Are you sure you want to delete "${service.name}"?',
                                      confirmText: 'Delete',
                                      cancelText: 'Cancel',
                                      isDestructive: true,
                                    );
                                    if (confirm != true) return;

                                    await ref
                                        .read(userManagementRepositoryProvider)
                                        .deleteService(service.id);

                                    ref.invalidate(umServicesProvider);
                                    ref.invalidate(
                                      umServiceDetailsProvider(service.id),
                                    );

                                    if (context.mounted) {
                                      context.pop();
                                    }
                                  },
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _FieldRow(label: 'ID', value: service.id),
                            _FieldRow(label: 'Name', value: service.name),
                            _FieldRow(
                              label: 'Name (lower)',
                              value: service.nameLower,
                            ),
                            _FieldRow(label: 'Code', value: service.code),
                            _FieldRow(
                                label: 'Department', value: departmentName),
                            _FieldRow(
                                label: 'Department ID',
                                value: service.departmentId),
                            _FieldRow(
                              label: 'Head User ID',
                              value: service.headUserId ?? '-',
                            ),
                            _FieldRow(
                              label: 'Status',
                              value: service.isActive ? 'Active' : 'Inactive',
                            ),
                            _FieldRow(
                              label: 'Created At',
                              value: _formatDateTime(service.createdAt),
                            ),
                            _FieldRow(
                              label: 'Updated At',
                              value: _formatDateTime(service.updatedAt),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                error: (error, _) => ErrorStateView(
                  title: 'Unable to load service',
                  description: error.toString(),
                  onRetry: () =>
                      ref.invalidate(umServiceDetailsProvider(serviceId)),
                ),
                loading: () => const LoadingStateView(
                  message: 'Loading service details...',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditServiceSheet extends ConsumerStatefulWidget {
  const _EditServiceSheet({required this.service});

  final UserManagementService service;

  @override
  ConsumerState<_EditServiceSheet> createState() => _EditServiceSheetState();
}

class _EditServiceSheetState extends ConsumerState<_EditServiceSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _headUserController;
  late String _departmentId;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service.name);
    _codeController = TextEditingController(text: widget.service.code);
    _headUserController =
        TextEditingController(text: widget.service.headUserId ?? '');
    _departmentId = widget.service.departmentId;
    _isActive = widget.service.isActive;
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
          if (departments.isNotEmpty &&
              departments.any((dep) => dep.id == _departmentId) == false) {
            _departmentId = departments.first.id;
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Service',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              CustomFormField(
                label: 'Name',
                hintText: 'Service name',
                textInputType: TextInputType.name,
                controller: _nameController,
              ),
              const SizedBox(height: 12),
              CustomFormField(
                label: 'Code',
                hintText: 'SRV_PROC',
                textInputType: TextInputType.text,
                controller: _codeController,
              ),
              const SizedBox(height: 12),
              Text(
                'Department',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: departments.isEmpty ? null : _departmentId,
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
                    _departmentId = value;
                  });
                },
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
    if (name.isEmpty || _departmentId.isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updated = UserManagementService(
      id: widget.service.id,
      code: _codeController.text.trim(),
      name: name,
      nameLower: name.toLowerCase(),
      departmentId: _departmentId,
      headUserId: _headUserController.text.trim().isEmpty
          ? null
          : _headUserController.text.trim(),
      isActive: _isActive,
      createdAt: widget.service.createdAt,
      updatedAt: DateTime.now(),
    );

    await ref.read(userManagementRepositoryProvider).updateService(updated);
    ref.invalidate(umServicesProvider);
    ref.invalidate(umServiceDetailsProvider(widget.service.id));

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
