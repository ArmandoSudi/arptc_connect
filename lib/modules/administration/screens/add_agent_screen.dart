import 'dart:developer';

import 'package:arptc_connect/extensions/date_extension.dart';
import 'package:arptc_connect/modules/administration/providers/service_provider.dart';
import 'package:arptc_connect/modules/authentication/providers/authentication_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../models/agent.dart';
import '../../../models/direction.dart';
import '../../../models/service.dart';
import '../../../widgets/content_view.dart';
import '../../../widgets/custom_form_field.dart';
import '../../../widgets/page_header.dart';
import '../providers/administration_api_provider.dart';
import '../providers/bureau_provider.dart';
import '../providers/directions_provider.dart';
import '../providers/providers.dart';

class AddAgentScreen extends ConsumerStatefulWidget {
  const AddAgentScreen({super.key});

  @override
  ConsumerState createState() => _AddAgentScreenState();
}

class _AddAgentScreenState extends ConsumerState<AddAgentScreen> {
  TextEditingController serviceNameController = TextEditingController();
  TextEditingController dateEngagementController = TextEditingController();
  TextEditingController matriculeController = TextEditingController();
  TextEditingController nomController = TextEditingController();
  TextEditingController postNomController = TextEditingController();
  TextEditingController prenomController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController numeroTelephoneController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController genreController = TextEditingController();

  List<String> genres = ["Masculin", "Feminin"];
  List<Direction> dir = [];
  List<Service> services = [];
  String directionDropdownValue = '';

  late String serviceDropdownValue;

  late String selectedGenre;
  late DateTime dobDate;
  late DateTime dateEngagement;

