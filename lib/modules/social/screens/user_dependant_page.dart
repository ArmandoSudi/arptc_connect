import 'package:arptc_connect/modules/administration/domain/models/dependant.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// User Dependant Page
///
/// Displays list of dependants with M3 styling
class UserDependantPage extends StatelessWidget {
  UserDependantPage({super.key});

  final db = FirebaseFirestore.instance;

  final CollectionReference agentsRef = FirebaseFirestore.instance
      .collection('agents/PyKV8iGiDzcTdQSaRzWD/dependants');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: agentsRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const ErrorStateView(
                title: "Something went wrong",
                description: "Unable to load dependants",
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingStateView(message: "Loading dependants...");
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const EmptyStateView(
                icon: Icons.people_outline,
                title: "No dependants yet",
                description: "Add your dependants to request vouchers",
              );
            }

            return _buildDependantList(context, snapshot.data!.docs);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Add dependant
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Dependant"),
      ),
    );
  }

  Widget _buildDependantList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: snapshot.length,
      itemBuilder: (context, index) => _buildDependant(context, snapshot[index]),
    );
  }

  Widget _buildDependant(BuildContext context, DocumentSnapshot data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    const entity = Dependant(
      name: "John",
      relationship: "Fils",
      id: "ads",
      imageURL: "Sdf",
    );

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        child: Icon(
          Icons.person,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(entity.name),
      subtitle: Text(
        entity.relationship,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      trailing: FilledButton.tonal(
        onPressed: () => debugPrint("Demander bon"),
        child: const Text("Demander Bon"),
      ),
      onTap: () {
        debugPrint("Doc ID: ${entity.id}");
      },
    );
  }
}
