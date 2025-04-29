import 'package:flutter/material.dart';

class TaskFormPage extends StatefulWidget {
  const TaskFormPage({super.key});

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'task';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Task')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(decoration: const InputDecoration(labelText: 'Label')),
              TextFormField(decoration: const InputDecoration(labelText: 'Observation')),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Type'),
                value: _type,
                items: const [
                  DropdownMenuItem(value: 'task', child: Text('Task')),
                  DropdownMenuItem(value: 'mail', child: Text('Mail')),
                ],
                onChanged: (val) => setState(() => _type = val ?? 'task'),
              ),
              if (_type == 'mail') ...[
                TextFormField(decoration: const InputDecoration(labelText: 'Sender')),
                TextFormField(decoration: const InputDecoration(labelText: 'Receiver')),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Mail Scan'),
                ),
              ],
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Report'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: () {}, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}