  @override
  Widget build(BuildContext context) {
    print("BUILDING THE ENTIRE WIDGET");

    final serviceState =
        ref.watch(asyncServiceProvider(directionDropdownValue));
    final bureauState = ref.watch(bureauControllerProvider);
    final directionsAsync = ref.watch(directionsControllerProvider);

    return Scaffold(
      body: ContentView(
        child: Column(children: [
          Row(
            children: [
              IconButton(icon:Icon(Icons.arrow_back_ios), onPressed: () {
                context.pop();
              },),
              const Gap(16),
              const PageHeader(
                title: 'Enregistrer un agent',
                description: 'formulaire d\'enregistrement d\'agent',
              ),
            ],
          ),
          const Gap(16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(16),

                  // AGENT IDENTITY FIELDS
                  Row(
                    children: [
                      Expanded(
                        child: CustomFormField(
                          label: "Nom",
                          hintText: "Nom de l'agent",
                          textInputType: TextInputType.name,
                          controller: nomController,
                        ),
                      ),
                      const Gap(24),
                      Expanded(
                        child: CustomFormField(
                          label: "Post Nom",
                          hintText: "Post-nom de l'agent",
                          textInputType: TextInputType.name,
                          controller: postNomController,
                        ),
                      ),
                      const Gap(24),
                      Expanded(
                        child: CustomFormField(
                          label: "Prénom",
                          hintText: "Prénom de l'agent",
                          textInputType: TextInputType.name,
                          controller: prenomController,
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),

                  // AGENT CONTACT FIELDS
                  Row(
                    children: [
                      Expanded(
                        child: CustomFormField(
                          label: "Email",
                          hintText: "l'email professionel de l'agent",
                          textInputType: TextInputType.name,
                          controller: emailController,
                        ),
                      ),
                      const Gap(24),
                      Expanded(
                        child: CustomFormField(
                          label: "Numéro de téléphone",
                          hintText: "Numéro de téléphone de l'agent",
                          textInputType: TextInputType.name,
                          controller: numeroTelephoneController,
                        ),
                      ),
                      const Gap(24),
                      Expanded(
                        child: CustomFormField(
                          label: "Date de naissance",
                          hintText: "Date de naissance de l'agent",
                          textInputType: TextInputType.name,
                          suffixIcon: Icon(Icons.calendar_month),
                          controller: dobController,
                          onTap: () async {
                            dobDate = (await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1940),
                              lastDate: DateTime.now(),
                            ))!;

                            setState(() {
                              dobController.text = dobDate!.formatedDate;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),

                  // AGENT
                  Row(
                    children: [
                      Expanded(
                        child: CustomFormField(
                          label: "Matricule",
                          hintText: "Le numéro matricule de l'agent",
                          textInputType: TextInputType.name,
                          controller: matriculeController,
                        ),
                      ),
                      const Gap(24),
                      Expanded(
                        child: CustomFormField(
                          label: "Date d'engagement",
                          hintText: "Date d'engagement de l'agent",
                          textInputType: TextInputType.name,
                          suffixIcon: Icon(Icons.calendar_month),
                          controller: dateEngagementController,
                          onTap: () async {
                            dateEngagement = (await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2002),
                              lastDate: DateTime.now(),
                            ))!;

                            setState(() {
                              dateEngagementController.text =
                                  dateEngagement!.formatedDate;
                            });
                          },
                        ),
                      ),
                      const Gap(24),
                      Expanded(
                        child: DropdownMenu<String>(
                          initialSelection: genres.first,
                          controller: genreController,
                          label: const Text('Genre'),
                          dropdownMenuEntries: genres
                              .map<DropdownMenuEntry<String>>((String value) {
                            return DropdownMenuEntry<String>(
                                value: value, label: value);
                          }).toList(),
                          onSelected: (String? genre) {
                            setState(() {
                              selectedGenre = genre!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),


                  const SizedBox(height: 20),

                  // DIRECTION DROPDOWN MENU
                  StreamBuilder<List<Direction>>(
                      stream: ref
                          .watch(administrationAPIProvider)
                          .allDirections(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Text("something went wrong");
                        }

                        if (snapshot.data == null ||
                            snapshot.connectionState ==
                                ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (!snapshot.hasData) {
                          return const Text("There is no direction yet");
                        }

                        dir = snapshot.data ?? [];

                        return DropdownMenu(
                          label: const Text("Directions"),
                          initialSelection: ref.read(selectedDirectionProvider),
                          onSelected: (String? value) {
                            setState(() {
                              directionDropdownValue = value!;
                            });

                            ref.read(selectedDirectionProvider.notifier).state =
                                value!;
                          },
                          dropdownMenuEntries: dir
                              .map<DropdownMenuEntry<String>>(
                                  (Direction value) {
                            return DropdownMenuEntry<String>(
                                value: value.id!, label: value.name);
                          }).toList(),
                        );
                      }),
                  const Gap(16),

                  // SERVICE DROPDOWN MENU
                  serviceState.when(
                      data: (data) {
                        print("Services length : ${data.length}");

                        if (data.isEmpty) {
                          return DropdownMenu(
                              label: const Text("Service"),
                              initialSelection: "No service",
                              onSelected: (String? value) {
                                // serviceDropdownValue = value!;
                              },
                              dropdownMenuEntries: const [
                                DropdownMenuEntry<String>(
                                  value: "No service",
                                  label: "No service",
                                )
                              ]);
                        }

                        return DropdownMenu(
                          label: const Text("Service"),
                          initialSelection: ref.read(selectedServiceProvider),
                          onSelected: (String? value) {
                            serviceDropdownValue = value!;

                            ref.read(selectedServiceProvider.notifier).state =
                                value!;
                          },
                          dropdownMenuEntries: data
                              .map<DropdownMenuEntry<String>>((Service value) {
                            return DropdownMenuEntry<String>(
                              value: value.id!,
                              label: value.name,
                            );
                          }).toList(),
                        );
                      },
                      error: (error, stackTrace) {
                        return const Text("something went wrong");
                      },
                      loading: () => const CircularProgressIndicator()),


                  const Gap(16),

                  // BUREAU DROP DOWN MENU

                  bureauState.when(
                    data: (data) {
                      print("Bureau length : ${data.length}");

                      if (data.isEmpty) {
                        return DropdownMenu(
                            label: const Text("Bureau"),
                            initialSelection: "No Bureau",
                            onSelected: (String? value) {
                              // serviceDropdownValue = value!;
                            },
                            dropdownMenuEntries: const [
                              DropdownMenuEntry<String>(
                                value: "No Bureau",
                                label: "No Bureau",
                              )
                            ]);
                      }

                      return DropdownMenu(
                        label: const Text("Bureau"),
                        initialSelection: ref.read(selectedBureauProvider),
                        onSelected: (String? value) {
                          setState(() {
                            directionDropdownValue = value!;
                          });

                          ref.read(selectedBureauProvider.notifier).state =
                          value!;
                        },
                        dropdownMenuEntries: data
                            .map<DropdownMenuEntry<String>>((Service value) {
                          return DropdownMenuEntry<String>(
                            value: value.id!,
                            label: value.name,
                          );
                        }).toList(),
                      );
                    },
                    error: (error, stackTrace) {
                      debugPrint("Error: $error");
                      debugPrint("StackTrace: $stackTrace");
                      return const Text("something went wrong");
                    },
                    loading: () => const CircularProgressIndicator(),
                  )

                ],
              ),
            ),
          ),
          const Gap(16),

          // CTA FIELDS (SAVE AND CANCEL)
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () {
                    signupWithEmailAndPassword(
                        emailController.text, "Arptc@2021");
                  },
                  child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold)),
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
                    log("add_agent_screen:: Cancel");

                    context.pop();
                  },
                  child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ]),
      ),
    );
  }

  Agent getAgent() {
    return Agent(
      name: nomController.text,
      email: emailController.text,
      dob: dobDate.formatedDate,
      matricule: matriculeController.text,
      genre: selectedGenre,
      direction: directionDropdownValue,
      service: directionDropdownValue,
      bureau: directionDropdownValue,
      category: '',
      roles: [],
    );
  }

  void signupWithEmailAndPassword(String email, String password) async {
    ref
        .read(authServiceProvider)
        .signUpWithEmailAndPassword(email, password, context);
  }
}
