import 'dart:developer';

import 'package:arptc_connect/extensions/date_extension.dart';
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
import '../providers/administration_service_provider.dart';



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
  late String directionDropdownValue ;
  late String selectedGenre;
  late DateTime dobDate;
  late DateTime dateEngagement;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: ContentView(
        child: Column(children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PageHeader(
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
                          suffixIcon: Icon(Icons.calendar_month) ,
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
                          suffixIcon: Icon(Icons.calendar_month) ,
                          controller: dateEngagementController,
                          onTap: () async {
                            dateEngagement = (await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2002),
                              lastDate: DateTime.now(),
                            ))!;

                            setState(() {
                              dateEngagementController.text = dateEngagement!.formatedDate;
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
                          dropdownMenuEntries: genres.map<DropdownMenuEntry<String>>((String value) {
                            return DropdownMenuEntry<String>(value: value, label: value);
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
                  // Text(
                  //     "Direction",
                  //     style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  // DropdownMenu(
                  //   width: MediaQuery.of(context).size.width - 16,
                  //   inputDecorationTheme: InputDecorationTheme(
                  //     border: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(5),
                  //     ),
                  //     contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  //   ),
                  //   initialSelection: directions.first,
                  //   onSelected: (String? value) {
                  //     // This is called when the user selects an item.
                  //     setState(() {
                  //       directionDropDownValue = value!;
                  //     });
                  //   },
                  //   dropdownMenuEntries: directions.map<DropdownMenuEntry<String>>((String value) {
                  //     return DropdownMenuEntry<String>(value: value, label: value);
                  //   }).toList(),
                  // ),
                  const SizedBox(height: 20),
                  // Text(
                  //     "Service",
                  //     style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  // DropdownMenu(
                  //   width: MediaQuery.of(context).size.width - 16,
                  //   inputDecorationTheme: InputDecorationTheme(
                  //     border: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(5),
                  //     ),
                  //     contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  //   ),
                  //   initialSelection: services.first,
                  //   onSelected: (String? value) {
                  //     // This is called when the user selects an item.
                  //     setState(() {
                  //       serviceDropdownValue = value!;
                  //     });
                  //   },
                  //   dropdownMenuEntries: services.map<DropdownMenuEntry<String>>((String value) {
                  //     return DropdownMenuEntry<String>(value: value, label: value);
                  //   }).toList(),
                  // ),
                  const SizedBox(height: 20),
                  StreamBuilder<List<Direction>>(
                    stream: ref.watch(administrationServiceProvider).allDirections(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Text("something went wrong");
                      }

                      if (snapshot.data == null ||
                          snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (!snapshot.hasData) {
                        return const Text("There is no direction yet");
                      }

                      dir = snapshot.data ?? [];

                      return DropdownMenu(
                        // width: MediaQuery.of(context).size.width - 16,

                        // inputDecorationTheme: InputDecorationTheme(
                        //   border: OutlineInputBorder(
                        //     borderRadius: BorderRadius.circular(5),
                        //   ),
                        //   contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        // ),
                        label: Text("Direction"),
                        initialSelection: dir.first.name,
                        onSelected: (String? value) {
                          directionDropdownValue = value!;
                        },
                        dropdownMenuEntries: dir.map<DropdownMenuEntry<String>>((Direction value) {
                          return DropdownMenuEntry<String>(value: value.name, label: value.name);
                        }).toList(),
                      );
                    }
                  ),
                  const Gap(16),
                  StreamBuilder<List<Service>>(
                      stream: ref.watch(administrationServiceProvider).allServices(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Text("something went wrong");
                        }

                        if (snapshot.data == null ||
                            snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (!snapshot.hasData) {
                          return const Text("There is no direction yet");
                        }

                        services = snapshot.data ?? [];

                        return DropdownMenu(
                          // width: MediaQuery.of(context).size.width - 16,
                          // inputDecorationTheme: InputDecorationTheme(
                          //   border: OutlineInputBorder(
                          //     borderRadius: BorderRadius.circular(5),
                          //   ),
                          //   contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          // ),
                          label: Text("Service"),
                          initialSelection: services.first.name,
                          onSelected: (String? value) {
                            directionDropdownValue = value!;
                          },
                          dropdownMenuEntries: services.map<DropdownMenuEntry<String>>((Service value) {
                            return DropdownMenuEntry<String>(value: value.name, label: value.name);
                          }).toList(),
                        );
                      }
                  ),
                  const Gap(16),
                  StreamBuilder<List<Direction>>(
                      stream: ref.watch(administrationServiceProvider).allDirections(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Text("something went wrong");
                        }

                        if (snapshot.data == null ||
                            snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (!snapshot.hasData) {
                          return const Text("There is no direction yet");
                        }

                        dir = snapshot.data ?? [];

                        return DropdownMenu(
                          // width: 200,
                          // inputDecorationTheme: InputDecorationTheme(
                          //   border: OutlineInputBorder(
                          //     borderRadius: BorderRadius.circular(5),
                          //   ),
                          //   contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          // ),
                          label: Text("Bureau"),
                          initialSelection: dir.first.name,
                          onSelected: (String? value) {
                            directionDropdownValue = value!;
                          },
                          dropdownMenuEntries: dir.map<DropdownMenuEntry<String>>((Direction value) {
                            return DropdownMenuEntry<String>(value: value.name, label: value.name);
                          }).toList(),
                        );
                      }
                  ),
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
                    signupWithEmailAndPassword(emailController.text, "Arptc@2021");
                  },
                  child: const Text("Save"),
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
                  child: const Text("Cancel"),
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
    ref.read(authServiceProvider).signUpWithEmailAndPassword(email, password, context);
  }
}


