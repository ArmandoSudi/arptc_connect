import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../models/bureau.dart';
import '../../../widgets/content_view.dart';
import '../../../widgets/page_header.dart';
import '../providers/administration_api_provider.dart';
import 'add_bureau_screen.dart';
import 'direction_details_screen.dart';

class BureauxScreen extends ConsumerWidget {

  BureauxScreen({Key? key}) : super(key: key);

  final bureaux = [
    "Bureau Webmaster",
    "Bureau Téléphonie et Messagerie",
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: ContentView(
          child: StreamBuilder<QuerySnapshot>(
              stream: ref.watch(administrationAPIProvider).bureaux.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text("Error loading the services");
                }

                if (snapshot.data == null ||
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (!snapshot.hasData) {
                  return const Text("There is no service yet");
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(icon:Icon(Icons.arrow_back_ios), onPressed: () {
                          context.pop();
                        },),
                        const Gap(16),
                        const PageHeader(
                          title: 'Bureaux',
                          description: 'La liste de tous les bureaux',
                        ),
                        Expanded(child: Container()),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            context.go('/administration/bureaux/add');
                          },
                          label: const Text("Enregistrer bureau",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const Gap(16),
                    Expanded(
                      child: Card(
                        child: _buildBureauList(
                            context, snapshot.data?.docs ?? []),
                      ),
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
                );
              }),
        ),
      ),
    );
  }

  Widget _buildBureauList(
      BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView.separated(
      itemCount: snapshot.length,
      itemBuilder: (context, index) {
        final data = snapshot[index];
        return _buildEntity(context, data);
      },
      separatorBuilder: (BuildContext context, int index) {
        return const Divider();
      },
    );
  }

  Widget _buildEntity(BuildContext context, DocumentSnapshot data) {
    final entity = Bureau.fromDocument(data);
    return ListTile(
      title: Text(entity.name),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DirectionDetailsScreen(),
          ),
        );
      },
    );
  }
}
