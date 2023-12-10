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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: ContentView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              context.pop();
            },
            label: const Text("Retour"),
          ),
          const Gap(16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                child: Card(
                  child: Container(
                    height: 100,
                    width: 250,
                    alignment: Alignment.center,
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(15)),
                    child: Text(
                      inventoryModules[0],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                onTap: () {
                  // context.go('/service/$path');
                },
              ),
              const Gap(16),
              InkWell(
                child: Card(
                  child: Container(
                    height: 100,
                    width: 250,
                    alignment: Alignment.center,
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(15)),
                    child: Text(
                      inventoryModules[1],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                onTap: () {
                  // context.go('/service/$path');
                },
              ),
              const Gap(16),
              InkWell(
                child: Card(
                  child: Container(
                    height: 100,
                    width: 250,
                    alignment: Alignment.center,
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(15)),
                    child: Text(
                      inventoryModules[2],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                onTap: () {
                  // context.go('/service/$path');
                },
              ),

            ],
          ),
        ],
      ),
    ));
  }
}
