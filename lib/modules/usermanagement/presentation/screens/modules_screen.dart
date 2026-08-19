import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_module.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/utils/user_management_command_feedback.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/module_form_sheet.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/user_management_access_gate.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/user_management_section_scaffold.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ModulesManagementScreen extends ConsumerWidget {
  const ModulesManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesAsync = ref.watch(umModulesProvider);
    final theme = Theme.of(context);
    final l10n = S.of(context);

    return UserManagementAccessGate(
      requirePrivateProfiles: true,
      child: UserManagementSectionScaffold(
        selectedIndex: 3,
        title: l10n.lookup('umModules'),
        subtitle: l10n.lookup('umModulesDescription'),
        primaryAction: modulesAsync.maybeWhen(
          data: (modules) => FilledButton.icon(
            onPressed: () => _showAddModule(context, ref, modules),
            icon: const Icon(Icons.add),
            label: Text(l10n.lookup('umAddModule')),
          ),
          orElse: () => null,
        ),
        body: modulesAsync.when(
          data: (modules) {
            if (modules.isEmpty) {
              return EmptyStateView(
                icon: Icons.widgets_outlined,
                title: l10n.lookup('umNoModules'),
                description: l10n.lookup('umNoModulesDescription'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
              itemCount: modules.length,
              itemBuilder: (context, index) {
                final module = modules[index];
                final rolesLabel =
                    module.accessRoles.map((role) => role.label).join(', ');
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    leading: const CircleAvatar(
                      child: Icon(Icons.extension_outlined),
                    ),
                    title: Text(
                      module.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${module.key} · '
                      '${module.isActive ? l10n.lookup('umActive') : l10n.lookup('umInactive')} · '
                      '$rolesLabel',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(
                      '/service/usermanagement/modules/${module.id}',
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
            );
          },
          error: (error, _) => ErrorStateView(
            title: l10n.lookup('umUnableToLoadModules'),
            description: error.toString(),
            onRetry: () => ref.invalidate(umModulesProvider),
          ),
          loading: () => LoadingStateView(message: l10n.lookup('umLoading')),
        ),
      ),
    );
  }

  Future<void> _showAddModule(
    BuildContext context,
    WidgetRef ref,
    List<UserManagementModule> modules,
  ) async {
    final l10n = S.of(context);
    final created = await showModuleFormSheet(
      context,
      existingModules: modules,
      onSubmit: (module) =>
          ref.read(userManagementRepositoryProvider).addModule(module),
      submissionErrorBuilder: (error) =>
          userManagementCommandErrorMessage(l10n, error),
      onSubmissionError: (error, stackTrace) =>
          reportUserManagementCommandError(
        context,
        operation: 'addModule',
        error: error,
        stackTrace: stackTrace,
      ),
    );
    if (created == null || !context.mounted) return;
    ref.invalidate(umModulesProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.lookup('umModuleCreated'))),
    );
  }
}
