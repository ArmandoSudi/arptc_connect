import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../widgets/content_view.dart';
import '../../../widgets/custom_form_field.dart';
import '../../../widgets/page_header.dart';
import '../models/courrier_model.dart';
import '../providers/courrier_service_provider.dart';
import '../../../extensions/date_extension.dart';

class AddCourrierScreen extends ConsumerStatefulWidget {
  const AddCourrierScreen({super.key});

  @override
  ConsumerState createState() => _AddCourrierScreenState();
}

class _AddCourrierScreenState extends ConsumerState<AddCourrierScreen> {

  TextEditingController senderController = TextEditingController();
  TextEditingController objectController = TextEditingController();
  TextEditingController dateCourrierController = TextEditingController();
  TextEditingController dateReceptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ContentView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Enregistrer un nouveau courrier',
              description: '',
            ),
            const Gap(16),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Expediteur
                    CustomFormField(
                      label: "Expéditeur",
                      hintText: "nom de l'expéditeur",
                      textInputType: TextInputType.name,
                      controller: senderController,
                    ),
                    const SizedBox(height: 20),

                    // Object
                    CustomFormField(
                      label: "Objet",
                      hintText: "object du courrier",
                      textInputType: TextInputType.name,
                      controller: objectController,
                    ),
                    const SizedBox(height: 20),

                    // Courrier entry Date
                    CustomFormField(
                      label: "Date du courrier",
                      hintText: "",
                      textInputType: TextInputType.name,
                      controller: dateCourrierController,
                      enable: true,
                      suffixIcon: Icon(Icons.calendar_month) ,
                      onTap: () async {
                        final DateTime? selectedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );

                        setState(() {
                          dateCourrierController.text = selectedDate!.formatedDate;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Reception Date
                    CustomFormField(
                      label: "Date de la réception",
                      hintText: "",
                      textInputType: TextInputType.name,
                      controller: dateReceptionController,
                      enable: true,
                      suffixIcon: Icon(Icons.calendar_month) ,
                      onTap: () async {
                        final DateTime? selectedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );

                        setState(() {
                          dateReceptionController.text = selectedDate!.formatedDate;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            const Gap(16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () {
                      log("add_courrier_screen:: save");

                      Courrier courrier = Courrier(
                        sender: senderController.text,
                        object: objectController.text,
                        date: DateTime.now(),
                        receptionDate: DateTime.now(),
                        url: "",
                        annotations: [],
                      );

                      ref.read(courrierServiceProvider).addCourrier(
                          courrier
                      );

                      Navigator.of(context).pop();
                    },
                    child: const Text("Enregistrer", style: TextStyle(fontWeight: FontWeight.bold),),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        side: const BorderSide(color: Colors.grey),
                        foregroundColor: Colors.grey),
                    onPressed: () {
                      log("add_courrier_screen:: cancel");

                      Navigator.of(context).pop();
                    },
                    child: const Text("Annuler", style: TextStyle(fontWeight: FontWeight.bold),),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
