import 'package:arptc_connect/modules/courrier/screens/details_courrier.dart';
import 'package:arptc_connect/modules/courrier/screens/details_courrier_two.dart';
import 'package:arptc_connect/modules/courrier/screens/list_courriers_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/courrier_model.dart';
import '../providers/courrier_service_provider.dart';

class CourrierBaseScreen extends ConsumerStatefulWidget {
  const CourrierBaseScreen({super.key});

  @override
  ConsumerState createState() => _CourrierBaseScreenState();
}

final selectedCourrier = StateProvider<String>((ref) => "");

class _CourrierBaseScreenState extends ConsumerState<CourrierBaseScreen> {

  // var _selection = ValueNotifier<Courrier>(null);
  var id = "";

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, dimens) {
      if (dimens.maxWidth >= 700) {
        const kListViewWidth = 800.0;
        return Row(
          children: <Widget>[
            // List of all courriers
            Expanded(
              // width: kListViewWidth,
              flex: 1,
              child: _buildCourrierList((val) {
                ref.watch(selectedCourrier.notifier).state =
                val.id!;
              }),
            ),

            // Details of selected courrier
            Expanded(
              flex: 1,
              child: Consumer(
                builder: (context, ref, child) {
                  var courrier = ref.watch(selectedCourrier);

                  if (courrier == "") {
                    return const Center(
                        child: Text('Aucun courrier Selectionné'));
                  }

                  return StreamBuilder<Courrier>(
                    stream: ref
                        .watch(courrierServiceProvider)
                        .getCourrier(courrier),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                            child: Text('Erreur de connection'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.data == null) {
                        return const Center(
                            child: Text('Aucun courrier Selectionné'));
                      }

                      return DetailsCourrierTwo(snapshot.data!);
                    },
                  );
                },
              ),
            ),
          ],
        );
      }

      print("Small SCReen");

      return _buildCourrierList((val) {

        print("selecting details");

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DetailsCourrierScreen(val),
          ),
        );
      });
    });
  }

  Widget _buildCourrierList(ValueChanged<Courrier> onSelect) {
    return Padding(
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

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Aucun courrier'));
          }

          return Center(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              width: 800,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey)
              ),
              child: ListView(
                children: [
                  const Text(
                    "Liste des courriers",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...snapshot.data!.docs.map((DocumentSnapshot document) {

                    Courrier courrier = Courrier.fromDocument(document);

                    return ListTile(
                      title: Text(
                        courrier.sender,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(courrier.object,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.grey)),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        debugPrint("Selecting a courrier");
                        // ref.watch(selectedCourrier.notifier).state =
                        //     courrier.id!;

                        onSelect(courrier);
                      },
                    );

                  }).toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
