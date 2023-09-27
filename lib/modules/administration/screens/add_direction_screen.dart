import 'dart:developer';

import 'package:arptc_connect/widgets/custom_form_field.dart';
import 'package:flutter/material.dart';

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
        appBar: AppBar(
          title: const Text("Add direction"),
        ),
        body: SafeArea(
          child: Stack(children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
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
