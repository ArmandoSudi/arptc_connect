import 'dart:developer';

import 'package:arptc_connect/extensions/date_extension.dart';
import 'package:arptc_connect/modules/task/domain/task.dart';
import 'package:arptc_connect/modules/task/presentation/controllers/async_tasks.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/custom_filledbutton.dart';
import 'package:arptc_connect/widgets/custom_form_field.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now(),
  );

  DateTime? _selectedDate;

  List<Task> _tasks = [];

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
              ],
            ),

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
                      return ListTile(
                        leading: Icon(
                          Icons.circle,
                          color: data[index].isDone
                              ? Colors.grey
                              : Colors.lightGreen,
                        ),
                        title: Text(
                          data[index].title,
                          style: theme.textTheme.bodyMedium!
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          data[index].observation,
                          style: theme.textTheme.labelMedium,
                        ),
                        trailing: Text(data[index].creationDate.formatedDate),
                        onTap: () {
                          // context.go("/service/ticketing/${data[index].id}");
                        },
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return const Divider();
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
        onPressed: () => showCreateTaskDialog(context),
      ),
    );
  }


  // void _showBottomModal(BuildContext context) {
  //   final _formKey = GlobalKey<FormState>();
  //   String _title = '';
  //   String _observation = '';
  //
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return Padding(
  //         padding: const EdgeInsets.all(16.0),
  //         child: Form(
  //           key: _formKey,
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: <Widget>[
  //               TextFormField(
  //                 decoration: const InputDecoration(labelText: 'Title'),
  //                 onSaved: (value) {
  //                   _title = value ?? '';
  //                 },
  //                 validator: (value) {
  //                   if (value == null || value.isEmpty) {
  //                     return 'Please enter a title';
  //                   }
  //                   return null;
  //                 },
  //               ),
  //               TextFormField(
  //                 decoration: const InputDecoration(labelText: 'Observation'),
  //                 onSaved: (value) {
  //                   _observation = value ?? '';
  //                 },
  //                 validator: (value) {
  //                   if (value == null || value.isEmpty) {
  //                     return 'Please enter an observation';
  //                   }
  //                   return null;
  //                 },
  //               ),
  //               const SizedBox(height: 16.0),
  //               ElevatedButton(
  //                 onPressed: () {
  //                   if (_formKey.currentState!.validate()) {
  //                     _formKey.currentState!.save();
  //                     // Handle the form submission
  //                     // For example, you can create a new Task object and add it to the list
  //                     Navigator.pop(context);
  //                   }
  //                 },
  //                 child: const Text('Create Task'),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  void showCreateTaskDialog(BuildContext context) {
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _observationController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: SizedBox(
            width: 700,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // TITLE
                  CustomFormField(
                    label: "Nom",
                    hintText: "Nom de la tâche",
                    textInputType: TextInputType.text,
                    controller: _titleController,
                  ),
                  const Gap(12),

                  // OBSERVATION
                  CustomFormField(
                    label: "Observation",
                    hintText: "Observation de la tâche",
                    textInputType: TextInputType.text,
                    controller: _observationController,
                  ),
                  const Gap(32),

                  // BUTTON TO SAVE OR CANCEL
                  Row(
                    children: [
                      Expanded(
                        child: CustomFilledButton(
                          onPressed: () {

                            final task = Task(
                              title: _titleController.text,
                              observation: _observationController.text,
                              isDone: false,
                              creationDate: DateTime.now(),
                            );

                            ref
                                .read(asyncTasksProvider.notifier)
                                .addTask(task);

                            Navigator.of(context).pop();
                          },
                          text: "Enregistrer",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                                minimumSize: const Size.fromHeight(50)),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              "Annuler",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          title: const Text('Enregistrer une nouvelle tâche'),
        );
      },
    );
  }
}
