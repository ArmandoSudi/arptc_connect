import 'dart:developer';

import 'package:arptc_connect/widgets/custom_form_field.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/content_view.dart';
import '../../../widgets/page_header.dart';

class AddDirectionScreen extends StatefulWidget {
  const AddDirectionScreen({Key? key}) : super(key: key);

  @override
  State<AddDirectionScreen> createState() => _AddDirectionScreenState();
}

class _AddDirectionScreenState extends State<AddDirectionScreen> {
  TextEditingController directionNameController = TextEditingController();
  TextEditingController abreviationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
          child: ContentView(
            child: Stack(children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(icon:Icon(Icons.arrow_back_ios), onPressed: () {
                          context.pop();
                        },),
                        const Gap(16),
                        const PageHeader(
                          title: 'Créer une direction',
                          description: 'Remplissez le formulaire pour créer une nouvelle direction',
                        ),
                      ],
                    ),
                    const Gap(16),
                    CustomFormField(
                      label: "Direction",
                      hintText: "nom de la direction",
                      textInputType: TextInputType.name,
                      controller: directionNameController,
                    ),
                    const SizedBox(height: 20),
                    CustomFormField(
                      label: "Abreviation",
                      hintText: "l'abréviation de la direction",
                      textInputType: TextInputType.name,
                      controller: abreviationController,
                    ),
                    Gap(16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              shape: const StadiumBorder(),
                            ),
                            onPressed: () {
                              log("add_direction_screen:: save");
                            },
                            child: const Text("Enregistrer", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.grey),
                                minimumSize: const Size.fromHeight(50),
                                foregroundColor: Colors.grey),
                            onPressed: () {
                              log("add_direction_screen:: cancel");
                            },
                            child: const Text("Annuler", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ));
  }
}
