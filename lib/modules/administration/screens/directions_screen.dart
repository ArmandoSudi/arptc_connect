import 'package:arptc_connect/modules/administration/screens/add_direction_screen.dart';
import 'package:arptc_connect/modules/administration/screens/direction_details_screen.dart';
import 'package:arptc_connect/modules/administration/screens/services_screen.dart';
import 'package:flutter/material.dart';

class DirectionsScreen extends StatelessWidget {
  DirectionsScreen({Key? key}) : super(key: key);

  final directions = [
    "Direction des Systèmes d'Information",
    "Direction des Ressources Humaines",
    "Direction des Projets",
    "Direction des Etudes et Prospectives",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Directions"),
        ),
        body: SafeArea(
            child: ListView.builder(
          itemCount: directions.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              title: Text(directions[index]),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DirectionDetailsScreen(),
                  ),
                );
              },
            );
          },
        )),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddDirectionScreen(),
              ),
            );
          },
          child: const Icon(Icons.add),
        ));
  }
}
