import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/task/domain/task_access.dart';
import 'package:arptc_connect/modules/task/presentation/controllers/task_providers.dart';
import 'package:arptc_connect/modules/task/presentation/widgets/task_details_view.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskDetailsPage extends ConsumerWidget {
  const TaskDetailsPage(this.taskId, {super.key});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final principalAsync = ref.watch(currentTaskPrincipalProvider);
    final taskAsync = ref.watch(taskDetailsProvider(taskId));

    return Scaffold(
      body: SafeArea(
        child: principalAsync.when(
          loading: () => LoadingStateView(message: l10n.loading),
          error: (error, _) => ErrorStateView(
            title: l10n.taskLoadFailed,
            description: error.toString(),
          ),
          data: (principal) {
            if (!principal.role.canRead) {
              return ErrorStateView(title: l10n.taskAccessDenied);
            }
            return taskAsync.when(
              loading: () => LoadingStateView(message: l10n.loadingTasks),
              error: (error, _) => ErrorStateView(
                title: l10n.taskLoadFailed,
                description: error.toString(),
                onRetry: () => ref.invalidate(taskDetailsProvider(taskId)),
              ),
              data: (task) {
                if (task == null) {
                  return EmptyStateView(
                    icon: Icons.search_off,
                    title: l10n.taskNotFound,
                  );
                }
                if (!TaskAccessPolicy.canViewTask(principal, task)) {
                  return ErrorStateView(title: l10n.taskAccessDenied);
                }
                return TaskDetailsView(task: task, principal: principal);
              },
            );
          },
        ),
      ),
    );
  }
}
