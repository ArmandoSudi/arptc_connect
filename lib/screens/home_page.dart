import 'package:arptc_connect/modules/social/screens/user_social_screen.dart';
import 'package:flutter/material.dart';

import '../modules/administration/screens/administration_screen.dart';

enum Modules {social, inventory, helpDesk, administration}

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  final _services = [
    Services(
      name: "Social",
      icon: const Icon(
        Icons.people_alt_outlined,
        size: 90,
        color: Colors.purple,
      ),
      module: Modules.social,
    ),
    Services(
      name: "Inventory",
      icon: const Icon(
        Icons.inventory_outlined,
        size: 90,
        color: Colors.purple,
      ),
      module: Modules.inventory,
    ),
    Services(
      name: "Help Desk",
      icon: const Icon(
        Icons.support_agent_outlined,
        size: 90,
        color: Colors.purple,
      ),
      module: Modules.helpDesk,
    ),
    Services(
      name: "Administration",
      icon: const Icon(
        Icons.admin_panel_settings_outlined,
        size: 90,
        color: Colors.purple,
      ),
      module: Modules.administration,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Services"),
      ),
      body: SafeArea(
        child: GridView.builder(
          itemCount: _services.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
          ),
          itemBuilder: (context, index) {
            return InkWell(
                child: Card(
                    child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _services[index].icon,
                      Text("${_services[index].name}"),
                    ],
                  ),
                )),
                onTap: () {

                  switch(_services[index].module){
                    case Modules.social:
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const UserSocialScreen()),
                      );
                      break;
                    case Modules.inventory:
                      print("inventory");
                      break;
                    case Modules.helpDesk:
                      print("helpDesk");
                      break;
                    case Modules.administration:
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) =>  AdministrationScreen()),
                      );
                      break;
                  }


                });
          },
        ),
      ),
    );
  }
}

class Services {
  final String name;
  final Icon icon;
  final Modules module;

  Services({required this.name, required this.icon ,required this.module});
}
