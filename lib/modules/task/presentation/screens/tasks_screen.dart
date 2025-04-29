import 'dart:developer';

import 'package:arptc_connect/extensions/date_extension.dart';
import 'package:arptc_connect/modules/task/domain/task_two.dart';
import 'package:arptc_connect/modules/task/presentation/controllers/async_tasks.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/custom_filledbutton.dart';
import 'package:arptc_connect/widgets/custom_form_field.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum TaskState {
  New,
  Doing,
  Done,
}

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

    asyncTasks.when(
        data: (data) {
          log("Tasks data: $data");
        },
        loading: () {},
        error: (error, stackTrace) {
          log("Error loading tasks:: $error");
        }
    );

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
                    title: "Tasks",
                    description: 'Gestion des tickets d\'intervention'),
                Expanded(
                  child: Container(),
                ),
                TextButton(
                  onPressed: () {
                    context.go("/service/tasks/task}");
                  },
                  child: const Text(
                    "Voir les tickets",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            // SEGEMENTED BUTTONS BASED ON THE TASK STATE
            SegmentedButton<TaskState>(
              segments: const <ButtonSegment<TaskState>>[
                ButtonSegment<TaskState>(
                  value: TaskState.New,
                  label: Text('Nouvelle'),
                ),
                ButtonSegment<TaskState>(
                    value: TaskState.Doing,
                    label: Text('En Traitement')),
                ButtonSegment<TaskState>(
                  value: TaskState.Done,
                  label: Text('Traitée'),
                )
              ],
              selected: {selectedFilterOption},
              onSelectionChanged: (Set<TaskState> newSelection) {
                setState(() {
                  log("Selected $newSelection");

                  switch (newSelection.first) {
                    case TaskState.New:
                      selectedFilterOption = TaskState.New;
                      break;
                    case TaskState.Doing:
                      selectedFilterOption = TaskState.Doing;
                      break;
                    case TaskState.Done:
                      selectedFilterOption = TaskState.Done;
                      break;
                  }
                });
              },
            ),
            const SizedBox(height: 20),

            // LIST OF TICKETS
            asyncTasks.when(
              data: (data) {

                // _tickets = data;
                _tasks.clear();

                // Order list in data by ticket creation date
                data.sort((a, b) => a.creationDate.compareTo(b.creationDate));

                _tasks.addAll(data);

                return Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: data.length,
                    itemBuilder: (context, index) {

                      log("Task ID ${data[index].id} ");

                      // add Inkwell
                      return InkWell(
                        onTap: (){
                          context.push("/service/tasks/${data[index].id}");
                        },
                        child: Card(
                          child: ClipRect(
                            // borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data[index].label,
                                    style: theme.textTheme.titleMedium!
                                        .copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text("De : ",  style: theme.textTheme.labelMedium,),
                                      const SizedBox(width: 2),
                                      Text(
                                        data[index].sender!,
                                        style: theme.textTheme.labelLarge,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // DATE LABEL
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Date d'émission",
                                        style: theme.textTheme.labelMedium,
                                      ),Text(
                                        "Date d'accusé réception",
                                        style: theme.textTheme.labelMedium,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        data[index].emissionDate.formatedDate,
                                        style: theme.textTheme.labelLarge,
                                      ),Text(
                                        data[index].receptionDate?.formatedDate ?? " - ",
                                        style: theme.textTheme.labelLarge,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                        ),
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
        } ,
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
  final TextEditingController _receptionDateController = TextEditingController();
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
              const Text('Créer une activité', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height:20),

              // TYPE OF THE TASK
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonFormField<String>(
                  // underline: const SizedBox.shrink(),
                  decoration: const InputDecoration(labelText: 'Type', border: InputBorder.none),
                  value: _type,
                  items: const [
                    DropdownMenuItem(value: 'task', child: Text('Projets / Autre Traitement')),
                    DropdownMenuItem(value: 'mail', child: Text('Courrier / NSI')),
                  ],
                  onChanged: (val) => setState(() => _type = val ?? 'task'),
                ),
              ),
              const SizedBox(height: 10),

              // DATE D'EMISSION ET DATE D'ACCUSE RECEPTION
              Row(
                children: [
                  Expanded(
                    child: CustomFormField(
                      label: "Date d'émission",
                      hintText: "Date d'émission",
                      textInputType: TextInputType.datetime,
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
                      }
                    ),
                  ),),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomFormField(
                      label: "Date d'accusé de réception",
                      hintText: "Date d'accusé de réception",
                      textInputType: TextInputType.datetime,
                      controller: _receptionDateController,
                      enable: _type == 'mail',
                      onTap: _type == 'mail' ? () => showDatePicker(
                        context: context,
                        initialDate: _receptionDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      ).then((date) {
                        if (date != null) {
                          setState(() {
                            _receptionDate = date;
                            _receptionDateController.text = date.formatedDate;
                          });
                        }
                      }
                    ) : null,
                  ),)
                ],
              ),
              const SizedBox(height: 10),

              // DATE D'EMISSION ET DATE D'ACCUSE RECEPTION
              if (_type == 'mail') ... [
                Row(
                children: [
                  Expanded(
                    child: // NAME OF THE SENDER
                    CustomFormField(
                      label: "Emetteur",
                      hintText: "Entrer l'émetteur du courrier",
                      textInputType: TextInputType.text,
                      controller: _senderController,
                    ),),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomFormField(
                      label: "Destinataire",
                      hintText: "Entrer le destinataire",
                      textInputType: TextInputType.text,
                      controller: _receiverController,
                    ),)
                ],
              ),
                const SizedBox(height: 10),
              ]
              else ... [
                // NOM DU RESPONSABLE
                CustomFormField(
                  label: "Responsable / Initiateur",
                  hintText: "Entrer le responable du projet",
                  textInputType: TextInputType.text,
                  controller: _senderController,
                ),
                const SizedBox(height: 10),
              ],

              // OBJET DE L'ACTIVITE
              CustomFormField(
                label: "Objet",
                hintText: "Entrez l'objet de l'activité",
                textInputType: TextInputType.text,
                controller: _titleController,
              ),
              const SizedBox(height: 10),

              // DESCRIPTION OF THE TASK
              CustomFormField(
                label: "Remarques",
                hintText: "Entrer la remarque du projet/courrier",
                textInputType: TextInputType.text,
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
                      onPressed: ()  {
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

                          ref
                              .read(asyncTasksProvider.notifier)
                              .addTask(task);

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

