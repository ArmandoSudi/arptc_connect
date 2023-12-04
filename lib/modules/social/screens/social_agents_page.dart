import 'package:arptc_connect/modules/social/screens/social_agent_details_screen.dart';
import 'package:arptc_connect/modules/social/screens/user_dependant_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';

import '../../../models/agent.dart';
import '../../../widgets/content_view.dart';

class SocialAgentsPage extends StatefulWidget {
  const SocialAgentsPage({super.key});

  @override
  State<SocialAgentsPage> createState() => _SocialAgentsPageState();
}

class _SocialAgentsPageState extends State<SocialAgentsPage> {
  final db = FirebaseFirestore.instance;
  bool _isSearching = false;

  CollectionReference agentsRef =
  FirebaseFirestore.instance.collection('agents');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
            // title: _isSearching ? CupertinoSearchTextField() : Container(),
            title: const CupertinoSearchTextField(placeholder: "Rechercher un agent",),
        ),
        body: Padding(
            padding: ResponsiveBreakpoints.of(context).isMobile
                ? const EdgeInsets.all(16)
                : const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: StreamBuilder<QuerySnapshot>(
                stream: agentsRef.snapshots(),
                builder: (context, snapshot) {

                  if (snapshot.hasError) {
                    return const Text("Une erreur est survenue");
                  }

                  if (snapshot.data == null || snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (!snapshot.hasData) {
                    return const Text("Il n'y a aucun Agent");
                  }

                  List<Agent>? agents = snapshot.data?.docs.map((data) => Agent.fromDocument(data)).toList();

                  return Card(
                      child: ListView.separated(
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
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => SocialAgentDetailsScreen(agentId: agents![index].id!),
                                  ),
                                );
                              },
                            );
                          },
                          separatorBuilder: (context, index) => Divider(),
                          itemCount: agents?.length ?? 0)
                  );
                }

            )
        ),
    );
  }

}
