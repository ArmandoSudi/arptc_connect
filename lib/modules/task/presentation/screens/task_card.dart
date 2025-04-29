import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  final String label;
  final String status;
  final VoidCallback onTap;
  const TaskCard({super.key, required this.label, required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(label),
        subtitle: Text('Status: $status'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}