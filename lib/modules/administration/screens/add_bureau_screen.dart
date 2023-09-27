import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../widgets/custom_form_field.dart';

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
        appBar: AppBar(
          title: const Text("add bureau"),
        ),
        body: SafeArea(
          child: Stack(children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              right: 10,
              left: 10,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        // minimumSize: const Size.fromHeight(50),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {
                        log("add_direction_screen:: save");
                      },
                      child: const Text("Save"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          foregroundColor: Colors.grey),
                      onPressed: () {
                        log("add_direction_screen:: cancel");
                      },
                      child: const Text("Cancel"),
                    ),
                  ),
                ],
              ),
            )
          ]),
        ));
  }
}
