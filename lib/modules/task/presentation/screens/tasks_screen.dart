import 'dart:developer';

import 'package:arptc_connect/extensions/date_extension.dart';
import 'package:arptc_connect/modules/task/application/activite_reporting_excel_service.dart';
import 'package:arptc_connect/modules/task/application/activite_reporting_service.dart';
import 'package:arptc_connect/modules/task/domain/task.dart';
import 'package:arptc_connect/modules/task/presentation/controllers/async_tasks.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/custom_filledbutton.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:arptc_connect/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

enum TaskState {
  New,
  Doing,
  Done,
}

final taskFilter = StateProvider<TaskState>((ref) {
  return TaskState.New;
});

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final List<Task> _tasks = [];
  TaskState selectedFilterOption = TaskState.New;

  @override
  Widget build(BuildContext context) {
    final asyncTasks = ref.watch(asyncTasksProvider);

    final theme = Theme.of(context);

    return Scaffold(
      body: ContentView(
        child: Column(
          children: [
            // TITLE
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    context.pop();
                  },
                ),
                const PageHeader(
                    title: "Tâches",
                    description: 'Gestion des tickets d\'intervention'),
                Expanded(
                  child: Container(),
                ),
                IconButton(
                  onPressed: () {
                    // final ActiviteReportingService ARS = ActiviteReportingService();
                    final excelReport = ActiviteExcelReportingService();

                    // ARS.generateReport(_tasks);
                    excelReport.generateExcelReport(_tasks, "reports.xlsx");
                  },
                  icon: const Icon(Icons.print),
                ),
              ],
            ),
            const Gap(20),

            // SEGMENTED BUTTONS - Outside of scrollable area
            ResponsiveCenter(
              child: SegmentedButton<TaskState>(
                segments: const <ButtonSegment<TaskState>>[
                  ButtonSegment<TaskState>(
                    value: TaskState.New,
                    label: Text('Nouvelle'),
                  ),
                  ButtonSegment<TaskState>(
                      value: TaskState.Doing, label: Text('En Traitement')),
                  ButtonSegment<TaskState>(
                    value: TaskState.Done,
                    label: Text('Traitée'),
                  )
                ],
                selected: {selectedFilterOption},
                onSelectionChanged: (Set<TaskState> newSelection) {
                  setState(() {
                    log("Selected $newSelection");
                    ref.read(taskFilter.notifier).state = newSelection.first;
                    selectedFilterOption = newSelection.first;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: asyncTasks.when(
                data: (data) {
                  _tasks.clear();

                  data.sort((a, b) => a.creationDate.compareTo(b.creationDate));

                  _tasks.addAll(data);

                  return SingleChildScrollView(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: data.length,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        log("Task ID ${data[index].id} ");

                        // add Inkwell
                        return InkWell(
                          onTap: () {
                            context.push("/service/tasks/${data[index].id}");
                          },
                          child: Card(
                            elevation: 0,
                            color: theme.colorScheme.surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data[index].label,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        "De : ",
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        data[index].sender!,
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // DATE LABELS
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Date d'émission",
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        "Date d'accusé réception",
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        data[index].emissionDate.formatedDate,
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        data[index]
                                                .receptionDate
                                                ?.formatedDate ??
                                            " - ",
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          onLongPress: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Supprimer la tâche'),
                                  content: Text(
                                      'Voulez-vous vraiment supprimer "${data[index].label}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('Non'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        ref
                                            .read(asyncTasksProvider.notifier)
                                            .deleteTask(data[index].id);
                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('Tâche supprimée'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            theme.colorScheme.error,
                                      ),
                                      child: const Text('Oui'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return const SizedBox.shrink();
                      },
                    ),
                  );
                },
                error: (error, stackTrace) {
                  log("Error loading tickets:: $error");
                  log("$stackTrace");
                  return const Text("An error occurer when loading the items");
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          // showCreateTaskDialog(context);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => const TaskBottomSheet(),
          );
        },
      ),
    );
  }
}

class TaskBottomSheet extends ConsumerStatefulWidget {
  const TaskBottomSheet({super.key});

  @override
  ConsumerState<TaskBottomSheet> createState() => _TaskBottomSheetState();
}

class _TaskBottomSheetState extends ConsumerState<TaskBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _observationController = TextEditingController();
  final TextEditingController _emissionDateController = TextEditingController();
  final TextEditingController _receptionDateController =
      TextEditingController();
  final TextEditingController _senderController = TextEditingController();
  final TextEditingController _receiverController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _type = 'task';
  DateTime? _receptionDate, _emissionDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Créer une activité',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // TYPE OF THE TASK
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonFormField<String>(
                  // underline: const SizedBox.shrink(),
                  decoration: const InputDecoration(
                      labelText: 'Type', border: InputBorder.none),
                  value: _type,
                  items: const [
                    DropdownMenuItem(
                        value: 'task',
                        child: Text('Projets / Autre Traitement')),
                    DropdownMenuItem(
                        value: 'mail', child: Text('Courrier / NSI')),
                  ],
                  onChanged: (val) => setState(() => _type = val ?? 'task'),
                ),
              ),
              const SizedBox(height: 10),

              // DATE D'EMISSION ET DATE D'ACCUSE RECEPTION
              Row(
                children: [
                  Expanded(
                    child: CommonTextInput(
                      label: "Date d'émission",
                      hintText: "Date d'émission",
                      type: CommonTextInputType.dateTime,
                      controller: _emissionDateController,
                      onTap: () => showDatePicker(
                        context: context,
                        initialDate: _emissionDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      ).then((date) {
                        if (date != null) {
                          setState(() {
                            _emissionDate = date;
                            _emissionDateController.text = date.formatedDate;
                          });
                        }
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CommonTextInput(
                      label: "Date d'accusé de réception",
                      hintText: "Date d'accusé de réception",
                      type: CommonTextInputType.dateTime,
                      controller: _receptionDateController,
                      enabled: _type == 'mail',
                      onTap: _type == 'mail'
                          ? () => showDatePicker(
                                context: context,
                                initialDate: _receptionDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              ).then((date) {
                                if (date != null) {
                                  setState(() {
                                    _receptionDate = date;
                                    _receptionDateController.text =
                                        date.formatedDate;
                                  });
                                }
                              })
                          : null,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),

              // DATE D'EMISSION ET DATE D'ACCUSE RECEPTION
              if (_type == 'mail') ...[
                Row(
                  children: [
                    Expanded(
                      child: // NAME OF THE SENDER
                          CommonTextInput(
                        label: "Emetteur",
                        hintText: "Entrer l'émetteur du courrier",
                        type: CommonTextInputType.text,
                        controller: _senderController,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CommonTextInput(
                        label: "Destinataire",
                        hintText: "Entrer le destinataire",
                        type: CommonTextInputType.text,
                        controller: _receiverController,
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 10),
              ] else ...[
                // NOM DU RESPONSABLE
                CommonTextInput(
                  label: "Responsable / Initiateur",
                  hintText: "Entrer le responable du projet",
                  type: CommonTextInputType.text,
                  controller: _senderController,
                ),
                const SizedBox(height: 10),
              ],

              // OBJET DE L'ACTIVITE
              CommonTextInput(
                label: "Objet",
                hintText: "Entrez l'objet de l'activité",
                type: CommonTextInputType.text,
                controller: _titleController,
              ),
              const SizedBox(height: 10),

              // DESCRIPTION OF THE TASK
              CommonTextInput(
                label: "Remarques",
                hintText: "Entrer la remarque du projet/courrier",
                type: CommonTextInputType.text,
                controller: _observationController,
              ),
              const SizedBox(height: 10),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: Colors.grey),
                      foregroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    onPressed: () {
                      context.pop();
                    },
                    child: const Text(
                      "Annuler",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomFilledButton(
                      text: "Enregistrer",
                      onPressed: () {
                        final task = Task(
                          id: "",
                          label: _titleController.text,
                          observation: _observationController.text,
                          creationDate: DateTime.now(),
                          emissionDate: _emissionDate ?? DateTime.now(),
                          receptionDate: _receptionDate,
                          status: "new",
                          type: _type,
                          sender: _senderController.text,
                          receiver: _receiverController.text,
                          mailScanUrl: "",
                          reportFileUrl: "",
                          department: "IT",
                        );

                        ref.read(asyncTasksProvider.notifier).addTask(task);

                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
