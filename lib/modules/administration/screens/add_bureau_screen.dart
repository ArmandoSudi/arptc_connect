import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/content_view.dart';
import '../../../widgets/custom_form_field.dart';
import '../../../widgets/page_header.dart';

List<String> directions = <String>['DSI', 'DRMT', 'DRAJ', 'DEP'];
List<String> services = <String>['Service Help Desk', 'Service Infrasctucture', 'Service Téléphonie & Messagerie'];

class AddBureauScreen extends StatefulWidget {
  const AddBureauScreen({Key? key}) : super(key: key);

  @override
  State<AddBureauScreen> createState() => _AddBureauScreenState();
}

class _AddBureauScreenState extends State<AddBureauScreen> {

  TextEditingController serviceNameController = TextEditingController();
  TextEditingController abreviationController = TextEditingController();

  var directionDropDownValue = directions.first;
  var serviceDropdownValue = services.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: ContentView(
          child: SafeArea(
            child: Stack(children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(icon:Icon(Icons.arrow_back_ios), onPressed: () {
                          context.pop();
                        },),
                        const Gap(16),
                        const PageHeader(
                          title: 'Enregistrer un bureau',
                          description: 'formulaire d\'enregistrement de bureau',
                        ),
                      ],
                    ),
                    const Gap(16),
                    Text(
                        "Direction",
                        style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                    DropdownMenu(
                      width: MediaQuery.of(context).size.width - 16,
                      inputDecorationTheme: InputDecorationTheme(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      initialSelection: directions.first,
                      onSelected: (String? value) {
                        // This is called when the user selects an item.
                        setState(() {
                          directionDropDownValue = value!;
                        });
                      },
                      dropdownMenuEntries: directions.map<DropdownMenuEntry<String>>((String value) {
                        return DropdownMenuEntry<String>(value: value, label: value);
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                        "Service",
                        style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                    DropdownMenu(
                      width: MediaQuery.of(context).size.width - 16,
                      inputDecorationTheme: InputDecorationTheme(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      initialSelection: services.first,
                      onSelected: (String? value) {
                        // This is called when the user selects an item.
                        setState(() {
                          serviceDropdownValue = value!;
                        });
                      },
                      dropdownMenuEntries: services.map<DropdownMenuEntry<String>>((String value) {
                        return DropdownMenuEntry<String>(value: value, label: value);
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    CustomFormField(
                      label: "Service",
                      hintText: "nom du service",
                      textInputType: TextInputType.name,
                      controller: serviceNameController,
                    ),
                    const SizedBox(height: 20),
                    CustomFormField(
                      label: "Abreviation",
                      hintText: "l'abréviation du service",
                      textInputType: TextInputType.name,
                      controller: abreviationController,
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
