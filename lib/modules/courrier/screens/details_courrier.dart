import 'package:arptc_connect/modules/courrier/screens/add_annotation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/content_view.dart';
import '../../../widgets/page_header.dart';
import '../models/courrier_model.dart';
import '../providers/courrier_service_provider.dart';

class DetailsCourrierScreen extends ConsumerWidget {
  String courrierId;

  DetailsCourrierScreen(this.courrierId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        body: ContentView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const PageHeader(
                    title: 'Détails du courrier',
                    description: '',
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      // Navigator.of(context).push(MaterialPageRoute(
                      //     builder: (context) => AddAnnotationScreen(courrierId: 'xxx')));
                      context.go('/courriers/$courrierId/annotations/enregistrer');
                    },
                    label: const Text("Ajouter Annotation"),
                  )
                ],
              ),
              const Gap(16),
              StreamBuilder<Courrier>(
                  stream: ref.watch(courrierServiceProvider).getCourrier(courrierId!),
                  builder: (context, snapshot) {

                    if (snapshot.hasError) {
                      return const Center(child: Text('Erreur de connection'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return Column(
                      children: [
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
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
                                    "${snapshot.data!.sender}",
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
                                    "${snapshot.data!.object}",
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
                                    "${snapshot.data!.date.day}-${snapshot.data!.date.month}-${snapshot.data!.date.year}",
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
                                      // ElevatedButton.icon(
                                      //   icon: const Icon(Icons.add),
                                      //   onPressed: () {
                                      //     Navigator.of(context).push(MaterialPageRoute(
                                      //         builder: (context) => AddAnnotationScreen(courrierId: snapshot.data!.id!)));
                                      //   },
                                      //   label: const Text("Ajouter Annotation"),
                                      // )
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ListView.separated(
                                      itemBuilder: (context, index) {
                                        return ListTile(
                                            title: Text(
                                                "${snapshot.data!.annotations[index]["entity"]}",
                                                style:
                                                const TextStyle(fontWeight: FontWeight.bold)),
                                            subtitle: Text(
                                                "${snapshot.data!.annotations[index]["object"]}"),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.delete_forever,
                                                  color: Colors.red),
                                              onPressed: () {
                                                debugPrint("delete");
                                                ref
                                                    .read(courrierServiceProvider)
                                                    .deleteAnnotationAtIndex(snapshot.data!, index);

                                                ref.read(courrierServiceProvider).getCourrier(snapshot.data!.id!);

                                              },
                                            ));
                                      },
                                      separatorBuilder: (context, index) => Divider(),
                                      itemCount: snapshot.data!.annotations.length,
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics()),
                                ]),
                          ),
                        ),
                      ],
                    );
                  }
              ),
              const Gap(16),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () {
                  context.pop();
                },
                label: const Text("Retour"),
              )
            ]
          ),
        ));
  }
}
