import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/custom_form_field.dart';
import '../providers/courrier_service_provider.dart';

class AddAnnotationScreen extends ConsumerStatefulWidget {

  String courrierId;

  AddAnnotationScreen({required this.courrierId, super.key});

  @override
  ConsumerState createState() => _AddAnnotationScreenState();
}

class _AddAnnotationScreenState extends ConsumerState<AddAnnotationScreen> {

  TextEditingController senderController = TextEditingController();
  TextEditingController objectController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Enregistrer un nouveau courrier"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            width: 800,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                CustomFormField(
                  label: "Destinataire",
                  hintText: "nom de l'agent désigné",
                  textInputType: TextInputType.name,
                  controller: senderController,
                ),
                const SizedBox(height: 20),
                CustomFormField(
                  label: "Objet",
                  hintText: "object du l'annotation",
                  textInputType: TextInputType.name,
                  controller: objectController,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          // minimumSize: const Size.fromHeight(50),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () {
                          log("add_annotation_screen:: save");

                          Map<String, String> annotation = {
                            "entity": senderController.text,
                            "object": objectController.text,
                          };

                          ref.read(courrierServiceProvider)
                              .addAnnotationToCourrier(widget.courrierId, annotation);

                          Navigator.of(context).pop();
                        },
                        child: const Text("Enregistrer"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            foregroundColor: Colors.grey),
                        onPressed: () {
                          log("add_annotation_screen:: cancel");

                          Navigator.of(context).pop();
                        },
                        child: const Text("Annuler"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
