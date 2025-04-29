import 'dart:developer';

import 'package:arptc_connect/widgets/custom_filledbutton.dart';
import 'package:arptc_connect/widgets/custom_form_field.dart';
import 'package:arptc_connect/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../widgets/content_view.dart';
import '../../../../widgets/page_header.dart';
import '../../data/directions_provider.dart';
import '../../domain/models/direction.dart';

class AddDirectionScreen extends ConsumerStatefulWidget {
  const AddDirectionScreen({super.key});

  @override
  ConsumerState createState() => _AddDirectionScreenState();
}

class _AddDirectionScreenState extends ConsumerState<AddDirectionScreen> {
  TextEditingController directionNameController = TextEditingController();
  TextEditingController abreviationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ContentView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () {
                        context.pop();
                      },
                    ),
                    const Gap(16),
                    const PageHeader(
                      title: 'Créer une direction',
                      description:
                          'Remplissez le formulaire pour créer une nouvelle direction',
                    ),
                  ],
                ),
                const Gap(16),
                ResponsiveCenter(
                  child: Column(
                    children: [
                      CustomFormField(
                        label: "Direction",
                        hintText: "nom de la direction",
                        textInputType: TextInputType.name,
                        controller: directionNameController,
                      ),
                      const Gap(16),
                      CustomFormField(
                        label: "Abreviation",
                        hintText: "l'abréviation de la direction",
                        textInputType: TextInputType.name,
                        controller: abreviationController,
                      ),
                      const Gap(16),
                    ],
                  ),
                ),
                
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            Expanded(
              child: CustomFilledButton(
                onPressed: () {
                  ref.read(directionsControllerProvider.notifier).add(
                        Direction(
                          name: directionNameController.text,
                          shortName: abreviationController.text,
                        ),
                      );
                  context.pop();
                },
                text: "Enregistrer",
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () {
                  log("add_direction_screen:: cancel");
                },
                child: const Text("Annuler",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
