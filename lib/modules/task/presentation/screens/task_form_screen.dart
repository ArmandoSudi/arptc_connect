import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/task/domain/task_access.dart';
import 'package:arptc_connect/modules/task/presentation/controllers/task_providers.dart';
import 'package:arptc_connect/modules/task/presentation/widgets/task_editor.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskFormScreen extends ConsumerWidget {
  const TaskFormScreen({
    super.key,
    this.taskId,
  });

  final String? taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final principalAsync = ref.watch(currentTaskPrincipalProvider);
    return principalAsync.when(
      loading: () => const Scaffold(body: LoadingStateView()),
      error: (error, _) => Scaffold(
        body: ErrorStateView(
          title: S.of(context).taskLoadFailed,
          description: error.toString(),
        ),
      ),
      data: (principal) {
        final isEditing = taskId != null;
        if ((!isEditing && !principal.role.canCreate) ||
            (isEditing && !principal.role.canEdit)) {
          return Scaffold(
            body: ErrorStateView(title: S.of(context).taskAccessDenied),
          );
        }

        if (!isEditing) {
          return TaskEditor(principal: principal);
        }

        return ref.watch(taskDetailsProvider(taskId!)).when(
              loading: () => const Scaffold(body: LoadingStateView()),
              error: (error, _) => Scaffold(
                body: ErrorStateView(
                  title: S.of(context).taskLoadFailed,
                  description: error.toString(),
                ),
              ),
              data: (task) {
                if (task == null) {
                  return Scaffold(
                    body: ErrorStateView(title: S.of(context).taskNotFound),
                  );
                }
                if (!TaskAccessPolicy.canMutateTask(principal, task)) {
                  return Scaffold(
                    body: ErrorStateView(
                      title: S.of(context).taskAccessDenied,
                    ),
                  );
                }
                return TaskEditor(
                  key: ValueKey(task.id),
                  principal: principal,
                  initialTask: task,
                );
              },
            );
      },
    );
  }
}
