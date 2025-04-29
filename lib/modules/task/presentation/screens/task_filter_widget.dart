import 'package:flutter/material.dart';

class TaskFilterWidget extends StatelessWidget {
  const TaskFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: 'doing', child: Text('Doing')),
              DropdownMenuItem(value: 'done', child: Text('Done')),
              DropdownMenuItem(value: 'archived', child: Text('Archived')),
            ],
            onChanged: (value) {},
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Type'),
            items: const [
              DropdownMenuItem(value: 'task', child: Text('Task')),
              DropdownMenuItem(value: 'mail', child: Text('Mail')),
            ],
            onChanged: (value) {},
          ),
        ),
      ],
    );
  }
}
