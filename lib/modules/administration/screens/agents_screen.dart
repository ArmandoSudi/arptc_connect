import 'package:arptc_connect/modules/administration/screens/add_agent_screen.dart';
import 'package:arptc_connect/modules/administration/screens/example_drop_down.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../models/agent.dart';
import '../../../widgets/content_view.dart';

class AgentsScreen extends StatefulWidget {
  const AgentsScreen({Key? key}) : super(key: key);

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {

  final db = FirebaseFirestore.instance;
  bool _isSearching = false;

  CollectionReference agentsRef =
  FirebaseFirestore.instance.collection('agents');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: ContentView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const PageHeader(title: "Liste des agents", description: ''),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AddAgentScreen(),
                          ),
                        );
                      },
                      label: const Text("Enregistrer agent", style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const Gap(16),
                const CupertinoSearchTextField(placeholder: "Rechercher un agent",),
                const Gap(16),
                StreamBuilder<QuerySnapshot>(
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

                      List<Agent>? agents = snapshot.data?.docs.map((data) => Agent.fromDocument(data)).toList();

                      return Card(
                          child: ListView.separated(
                            shrinkWrap: true,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading: Container(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.person),
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(50),
                                          color: Colors.grey[300]
                                      )
                                  ),
                                  title: Text(agents![index].name),
                                  trailing: const Icon(Icons.arrow_forward_ios),
                                  onTap: () {
                                    debugPrint("Doc ID: ${agents?[index].id}");
                                    // Navigator.of(context).push(
                                    //   MaterialPageRoute(
                                    //     builder: (context) => SocialAgentDetailsScreen(agentId: agents![index].id!),
                                    //   ),
                                    // );
                                  },
                                );
                              },
                              separatorBuilder: (context, index) => Divider(),
                              itemCount: agents?.length ?? 0)
                      );
                    }

                ),
                const Gap(16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    context.pop();
                  },
                  label: const Text("Retour"),
                )
              ],
            )
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DropdownMenuExample(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

}
