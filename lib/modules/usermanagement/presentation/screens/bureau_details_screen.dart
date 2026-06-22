import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_bureau.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/entity_details_providers.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/custom_filledbutton.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:arptc_connect/widgets/yes_or_no_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BureauDetailsScreen extends ConsumerWidget {
  const BureauDetailsScreen({
    required this.bureauId,
    super.key,
  });

  final String bureauId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bureauAsync = ref.watch(umBureauDetailsProvider(bureauId));
    final departmentsAsync = ref.watch(umDepartmentsProvider);
    final servicesAsync = ref.watch(umServicesProvider);

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
                  title: 'Bureau Details',
                  description: 'View and edit bureau fields',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: bureauAsync.when(
                data: (bureau) {
                  final departmentName = departmentsAsync.maybeWhen(
                    data: (departments) {
                      for (final department in departments) {
                        if (department.id == bureau.departmentId) {
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
                        if (service.id == bureau.serviceId) {
                          return service.name;
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
                                  bureau.name,
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
                                          _EditBureauSheet(bureau: bureau),
                                    );
                                  },
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final confirm =
                                        await showAdaptiveYesNoDialog(
                                      context,
                                      'Delete Bureau',
                                      'Are you sure you want to delete "${bureau.name}"?',
                                      confirmText: 'Delete',
                                      cancelText: 'Cancel',
                                      isDestructive: true,
                                    );
                                    if (confirm != true) return;

                                    await ref
                                        .read(userManagementRepositoryProvider)
                                        .deleteBureau(bureau.id);

                                    ref.invalidate(umBureauxProvider);
                                    ref.invalidate(
                                      umBureauDetailsProvider(bureau.id),
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
                            _FieldRow(label: 'ID', value: bureau.id),
                            _FieldRow(label: 'Name', value: bureau.name),
                            _FieldRow(
                              label: 'Name (lower)',
                              value: bureau.nameLower,
                            ),
                            _FieldRow(label: 'Code', value: bureau.code),
                            _FieldRow(
                                label: 'Department', value: departmentName),
                            _FieldRow(
                                label: 'Department ID',
                                value: bureau.departmentId),
                            _FieldRow(label: 'Service', value: serviceName),
                            _FieldRow(
                                label: 'Service ID', value: bureau.serviceId),
                            _FieldRow(
                              label: 'Head User ID',
                              value: bureau.headUserId ?? '-',
                            ),
                            _FieldRow(
                              label: 'Status',
                              value: bureau.isActive ? 'Active' : 'Inactive',
                            ),
                            _FieldRow(
                              label: 'Created At',
                              value: _formatDateTime(bureau.createdAt),
                            ),
                            _FieldRow(
                              label: 'Updated At',
                              value: _formatDateTime(bureau.updatedAt),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                error: (error, _) => ErrorStateView(
                  title: 'Unable to load bureau',
                  description: error.toString(),
                  onRetry: () =>
                      ref.invalidate(umBureauDetailsProvider(bureauId)),
                ),
                loading: () => const LoadingStateView(
                  message: 'Loading bureau details...',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditBureauSheet extends ConsumerStatefulWidget {
  const _EditBureauSheet({required this.bureau});

  final UserManagementBureau bureau;

  @override
  ConsumerState<_EditBureauSheet> createState() => _EditBureauSheetState();
}

class _EditBureauSheetState extends ConsumerState<_EditBureauSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _headUserController;
  late String _departmentId;
  String? _serviceId;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bureau.name);
    _codeController = TextEditingController(text: widget.bureau.code);
    _headUserController =
        TextEditingController(text: widget.bureau.headUserId ?? '');
    _departmentId = widget.bureau.departmentId;
    _serviceId = widget.bureau.serviceId;
    _isActive = widget.bureau.isActive;
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
          if (departments.isNotEmpty &&
              departments.any((dep) => dep.id == _departmentId) == false) {
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

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Bureau',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  CommonTextInput(
                    label: 'Name',
                    hintText: 'Bureau name',
                    type: CommonTextInputType.name,
                    controller: _nameController,
                  ),
                  const SizedBox(height: 12),
                  CommonTextInput(
                    label: 'Code',
                    hintText: 'BUR_LOCAL',
                    type: CommonTextInputType.text,
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
                        _serviceId = null;
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
                    value: filteredServices.isEmpty ? null : _serviceId,
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
                              _serviceId = value;
                            });
                          },
                    hint: const Text('Select service'),
                  ),
                  const SizedBox(height: 12),
                  CommonTextInput(
                    label: 'Head user ID',
                    hintText: 'uid_123',
                    type: CommonTextInputType.text,
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
    final serviceId = _serviceId ?? '';
    if (name.isEmpty || _departmentId.isEmpty || serviceId.isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updated = UserManagementBureau(
      id: widget.bureau.id,
      code: _codeController.text.trim(),
      name: name,
      nameLower: name.toLowerCase(),
      departmentId: _departmentId,
      serviceId: serviceId,
      headUserId: _headUserController.text.trim().isEmpty
          ? null
          : _headUserController.text.trim(),
      isActive: _isActive,
      createdAt: widget.bureau.createdAt,
      updatedAt: DateTime.now(),
    );

    await ref.read(userManagementRepositoryProvider).updateBureau(updated);
    ref.invalidate(umBureauxProvider);
    ref.invalidate(umBureauDetailsProvider(widget.bureau.id));

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
