import 'package:arptc_connect/modules/administration/screens/add_service_screen.dart';
import 'package:arptc_connect/modules/administration/screens/bureaux_screen.dart';
import 'package:flutter/material.dart';

class ServicesScreen extends StatelessWidget {
  ServicesScreen({Key? key}) : super(key: key);

  final services = [
    "Service de développement et base des données",
    "Service de l'infrastructures et réseaux",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Services"),
        ),
        body: SafeArea(
            child: ListView.builder(
              itemCount: services.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(services[index]),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: (){
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BureauxScreen(),
                      ),
                    );
                  },
                );
              },
            )
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddServiceScreen())),
          child: const Icon(Icons.add),
        )
    );
  }
}
