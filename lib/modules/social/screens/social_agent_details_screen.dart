import 'dart:developer';

import 'package:arptc_connect/modules/administration/data/administration_api_provider.dart';
import 'package:arptc_connect/modules/social/screens/data/voucher_service.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/responsive_center.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../administration/domain/models/agent.dart';

class SocialAgentDetailsScreen extends ConsumerStatefulWidget {
  final String agentId;
  late CollectionReference agentsRef;

  SocialAgentDetailsScreen({required this.agentId, super.key}) {
    agentsRef =
        FirebaseFirestore.instance.collection('agents/$agentId/dependants');
  }

  @override
  ConsumerState createState() => _SocialAgentDetailsScreenState();
}

class _SocialAgentDetailsScreenState
    extends ConsumerState<SocialAgentDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Détails de l'Agent"),
      ),
      body: FutureBuilder<Agent>(
        future:
            ref.watch(administrationAPIProvider).getAgentById(widget.agentId),
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
          Agent agent = snapshot.data!;

          log("AGENT DETAILS : $agent");
          return ContentView(
            child: ResponsiveCenter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PROFILE PICTURE
                  const Gap(16),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // PROFILE
                          const CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(
                                'https://i.pravatar.cc/300?img=49',
                                scale: 2),
                          ),
                          const Gap(24),

                          // NAME
                          Text(
                            agent.name,
                            style: theme.textTheme.titleLarge!.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Gap(16),

                          // DEPARTMENT
                          Text(
                            "Direction Générale",
                            style: theme.textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Gap(16),

                          // SERVICE
                          Text(
                            "Service  Developpement et Base des données",
                            style: theme.textTheme.titleSmall!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Gap(16),

                          // ACTIONS
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  // primary: theme.primaryColor
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 32),
                                  side: BorderSide(color: theme.primaryColor),
                                ),
                                onPressed: () async {
                                  log("Generer bon");
                                  VoucherService().generateVoucher(agent);
                                },
                                icon: const Icon(Icons.file_copy_outlined),
                                label: const Text("Bon Médical"),
                              ),
                              const Gap(16),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  // primary: theme.primaryColor
                                  padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                                  side: BorderSide(color: theme.primaryColor),
                                ),
                                onPressed: () async {
                                  log("Générer attestation");
                                  VoucherService().generateAttestation(agent);
                                },
                                icon: const Icon(Icons.file_copy_outlined),
                                label: const Text("Attestation de Service"),
                              ),
                            ],
                          ),

                        ],
                      ),
                    ),
                  ),
                  const Gap(16),

                  // DEPENDANTS
                  Card(
                    color: Colors.white,
                    elevation: 5,
                    child: Container(
                      // color: Colors.white,
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Dépendants",
                                  style: theme.textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                FilledButton(
                                  onPressed: () => log("Add dependant"),
                                  child: const Text("Ajouter dépendant"),
                                ),
                              ],
                            ),
                          ),
                          // TODO Implement the service to fetch dependants
                          // FutureBuilder(
                          //     future: future,
                          //     builder: builder),
                          // _buildDependantList(
                          //     context, snapshot ?? []),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDependantList(
      BuildContext context,
      List<Map<String, dynamic>> dependants) {
    if (dependants.isEmpty) {
      return const Text("Cet agent n'a aucun dépendant");
    }
    return ListView.separated(
      shrinkWrap: true,
      itemBuilder: (BuildContext context, int index) {
        return _buildDependant(context, {"name": "John Doe"});
      },
      separatorBuilder: (BuildContext context, int index) {
        return const Divider();
      },
      itemCount: dependants.length,
    );
  }

  Widget _buildDependant(BuildContext context, Map<String, dynamic> data) {
    // final entity = Dependant(
    //   name: "John",
    //   relationship: "Fils",
    //   id: "ads",
    //   imageURL: "Sdf",
    // );
    return ListTile(
      leading: const Icon(Icons.person),
      title: Text(data["name"]),
      subtitle: Text(data["relation"]),
      trailing: IconButton(
        icon: const Icon(Icons.file_copy_outlined),
        onPressed: () => log("Generer bon"),
      ),
      onTap: () {
        debugPrint("Doc ID: $data");
        // Navigator.of(context).push(
        //   MaterialPageRoute(
        //     builder: (context) => DirectionDetailsScreen(),
        //   ),
        // );
      },
    );
  }
}
