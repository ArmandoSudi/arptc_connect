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
          child: ListView.builder(
        itemCount: entities.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(entities[index]),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DirectionsScreen(),
                ),
              );
            },
          );
        },
      )),
    );
  }
}
