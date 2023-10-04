import 'package:arptc_connect/modules/administration/screens/add_direction_screen.dart';
import 'package:arptc_connect/modules/administration/screens/direction_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../utils/entity_model.dart';

class DirectionsScreen extends StatelessWidget {
  DirectionsScreen({Key? key}) : super(key: key);

  final db = FirebaseFirestore.instance;

  final directions = [
    "Direction des Systèmes d'Information",
    "Direction des Ressources Humaines",
    "Direction des Projets",
    "Direction des Etudes et Prospectives",
  ];

  CollectionReference directionsRef =
  FirebaseFirestore.instance.collection('directions');



  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(
          title: const Text("Directions"),
        ),
        body: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: directionsRef.snapshots(),
            builder: (context, snapshot) {

              if (snapshot.hasError) {
                return const Text("something wen wrong");
              }

              if (snapshot.data == null || snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
              } else if (!snapshot.hasData) {
                  return const Text("There is no direction yet");
              }
                  // print("Directions size : ${snapshot.data!.length}");
                  return _buildDirectionList(context, snapshot.data?.docs ?? []);
              }

          ),
        ),
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

  Widget _buildDirectionList( BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      children: snapshot.map((data) => _buildEntity(context, data)).toList(),
    );
  }

  Widget _buildEntity(BuildContext context, DocumentSnapshot data) {
    final entity = Entity.fromSnapshot(data);
    return ListTile(
      title: Text(entity.name),
      trailing: Icon(Icons.arrow_forward_ios),
      onTap: () {

        debugPrint("Doc ID: ${entity.reference.id}");

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DirectionDetailsScreen(),
          ),
        );
      },
    );
  }
}