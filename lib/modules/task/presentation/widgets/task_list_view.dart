import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/task/domain/task.dart';
import 'package:arptc_connect/modules/task/domain/task_access.dart';
import 'package:arptc_connect/modules/task/presentation/controllers/task_providers.dart';
import 'package:arptc_connect/modules/task/presentation/task_presentation_helpers.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:arptc_connect/widgets/page_header_simple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TaskListView extends ConsumerWidget {
  const TaskListView({
    super.key,
    required this.principal,
  });

  final TaskPrincipal principal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final tasksAsync = ref.watch(filteredDepartmentTasksProvider);
    final scopeDescription = principal.role.canViewAllDepartments
        ? l10n.allDepartmentTasks
        : l10n.departmentTasks(
            principal.departmentName.trim().isNotEmpty
                ? principal.departmentName
                : principal.departmentId,
          );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return PageHeaderSimple(
                          title: l10n.tasks,
                          actions: principal.role.canCreate &&
                                  constraints.maxWidth >= 650
                              ? [
                                  FilledButton.icon(
                                    onPressed: () =>
                                        context.push('/service/tasks/new'),
                                    icon: const Icon(Icons.add),
                                    label: Text(l10n.newTask),
                                  ),
                                ]
                              : null,
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 52, top: 4),
                      child: Text(
                        scopeDescription,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _TaskFilterBar(),
                  ],
                ),
              ),
            ),
          ),
        ),
        tasksAsync.when(
          loading: () => SliverFillRemaining(
            hasScrollBody: false,
            child: LoadingStateView(message: l10n.loadingTasks),
          ),
          error: (error, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorStateView(
              title: l10n.taskLoadFailed,
              description: error.toString(),
              onRetry: () => ref.invalidate(departmentTasksProvider),
            ),
          ),
          data: (tasks) {
            if (tasks.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView(
                  icon: Icons.task_alt_outlined,
                  title: l10n.noTasks,
                  description: l10n.noTasksDescription,
                  actionLabel: principal.role.canCreate ? l10n.newTask : null,
                  onAction: principal.role.canCreate
                      ? () => context.push('/service/tasks/new')
                      : null,
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= 900) {
                          return _TaskTable(tasks: tasks);
                        }
                        return Column(
                          children: tasks
                              .map((task) => _TaskCard(task: task))
                              .toList(),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TaskFilterBar extends ConsumerWidget {
  const _TaskFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final filters = ref.watch(taskFiltersProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final status = _FilterDropdown<TaskStatus>(
              label: l10n.status,
              value: filters.status,
              allLabel: l10n.allStatuses,
              items: TaskStatus.values,
              labelBuilder: (value) => taskStatusLabel(l10n, value),
              onChanged: (value) {
                ref.read(taskFiltersProvider.notifier).state = filters.copyWith(
                  status: value,
                  clearStatus: value == null,
                );
              },
            );
            final type = _FilterDropdown<TaskType>(
              label: l10n.type,
              value: filters.type,
              allLabel: l10n.allTypes,
              items: TaskType.values,
              labelBuilder: (value) => taskTypeLabel(l10n, value),
              onChanged: (value) {
                ref.read(taskFiltersProvider.notifier).state = filters.copyWith(
                  type: value,
                  clearType: value == null,
                );
              },
            );

            if (constraints.maxWidth < 620) {
              return Column(
                children: [
                  status,
                  const SizedBox(height: 14),
                  type,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: status),
                const SizedBox(width: 16),
                Expanded(child: type),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.allLabel,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final String allLabel;
  final List<T> items;
  final String Function(T value) labelBuilder;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T?>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        DropdownMenuItem<T?>(
          value: null,
          child: Text(allLabel),
        ),
        ...items.map(
          (item) => DropdownMenuItem<T?>(
            value: item,
            child: Text(labelBuilder(item)),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _TaskTable extends StatelessWidget {
  const _TaskTable({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          columns: [
            DataColumn(label: Text(l10n.activityObject)),
            DataColumn(label: Text(l10n.type)),
            DataColumn(label: Text(l10n.status)),
            DataColumn(label: Text(l10n.department)),
            DataColumn(label: Text(l10n.createdAt)),
            DataColumn(label: Text(l10n.createdBy)),
          ],
          rows: tasks.map((task) {
            return DataRow(
              onSelectChanged: (_) => context.push('/service/tasks/${task.id}'),
              cells: [
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      task.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(taskTypeLabel(l10n, task.type))),
                DataCell(_TaskStatusBadge(status: task.status)),
                DataCell(Text(
                  task.departmentName.trim().isNotEmpty
                      ? task.departmentName
                      : task.departmentId,
                )),
                DataCell(Text(formatTaskDate(context, task.creationDate))),
                DataCell(Text(
                  task.createdByName.trim().isEmpty
                      ? l10n.notAvailable
                      : task.createdByName,
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/service/tasks/${task.id}'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      task.type == TaskType.mail
                          ? Icons.mail_outline
                          : Icons.task_alt_outlined,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          taskTypeLabel(l10n, task.type),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _TaskStatusBadge(status: task.status),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 18,
                runSpacing: 8,
                children: [
                  _CardMetadata(
                    icon: Icons.account_tree_outlined,
                    value: task.departmentName.trim().isNotEmpty
                        ? task.departmentName
                        : task.departmentId,
                  ),
                  _CardMetadata(
                    icon: Icons.schedule,
                    value: formatTaskDate(context, task.creationDate),
                  ),
                  if (task.createdByName.trim().isNotEmpty)
                    _CardMetadata(
                      icon: Icons.person_outline,
                      value: task.createdByName,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardMetadata extends StatelessWidget {
  const _CardMetadata({
    required this.icon,
    required this.value,
  });

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 17,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _TaskStatusBadge extends StatelessWidget {
  const _TaskStatusBadge({required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final colors = _statusColors(Theme.of(context).colorScheme, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        taskStatusLabel(l10n, status),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.$2,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

(Color, Color) _statusColors(ColorScheme scheme, TaskStatus status) {
  switch (status) {
    case TaskStatus.newTask:
      return (scheme.primaryContainer, scheme.onPrimaryContainer);
    case TaskStatus.doing:
      return (scheme.tertiaryContainer, scheme.onTertiaryContainer);
    case TaskStatus.done:
      return (scheme.secondaryContainer, scheme.onSecondaryContainer);
    case TaskStatus.archived:
      return (scheme.surfaceContainerHighest, scheme.onSurfaceVariant);
  }
}
