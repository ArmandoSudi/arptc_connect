import 'package:arptc_connect/modules/courrier/providers/courrier_service_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/content_view.dart';
import '../../../widgets/page_header.dart';
import '../models/courrier_model.dart';
import 'add_courrier_screen.dart';

class ListCourriersScreen extends ConsumerStatefulWidget {
  const ListCourriersScreen({super.key});

  @override
  ConsumerState createState() => _ListCourriersScreenState();
}

class _ListCourriersScreenState extends ConsumerState<ListCourriersScreen> {

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return Scaffold(
      body: ContentView(
        child: StreamBuilder<QuerySnapshot>(
          stream: ref.watch(courrierServiceProvider).courriers.snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Erreur de connection'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.docs.isEmpty){
              return const Center(child: Text('Aucun courrier'));
            }

            var courriers = snapshot.data!.docs.map((DocumentSnapshot document) {
              Courrier courrier = Courrier.fromDocument(document);
              return courrier;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const PageHeader(
                      title: 'Courriers',
                      description: 'La liste des courriers de la DEP',
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => AddCourrierScreen()));
                      },
                      label: const Text("Enregistrer courrier", style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const Gap(16),
                Expanded(
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListView.separated(
                      itemCount: courriers.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final courrier = courriers[index];
                        return ListTile(
                          title: Text(
                            courrier.sender,
                            style: theme.textTheme.bodyMedium!
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            courrier.object,
                            style: theme.textTheme.labelMedium,
                          ),
                          trailing: const Icon(Icons.navigate_next_outlined),
                          onTap: () {
                            // UserPageRoute(userId: user.userId).go(context);
                            context.go('/courriers/${courrier.id}');
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Navigator.of(context).push(
      //         MaterialPageRoute(builder: (context) => AddCourrierScreen()));
      //   },
      //   child: const Icon(Icons.add),
      // )
    );
  }
}
