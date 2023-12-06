import 'package:arptc_connect/modules/administration/screens/agents_screen.dart';
import 'package:arptc_connect/modules/administration/screens/bureaux_screen.dart';
import 'package:arptc_connect/modules/administration/screens/services_screen.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/content_view.dart';
import '../../../widgets/page_header.dart';
import 'directions_screen.dart';

class AdministrationScreen extends StatelessWidget {
  AdministrationScreen({Key? key}) : super(key: key);

  final entities = [
  {"Directions" : DirectionsScreen()},
  {"Services" : ServicesScreen()},
  {"Bureaux" : BureauxScreen()},
  {"Agents" : AgentsScreen()},
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
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => entity.values.first,
                        ),
                      );
                    },
                  );
                },
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
        ),
      ),
    );
  }
}
