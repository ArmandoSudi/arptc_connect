import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../widgets/content_view.dart';
import '../../../../widgets/page_header.dart';

class AdministrationScreen extends StatelessWidget {
  AdministrationScreen({super.key});

  final entities = [
  {"Directions" : "directions"},
  {"Services" : "services"},
  {"Bureaux" : "bureaux"},
  {"Agents" : "agents"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ContentView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Administration',
              description: 'La gestion des directions, des services, des bureaux et des agents',
            ),
            const Gap(16),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: entities.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final entity = entities[index];
                  return ListTile(
                    title: Text(
                      entity.keys.first,
                      // style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.navigate_next_outlined),
                    onTap: () {
                      context.go("/administration/${entity.values.first}");
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
