import 'dart:developer';

import 'package:arptc_connect/core/constants.dart';
import 'package:arptc_connect/modules/service/module_config.dart';
import 'package:arptc_connect/widgets/module_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/content_view.dart';
import '../../../widgets/page_header.dart';

class MainServiceScreen extends ConsumerWidget {
  MainServiceScreen({super.key});
  //
  // final services = [
  //   {"Courrier": "Courrier"},
  //   {"Social": "Social"},
  //   {"Inventory": "Inventaire"},
  //   {"Ticketing": "Ticketerie"},
  //   {"MeetingHall": "Salles de réunion"}, // Added meeting hall service
  // ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final roles = ref.read(sharedPrefUtilityProvider).getRoles();

    // TODO : Get all the services for now but later we will filter them based on the roles
    final roles = ["TICKETING", "TASK", "COURRIER", "INVENTORY", "MEETING"];
    // final authorizedServices = getAccreditedService(roles);

    return CustomScrollView(
      slivers: [
        // Welcome Header
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "John Doe",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
              ],
            ),
          ),
        ),

        // Modules Grid
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getCrossAxisCount(context),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final module = ModulesConfig.allModules[index];
                return ModuleCard(module: module);
              },
              childCount: ModulesConfig.allModules.length,
            ),
          ),
        ),
      ],
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 2;
  }

  // int calculateColumnCount(double maxWidth) {
  //   if (maxWidth >= 800) {
  //     // Adjust width thresholds as needed
  //     return 4;
  //   } else if (maxWidth >= 600) {
  //     return 3;
  //   } else {
  //     return 2;
  //   }
  // }
  //
  // Widget serviceCard(BuildContext context, Service service) {
  //   return InkWell(
  //     child: Card(
  //       child: Container(
  //         alignment: Alignment.center,
  //         decoration: BoxDecoration(
  //             borderRadius: BorderRadius.circular(15)),
  //         child: Row(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Icon(
  //               service.iconData,
  //               color: service.color,
  //               size: 40,
  //             ),
  //             const Gap(8),
  //             Text(
  //               service.name,
  //               style: const TextStyle(
  //                 fontWeight: FontWeight.bold,
  //                 fontSize: 18,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //     onTap: () {
  //       context.go('/service/${service.path}');
  //     },
  //   );
  // }

  List<Service> getAccreditedService(List<String> roles) {
    List<Service> services = [];

    for (String role in roles) {
      if (Constants.modules.containsKey(role)) {
        services.add(Constants.modules[role]!);
      }
    }

    return services;
  }
}

class Service {
  final String name;
  final String path;
  final IconData iconData;

  Color? color;

  Service(this.name, this.path, this.iconData, {this.color});
}
