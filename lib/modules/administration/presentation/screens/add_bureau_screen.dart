import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../widgets/content_view.dart';
import '../../../../widgets/custom_form_field.dart';
import '../../../../widgets/page_header.dart';
import '../../data/directions_provider.dart';
import '../../data/service_provider.dart';
import 'package:arptc_connect/modules/administration/domain/models/service.dart';

List<String> directions = <String>['DSI', 'DRMT', 'DRAJ', 'DEP'];
List<String> services = <String>[
  'Service Help Desk',
  'Service Infrasctucture',
  'Service Téléphonie & Messagerie'
];

class AddBureauScreen extends ConsumerStatefulWidget {
  const AddBureauScreen({Key? key}) : super(key: key);

  @override
  ConsumerState createState() => _AddBureauScreenState();
}

class _AddBureauScreenState extends ConsumerState<AddBureauScreen> {
  TextEditingController serviceNameController = TextEditingController();
  TextEditingController abreviationController = TextEditingController();

  var directionDropDownValue = directions.first;
  var serviceDropdownValue = services.first;

  String? selectedDirectionId, selectedServiceId;

  @override
  Widget build(BuildContext context) {
    final directionsAsync = ref.watch(directionsControllerProvider);
    final serviceAsync = ref.watch(asyncServiceProvider);

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
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () {
                        context.pop();
                      },
                    ),
                    const Gap(16),
                    const PageHeader(
                      title: 'Enregistrer un bureau',
                      description: 'formulaire d\'enregistrement de bureau',
                    ),
                  ],
                ),
                const Gap(16),

                // DIRECTION DROPDOWN
                directionsAsync.when(
                  data: (data) {
                    if (data.isEmpty) {
                      return Container();
                    }

                    selectedDirectionId = data.first.id!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Direction",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            hintText: "hint text",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(5),
                              ),
                            ),
                            // suffixIcon: Icon(Icons.arrow_drop_down)
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down_outlined),
                          isExpanded: true,
                          value: data.first.id,
                          items:
                              data.map<DropdownMenuItem<String>>((direction) {
                            return DropdownMenuItem<String>(
                              value: direction.id,
                              child: Text(direction.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            selectedDirectionId = value!;
                          },
                        ),
                      ],
                    );
                  },
                  error: (error, stackTrace) {
                    debugPrint("Error: $error");
                    debugPrint("StackTrace: $stackTrace");
                    return const Text("something went wrong");
                  },
                  loading: () => const CircularProgressIndicator(),
                ),
                const SizedBox(height: 20),

                // SERVICES DROPDOWN
                serviceAsync.when(
                  data: (data) {
                    if (data.isEmpty) {
                      return Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Services"),
                            DropdownButtonFormField<Service>(
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                hintText: "hint text",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(5),
                                  ),
                                ),
                              ),
                              isExpanded: true,
                              // value: data.first,
                              items: const [
                                DropdownMenuItem<Service>(
                                  value: null,
                                  child: Text("Aucun service trouvé"),
                                )
                              ],
                              onChanged: (value) {
                              },
                            ),
                          ],
                        ),
                      );
                    }

                    selectedServiceId = data.first.id!;

                    return Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Services"),
                          DropdownButtonFormField<Service>(
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              hintText: "hint text",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(5),
                                ),
                              ),
                              // suffixIcon: Icon(Icons.arrow_drop_down)
                            ),
                            icon: const Icon(
                                Icons.keyboard_arrow_down_outlined),
                            isExpanded: true,
                            value: data.first,
                            items: data
                                .map<DropdownMenuItem<Service>>((service) {
                              return DropdownMenuItem<Service>(
                                value: service,
                                child: Text(service.name),
                              );
                            }).toList(),
                            onChanged: (value) {

                              serviceDropdownValue = value!.name;
                            },
                          )
                        ],
                      ),
                    );
                  },
                  error: (error, stackTrace) {
                    debugPrint("Error: $error");
                    debugPrint("StackTrace: $stackTrace");
                    return const Text("something went wrong");
                  },
                  loading: () => const Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text("Services"),
                          ],
                        ),
                        CircularProgressIndicator()
                      ],
                    ),
                  ),
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
                        child: const Text("Enregistrer",
                            style: TextStyle(fontWeight: FontWeight.bold)),
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
                        child: const Text("Annuler",
                            style: TextStyle(fontWeight: FontWeight.bold)),
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
