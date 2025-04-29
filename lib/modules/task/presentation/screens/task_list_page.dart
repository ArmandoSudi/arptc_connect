import 'package:arptc_connect/modules/task/presentation/screens/task_filter_widget.dart';
import 'package:arptc_connect/modules/task/presentation/screens/task_form_page.dart';
import 'package:flutter/material.dart';

import 'task_card.dart';

class TaskListPage extends StatelessWidget {
  const TaskListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: const Column(
                children: [
                  TaskFilterWidget(),
                  Expanded(child: TaskListView()),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: const Placeholder(fallbackHeight: 200),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const TaskFormPage(),
          ));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TaskListView extends StatelessWidget {
  const TaskListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return TaskCard(
          label: 'Task #$index',
          status: index % 2 == 0 ? 'doing' : 'done',
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => const TaskDetailPage(),
          )),
        );
      },
    );
  }
}

class TaskDetailPage extends StatelessWidget {
  const TaskDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Label: ..."),
            Text("Observation: ..."),
            Text("Status: ..."),
            Text("Type: ..."),
            Text("Sender: ..."),
            Text("Receiver: ..."),
            Text("Files: ..."),
          ],
        ),
      ),
    );
  }
}