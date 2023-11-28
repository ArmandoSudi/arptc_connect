import 'package:arptc_connect/modules/administration/screens/add_direction_screen.dart';
import 'package:arptc_connect/modules/administration/screens/direction_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../utils/entity_model.dart';
import '../../../widgets/content_view.dart';
import '../../../widgets/page_header.dart';
import '../../courrier/screens/add_courrier_screen.dart';

class DirectionsScreen extends StatelessWidget {
  DirectionsScreen({Key? key}) : super(key: key);

  CollectionReference directionsRef =
      FirebaseFirestore.instance.collection('directions');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ContentView(
          child: StreamBuilder<QuerySnapshot>(
              stream: directionsRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text("something went wrong");
                }

                if (snapshot.data == null ||
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (!snapshot.hasData) {
                  return const Text("There is no direction yet");
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const PageHeader(
                          title: 'Directions',
                          description: 'La liste de toutes les Directions',
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => AddDirectionScreen(),
                              ),
                            );
                          },
                          label: const Text("Enregistrer direction",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const Gap(16),
                    Expanded(
                      child: Card(
                        child: _buildDirectionList(
                            context, snapshot.data?.docs ?? []),
                      ),
                    ),
                    const Gap(16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () {
                        context.pop();
                      },
                      label: const Text("Retour"),
                    )
                  ],
                );
              }),
        ),
      ),
    );
  }

  Widget _buildDirectionList(
      BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView.separated(
      itemCount: snapshot.length,
      itemBuilder: (context, index) {
        final data = snapshot[index];
        return _buildEntity(context, data);
      },
      separatorBuilder: (BuildContext context, int index) {
        return const Divider();
      },
      // children: snapshot.map((data) => _buildEntity(context, data)).toList(),
    );
  }

  Widget _buildEntity(BuildContext context, DocumentSnapshot data) {
    final entity = Entity.fromSnapshot(data);
    return ListTile(
      title: Text(entity.name),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DirectionDetailsScreen(),
          ),
        );
      },
    );
  }
}
