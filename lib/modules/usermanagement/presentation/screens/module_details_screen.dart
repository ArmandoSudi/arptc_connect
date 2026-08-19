import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_module.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/entity_details_providers.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/utils/user_management_command_feedback.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/module_form_sheet.dart';
import 'package:arptc_connect/widgets/content_view.dart';
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
    final canManage =
        ref.watch(userManagementAccessPolicyProvider).canManageOrganization;

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
                                  if (canManage)
                                    IconButton(
                                      onPressed: () =>
                                          _editModule(context, ref, module),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                  if (canManage)
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

  Future<void> _editModule(
    BuildContext context,
    WidgetRef ref,
    UserManagementModule module,
  ) async {
    final l10n = S.of(context);
    final updated = await showModuleFormSheet(
      context,
      module: module,
      onSubmit: (value) =>
          ref.read(userManagementRepositoryProvider).updateModule(value),
      submissionErrorBuilder: (error) =>
          userManagementCommandErrorMessage(l10n, error),
      onSubmissionError: (error, stackTrace) =>
          reportUserManagementCommandError(
        context,
        operation: 'updateModule',
        error: error,
        stackTrace: stackTrace,
      ),
    );
    if (updated == null || !context.mounted) return;
    ref.invalidate(umModulesProvider);
    ref.invalidate(umModuleDetailsProvider(module.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.lookup('umModuleUpdated'))),
    );
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
