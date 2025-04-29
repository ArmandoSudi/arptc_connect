import 'dart:developer';

import 'package:arptc_connect/modules/administration/data/administration_api_provider.dart';
import 'package:arptc_connect/modules/administration/data/directions_provider.dart';
import 'package:arptc_connect/widgets/custom_filledbutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/direction.dart';

class DirectionDetailsScreen extends ConsumerStatefulWidget {

  final String directionId;
  const DirectionDetailsScreen({super.key, required this.directionId});

  @override
  ConsumerState createState() => _DirectionDetailsScreenState();
}

class _DirectionDetailsScreenState extends ConsumerState<DirectionDetailsScreen> {
  bool isServiceExpanded = false;
  bool isAgentExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: const Text("Directions"),
          actions: const [
            IconButton(onPressed: null, icon: Icon(Icons.edit))
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: FutureBuilder<Direction>(
                future: ref.watch(administrationAPIProvider).getDirectionById(widget.directionId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Erreur de connection'));
                  }
                  final direction = snapshot.data as Direction;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        direction.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Services",
                                    style: TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                    onPressed: () {
                                      setState(() {
                                        isServiceExpanded = !isServiceExpanded;
                                      });
                                    },
                                  )
                                ],
                              ),
                              const SizedBox(height: 20),
                              isServiceExpanded
                                  ? ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: 3,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Text("Service $index"),
                                    );
                                  })
                                  : Container(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Agents",
                                    style: TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                    onPressed: () {
                                      setState(() {
                                        isAgentExpanded = !isAgentExpanded;
                                      });
                                    },
                                  )
                                ],
                              ),
                              const SizedBox(height: 20),
                              isAgentExpanded
                                  ? ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: 3,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Text("Agent $index"),
                                    );
                                  })
                                  : Container(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }
              ),
            ),
          ),
        ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            Expanded(
              child: CustomFilledButton(
                backgroundColor: Colors.red,
                text: "Supprimer",
                onPressed: () {
                  // TODO Before deleting a direction, check if there are services and bureaux under it
                  // TODO Display a yesOrNo dialogBox
                  ref.read(directionsControllerProvider.notifier)
                      .delete(widget.directionId);
                  context.pop();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () {
                  context.pop();
                },
                child: const Text("Annuler"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void deleteDirection(Direction) {
    log("deleteDirection");
  }
}
