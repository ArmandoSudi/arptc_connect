import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../models/dependant.dart';

class SocialAgentDetailsScreen extends StatelessWidget {
  final String agentId;
  late CollectionReference agentsRef;

  SocialAgentDetailsScreen({required this.agentId, super.key}) {
    this.agentsRef =
        FirebaseFirestore.instance.collection('agents/$agentId/dependants');
  }



  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return Scaffold(
        body: StreamBuilder<QuerySnapshot>(
            stream: agentsRef!.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text("something went wrong");
              }

              if (snapshot.data == null ||
                  snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (!snapshot.hasData) {
                return const Text("There is no dependant yet");
              }
              // print("Directions size : ${snapshot.data!.length}");
              return ContentView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PageHeader(title: "Détails de l'Agent", description: "description"),
                    Gap(16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  const CircleAvatar(
                                    radius: 150,
                                    backgroundImage:
                                    NetworkImage('https://picsum.photos/id/237/200/300', scale: 2),
                                  ),
                                  const Gap(24),
                                  Text("John Doe",
                                    style: theme.textTheme.titleLarge!.copyWith(
                                      fontWeight: FontWeight.w700,
                                    )),
                                  const Gap(16),
                                  Text("Direction Générale",
                                      style: theme.textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.w600,
                                  )),
                                  const Gap(16),
                                  Text("Service  Juridique",
                                      style: theme.textTheme.titleSmall!.copyWith(
                                        fontWeight: FontWeight.w600,
                                      )
                                  ),
                                  const Gap(16),
                                  ElevatedButton(
                                      onPressed: (){},
                                      child: Text("Demander bon", style: TextStyle(fontWeight: FontWeight.bold)),
                                  )
                                ],
                              ),
                            )
                          ),
                        ),
                        // Gap(16),
                        Expanded(
                          child: Card(
                            child:
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("Dépendants", style: theme.textTheme.titleMedium!.copyWith(
                                            fontWeight: FontWeight.w700,
                                          )),
                                          ElevatedButton.icon(
                                              icon: Icon(Icons.add),
                                              onPressed: (){

                                              }, label: Text("Ajouter", style: TextStyle(fontWeight: FontWeight.bold)),)
                                        ],
                                      ),
                                    ),
                                    _buildDependantList(context, snapshot.data?.docs ?? []),
                                  ],
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }));
  }

  Widget _buildDependantList(
      BuildContext context, List<DocumentSnapshot> snapshot) {
    if (snapshot.isEmpty) {
      return const Text("Cet agent n'a aucun dépendant");
    }
    return ListView(
      shrinkWrap: true,
      children: snapshot.map((data) => _buildDependant(context, data)).toList(),
    );
  }

  Widget _buildDependant(BuildContext context, DocumentSnapshot data) {
    final entity = Dependant.fromSnapshot(data);
    return ListTile(
      leading: const Icon(Icons.person),
      title: Text(entity.name),
      subtitle: Text(entity.relationship),
      trailing: ElevatedButton(
        child: Text("Demander Bon"),
        onPressed: () => print("Demander bon"),
      ),
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
