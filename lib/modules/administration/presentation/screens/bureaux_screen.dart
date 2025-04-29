import 'dart:developer';

import 'package:arptc_connect/modules/administration/data/administration_api_provider.dart';
import 'package:arptc_connect/modules/administration/data/bureau_provider.dart';
import 'package:arptc_connect/modules/administration/domain/models/bureau.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../widgets/content_view.dart';
import '../../../../widgets/page_header.dart';
import '../../../../widgets/yes_or_no_dialog.dart';

class BureauxScreen extends ConsumerWidget {
  BureauxScreen({super.key});

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
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          onPressed: () {
                            context.pop();
                          },
                        ),
                        const Gap(16),
                        const PageHeader(
                          title: 'Bureaux',
                          description: 'La liste de tous les bureaux',
                        ),
                        Expanded(child: Container()),
                        FilledButton.icon(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            context.go('/administration/bureaux/add');
                          },
                          label: const Text("Nouveau bureau",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const Gap(16),
                    Expanded(
                      child: _buildBureauList(
                        context,
                        snapshot.data?.docs ?? [],
                        ref,
                      ),
                    ),
                    const Gap(16),

                  ],
                );
              }),
        ),
      ),
    );
  }

  Widget _buildBureauList(
    BuildContext context,
    List<DocumentSnapshot> snapshot,
    WidgetRef ref,
  ) {
    return ListView.separated(
      itemCount: snapshot.length,
      itemBuilder: (context, index) {
        final data = snapshot[index];
        return _buildEntity(context, data, ref);
      },
      separatorBuilder: (BuildContext context, int index) {
        return const Divider();
      },
    );
  }

  Widget _buildEntity(
    BuildContext context,
    DocumentSnapshot data,
    WidgetRef ref,
  ) {
    final entity = Bureau.fromDocument(data);
    return ListTile(
      title: Text(entity.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.grey),
            onPressed: () async  {
              final result = await showCupertinoYesNoDialog(
                context,
                'Modification',
                'Voulez-vous vraiment modifier le ${entity.name} ?',
              );
              if (result == true) {
                // TODO : implement the edit action
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: () async{
              final result = await showCupertinoYesNoDialog(
                context,
                'Suppression',
                'Voulez-vous vraiment supprimer le ${entity.name} ?',
              );
              if (result == true) {
                ref.read(bureauControllerProvider.notifier).delete(entity.id!);
                log('${entity.name} deleted');
              }
            },
          ),
        ],
      ),

    );
  }

}
