import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/authentication/providers/authorized_session_provider.dart';
import 'package:arptc_connect/modules/task/domain/task_access.dart';
import 'package:arptc_connect/modules/task/presentation/controllers/task_providers.dart';
import 'package:arptc_connect/modules/task/presentation/widgets/task_list_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final principalAsync = ref.watch(currentTaskPrincipalProvider);

    return Scaffold(
      body: SafeArea(
        child: principalAsync.when(
          loading: () => LoadingStateView(message: l10n.loading),
          error: (error, _) => ErrorStateView(
            title: l10n.taskLoadFailed,
            description: error.toString(),
            onRetry: () => ref.invalidate(authorizedSessionProvider),
          ),
          data: (principal) {
            if (!principal.role.canRead) {
              return ErrorStateView(title: l10n.taskAccessDenied);
            }
            if (!principal.role.canViewAllDepartments &&
                !principal.hasDepartment) {
              return ErrorStateView(
                title: l10n.departmentRequired,
                description: l10n.taskDepartmentMissingDescription,
              );
            }
            return TaskListView(principal: principal);
          },
        ),
      ),
      floatingActionButton:
          principalAsync.valueOrNull?.role.canCreate == true &&
                  MediaQuery.sizeOf(context).width < 650
              ? FloatingActionButton.extended(
                  onPressed: () => context.push('/service/tasks/new'),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.newTask),
                )
              : null,
    );
  }
}
