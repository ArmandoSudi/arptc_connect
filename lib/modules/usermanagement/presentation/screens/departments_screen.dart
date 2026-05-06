import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_department.dart';
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

class DepartmentsScreen extends ConsumerWidget {
  const DepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  title: 'Departments',
                  description: 'List of organizational departments',
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
                      builder: (_) => const _AddDepartmentSheet(),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Department'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: departmentsAsync.when(
                data: (departments) {
                  if (departments.isEmpty) {
                    return const EmptyStateView(
                      icon: Icons.account_tree_outlined,
                      title: 'No department found',
                      description: 'Start by adding your first department.',
                    );
                  }

                  return ListView.separated(
                    itemCount: departments.length,
                    itemBuilder: (context, index) {
                      final department = departments[index];
                      return ListTile(
                        leading: const Icon(Icons.apartment_outlined),
                        title: Text(
                          department.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: department.code.isEmpty
                            ? null
                            : Text(
                                department.code,
                                style: theme.textTheme.bodySmall,
                              ),
                        onTap: () => context.push(
                          '/service/usermanagement/departments/${department.id}',
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 1),
                  );
                },
                error: (error, _) => ErrorStateView(
                  title: 'Unable to load departments',
                  description: error.toString(),
                  onRetry: () => ref.invalidate(umDepartmentsProvider),
                ),
                loading: () =>
                    const LoadingStateView(message: 'Loading departments...'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddDepartmentSheet extends ConsumerStatefulWidget {
  const _AddDepartmentSheet();

  @override
  ConsumerState<_AddDepartmentSheet> createState() =>
      _AddDepartmentSheetState();
}

class _AddDepartmentSheetState extends ConsumerState<_AddDepartmentSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
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
            'Add Department',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          CustomFormField(
            label: 'Department name',
            hintText: 'Enter department name',
            textInputType: TextInputType.name,
            controller: _nameController,
          ),
          const SizedBox(height: 12),
          CustomFormField(
            label: 'Code (optional)',
            hintText: 'DEP_FIN',
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

    await ref.read(userManagementRepositoryProvider).addDepartment(
          UserManagementDepartment(
            id: '',
            code: _codeController.text.trim(),
            name: name,
            nameLower: name.toLowerCase(),
            headUserId: null,
            isActive: true,
          ),
        );

    ref.invalidate(umDepartmentsProvider);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
