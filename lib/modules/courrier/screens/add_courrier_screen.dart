import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/custom_form_field.dart';
import '../models/courrier_model.dart';
import '../providers/courrier_service_provider.dart';

class AddCourrierScreen extends ConsumerStatefulWidget {
  const AddCourrierScreen({super.key});

  @override
  ConsumerState createState() => _AddCourrierScreenState();
}

class _AddCourrierScreenState extends ConsumerState<AddCourrierScreen> {

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
                  label: "Expéditeur",
                  hintText: "nom de l'expéditeur",
                  textInputType: TextInputType.name,
                  controller: senderController,
                ),
                const SizedBox(height: 20),
                CustomFormField(
                  label: "Objet",
                  hintText: "object du courrier",
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
                          log("add_courrier_screen:: save");

                          Courrier courrier = Courrier(
                              sender: senderController.text,
                              object: objectController.text,
                            date: DateTime.now(),
                            url: "",
                            annotations: [],
                          );

                          ref.read(courrierServiceProvider).addCourrier(
                            courrier
                          );

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
                          log("add_courrier_screen:: cancel");

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
