import 'package:arptc_connect/modules/administration/screens/agents_screen.dart';
import 'package:arptc_connect/modules/administration/screens/bureaux_screen.dart';
import 'package:arptc_connect/modules/administration/screens/services_screen.dart';
import 'package:flutter/material.dart';

import 'directions_screen.dart';

class AdministrationScreen extends StatelessWidget {
  AdministrationScreen({Key? key}) : super(key: key);

  final entities = [
    "Directions",
    "Services",
    "Bureaux",
    "Agents",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Administration"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              ListTile(
                title: const Text("Directions"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DirectionsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text("Services"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ServicesScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text("Bureaux"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => BureauxScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text("Agents"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AgentsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        )
      ),
    );
  }
}
