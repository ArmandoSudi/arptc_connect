import 'dart:developer';

import 'package:arptc_connect/core/constants.dart';
import 'package:arptc_connect/core/shared_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/content_view.dart';
import '../../../widgets/page_header.dart';

class MainServiceScreen extends ConsumerWidget {
  MainServiceScreen({super.key});

  final services = [
    {"Courrier": "Courrier"},
    {"Social": "Social"},
    {"Inventory": "Inventaire"},
    {"Ticketing": "Ticketerie"},
  ];



  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final roles = ref.read(sharedPrefUtilityProvider).getRoles();

    final authorizedServices = getAccreditedService(roles);

    return Scaffold(
        body: ContentView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PageHeader(
              title: 'Applications métiers',
              description: '',
            ),
          ],
        ),
        const Gap(16),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth;
              final int columnCount = calculateColumnCount(maxWidth);
              return GridView.count(
                crossAxisCount: columnCount,
                mainAxisSpacing: 10.0, // Adjust spacing as needed
                crossAxisSpacing: 10.0,
                childAspectRatio: 5 / 3,
                children: authorizedServices.map((service) => serviceCard(context, service)).toList(),// Adjust spacing as needed
              );
            },
          ),
        ),
        const Gap(16),
      ]),
    ));
  }

  int calculateColumnCount(double maxWidth) {
    if (maxWidth >= 800) { // Adjust width thresholds as needed
      return 4;
    } else if (maxWidth >= 600) {
      return 3;
    } else {
      return 2;
    }
  }

  Widget serviceCard(BuildContext context, Service service) {
    return InkWell(
      child: Card(
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                service.iconData,
                color: service.color,
                size: 40,
              ),
              const Gap(8),
              Text(
                service.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        context.go('/service/${service.path}');
      },
    );
  }
  
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
