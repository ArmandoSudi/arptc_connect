import 'package:arptc_connect/modules/courrier/providers/courrier_service_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/courrier_model.dart';
import 'add_courrier_screen.dart';
import 'details_courrier.dart';

class ListCourriersScreen extends ConsumerStatefulWidget {
  const ListCourriersScreen({super.key});

  @override
  ConsumerState createState() => _ListCourriersScreenState();
}

class _ListCourriersScreenState extends ConsumerState<ListCourriersScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        centerTitle: false,
        title: const Text("Gestion des courriers"),
      ),
      // Retreiving all the courrier from a streambuilder
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: ref.watch(courrierServiceProvider).courriers.snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Erreur de connection'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.docs.isEmpty){
              return const Center(child: Text('Aucun courrier'));
            }

            return Center(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                width: 800,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListView(
                  children: [
                    Text("Liste des courriers", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ... snapshot.data!.docs.map((DocumentSnapshot document) {
                      Courrier courrier = Courrier.fromDocument(document);
                      return ListTile(
                        title: Text(courrier.sender, style: TextStyle(fontWeight: FontWeight.bold,)),
                        subtitle: Text(courrier.object,  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => DetailsCourrierScreen(courrier)));
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => AddCourrierScreen()));
        },
        child: const Icon(Icons.add),
      )
    );
  }
}
