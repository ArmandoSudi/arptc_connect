import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/dependant.dart';

class UserDependantPage extends StatelessWidget {
  UserDependantPage({super.key});

  final db = FirebaseFirestore.instance;

  CollectionReference agentsRef =
  FirebaseFirestore.instance.collection('agents/PyKV8iGiDzcTdQSaRzWD/dependants');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: StreamBuilder<QuerySnapshot>(
                stream: agentsRef.snapshots(),
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
                  return _buildDependantList(context, snapshot.data?.docs ?? []);
                }

            )
        ),
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
      subtitle: Text(entity.relation),
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
