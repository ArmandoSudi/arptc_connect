import 'package:arptc_connect/modules/courrier/screens/add_annotation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/courrier_model.dart';
import '../providers/courrier_service_provider.dart';

class DetailsCourrierScreen extends ConsumerWidget {
  Courrier courrier;

  DetailsCourrierScreen(this.courrier, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        backgroundColor: Colors.grey[300],
        appBar: AppBar(
          title: const Text("Détails du Courier"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24.0),
              width: 800,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: StreamBuilder<Courrier>(
                stream: ref.watch(courrierServiceProvider).getCourrier(courrier.id!),
                builder: (context, snapshot) {

                  if (snapshot.hasError) {
                    return const Center(child: Text('Erreur de connection'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // if (snapshot.data!.docs.isEmpty){
                  //   return const Center(child: Text('Aucun courrier'));
                  // }

                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Expediteur
                        Text(
                          "Expéditeur",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          "${courrier.sender}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Objet
                        Text(
                          "Objet",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          "${courrier.object}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Date Réception
                        Text(
                          "Date de recéption",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          "${courrier.date.day}-${courrier.date.month}-${courrier.date.year}",
                          // courrier.date.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Annotations
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Annotations",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            TextButton.icon(
                              icon: Icon(Icons.add),
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => AddAnnotationScreen(courrierId: courrier.id!)));
                              },
                              label: Text("Ajouter Annotation"),
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                        ListView.separated(
                            itemBuilder: (context, index) {
                              return ListTile(
                                  title: Text(
                                      "${courrier.annotations[index]["entity"]}",
                                      style:
                                          const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                      "${courrier.annotations[index]["object"]}"),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_forever,
                                        color: Colors.red),
                                    onPressed: () {
                                      debugPrint("delete");
                                      ref
                                          .read(courrierServiceProvider)
                                          .deleteAnnotationAtIndex(courrier, index);

                                      ref.read(courrierServiceProvider).getCourrier(courrier.id!);

                                    },
                                  ));
                            },
                            separatorBuilder: (context, index) => Divider(),
                            itemCount: courrier.annotations.length,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics()),
                      ]);
                }
              ),
            ),
          ),
        ));
  }
}
