import 'package:arptc_connect/widgets/content_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/dependant.dart';

class SocialAgentDetailsScreen extends StatelessWidget {

  final String agentId;
  late CollectionReference agentsRef;

  SocialAgentDetailsScreen( {required this.agentId, super.key}){
    this.agentsRef =
    FirebaseFirestore.instance.collection('agents/$agentId/dependants');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: agentsRef!.snapshots(),
        builder: (context, snapshot) {

          if (snapshot.hasError) {
            return const Text("something wen wrong");
          }

          if (snapshot.data == null || snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData) {
            return const Text("There is no dependant yet");
          }
          // print("Directions size : ${snapshot.data!.length}");
          return ContentView(child: Card(child: _buildDependantList(context, snapshot.data?.docs ?? [])));
        }

      )
    );
  }

  Widget _buildDependantList( BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      children: snapshot.map((data) => _buildDependant(context, data)).toList(),
    );
  }

  Widget _buildDependant(BuildContext context, DocumentSnapshot data) {
    final entity = Dependant.fromSnapshot(data);
    return ListTile(
      leading: const Icon(Icons.person),
      title: Text(entity.name),
      subtitle: Text(entity.relationship),
      trailing: ElevatedButton(child: Text("Demander Bon"), onPressed: () => print("Demander bon"),),
      onTap: () {
        debugPrint("Doc ID: ${entity.reference.id}");
        // Navigator.of(context).push(
        //   MaterialPageRoute(
        //     builder: (context) => DirectionDetailsScreen(),
        //   ),
        // );
      },
    );
  }
}
