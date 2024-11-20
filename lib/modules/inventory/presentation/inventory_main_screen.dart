import 'package:arptc_connect/modules/service/screens/main_service_screen.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/content_view.dart';

class InventoryMainScreen extends StatelessWidget {
  InventoryMainScreen({super.key});

  final inventoryModules = [
    "Gestion des Stocks",
    "Approvisionnement",
    "Livraison"
  ];

  final List<Service> _inventoryServices = [
    Service("Gestion des Stocks", "management", Icons.inventory_2_outlined),
    Service("Approvisionnement", "appro", Icons.download),
    Service("Livraison", "livraison", Icons.upload),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: ContentView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios),
                    onPressed: () => context.pop(),
                  ),
                  const PageHeader(
                    title: 'Inventaire',
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
                      children: _inventoryServices.map((service) => serviceCard(context, service)).toList(),// Adjust spacing as needed
                    );
                  },
                ),
              )
            ],
          ),
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
                color: Colors.grey[700],
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
        context.go('/service/inventory/${service.path}');
      },
    );
  }
}
