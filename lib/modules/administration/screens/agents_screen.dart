import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/agent.dart';

class AgentsScreen extends StatefulWidget {
  const AgentsScreen({Key? key}) : super(key: key);

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {

  final agents = [
    "Agent 1",
    "Agent 2",
    "Agent 3",
  ];

  final db = FirebaseFirestore.instance;

  CollectionReference agentsRef =
  FirebaseFirestore.instance.collection('agents');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Agents"),
        ),
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
                    return const Text("There is no direction yet");
                  }
                  // print("Directions size : ${snapshot.data!.length}");
                  return _buildAgentList(context, snapshot.data?.docs ?? []);
                }

            )
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add),
        )
    );
  }

  Widget _buildAgentList( BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      children: snapshot.map((data) => _buildAgent(context, data)).toList(),
    );
  }

  Widget _buildAgent(BuildContext context, DocumentSnapshot data) {
    final entity = Agent.fromSnapshot(data);
    return ListTile(
      title: Text(entity.name),
      trailing: Icon(Icons.arrow_forward_ios),
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
