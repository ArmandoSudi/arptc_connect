
import 'package:arptc_connect/extensions/date_extension.dart';
import 'package:arptc_connect/modules/administration/data/bureau_provider.dart';
import 'package:arptc_connect/modules/administration/data/directions_provider.dart';
import 'package:arptc_connect/modules/administration/data/providers.dart';
import 'package:arptc_connect/modules/administration/data/service_provider.dart';
import 'package:arptc_connect/modules/administration/domain/models/agent.dart';
import 'package:arptc_connect/modules/administration/domain/models/direction.dart';
import 'package:arptc_connect/modules/administration/domain/models/service.dart';
import 'package:arptc_connect/modules/authentication/providers/authentication_provider.dart';
import 'package:arptc_connect/widgets/custom_filledbutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../widgets/content_view.dart';
import '../../../../widgets/custom_form_field.dart';
import '../../../../widgets/page_header.dart';

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

  late String serviceDropdownValue, bureauDropdownValue;
  late String selectedGenre;
  late DateTime dobDate;
  late DateTime dateEngagement;

  @override
  Widget build(BuildContext context) {
    print("BUILDING THE ENTIRE WIDGET");

    final directionsAsync = ref.watch(directionsControllerProvider);
    final serviceAsync = ref.watch(asyncServiceProvider);
    final bureauAsync = ref.watch(bureauControllerProvider);

    return Scaffold(
      body: ContentView(
        child: Column(children: [
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
                          suffixIcon: const Icon(Icons.calendar_month),
                          controller: dobController,
                          onTap: () async {
                            dobDate = (await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1940),
                              lastDate: DateTime.now(),
                            ))!;

                            setState(() {
                              dobController.text = dobDate.formatedDate;
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
                          suffixIcon: const Icon(Icons.calendar_month),
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
                                  dateEngagement.formatedDate;
                            });
                          },
                        ),
                      ),
                      const Gap(24),

                      // SEXE DROPDOWN
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 5),
                              child: Text("Sexe"),
                            ),
                            DropdownButtonFormField<String>(
                              hint: const Text("m"),
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
                              value: genres.first,
                              items:
                                  genres.map<DropdownMenuItem<String>>((genre) {
                                print("Dropdown menuitem value $genre");
                                return DropdownMenuItem<String>(
                                  value: genre,
                                  child: Text(genre),
                                );
                              }).toList(),
                              onChanged: (value) {
                                selectedGenre = value!;
                              },
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const Gap(16),

                  Row(
                    children: [
                      // DIRECTIONS DROPDOWN
                      directionsAsync.when(
                        data: (data) {
                          if (data.isEmpty) {
                            return Container();
                          }
                          return Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Directions"),
                                DropdownButtonFormField<Direction>(
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
                                  items: data.map<DropdownMenuItem<Direction>>(
                                      (direction) {
                                    return DropdownMenuItem<Direction>(
                                      value: direction,
                                      child: Text(direction.name),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    print("Selected direction is : $value");
                                    ref
                                        .read(
                                            selectedDirectionProvider.notifier)
                                        .state = value!.id!;

                                    directionDropdownValue = value.name;

                                    ref
                                        .read(selectedServiceProvider.notifier)
                                        .state = "";
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                        error: (error, stackTrace) {
                          debugPrint("Error: $error");
                          debugPrint("StackTrace: $stackTrace");
                          return const Text("something went wrong");
                        },
                        loading: () => const CircularProgressIndicator(),
                      ),
                      const Gap(16),

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
                                      // ref
                                      //     .read(
                                      //         selectedServiceProvider.notifier)
                                      //     .state = value!.id!;
                                    },
                                  ),
                                ],
                              ),
                            );
                          }
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
                                    ref
                                        .read(selectedServiceProvider.notifier)
                                        .state = value!.id!;

                                    serviceDropdownValue = value.name;
                                  },
                                ),
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
                      const Gap(16),

                      // BUREAUX DROPDOWN
                      bureauAsync.when(
                        data: (data) {
                          if (data.isEmpty) {
                            return Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Bureaux"),
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
                                    ),
                                    isExpanded: true,
                                    value: "aucun",
                                    items: const [
                                      DropdownMenuItem<String>(
                                        value: "aucun",
                                        child: Text("Aucun bureau trouve"),
                                      )
                                    ],
                                    onChanged: (value) {
                                      ref
                                          .read(
                                              selectedServiceProvider.notifier)
                                          .state = value!;
                                    },
                                  ),
                                ],
                              ),
                            );
                          }
                          return Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Bureaux"),
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
                                  ),
                                  icon: const Icon(
                                      Icons.keyboard_arrow_down_outlined),
                                  isExpanded: true,
                                  value: data.first.id,
                                  items: data.map<DropdownMenuItem<String>>(
                                      (direction) {
                                    return DropdownMenuItem<String>(
                                      value: direction.id,
                                      child: Text(direction.name),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    bureauDropdownValue = value!;
                                  },
                                ),
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
                    ],
                  ),
                  const Gap(16),
                ],
              ),
            ),
          ),
          const Gap(16),
        ]),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            Expanded(
              child: CustomFilledButton(
                text: "Enregistrer",
                onPressed: () {
                  registerAgent();
                  context.pop();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () {
                  context.pop();
                },
                child: const Text("Annuler"),
              ),
            ),
          ],
        ),
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
      roles: ['DSI'],
    );
  }

  void registerAgent() {
    Agent agent = getAgent();
    ref
        .read(authServiceProvider)
        .createAgent(agent);
  }

  void signupWithEmailAndPassword(String email, String password) async {
    ref
        .read(authServiceProvider)
        .signInWithEmailAndPassword(email, password, context);
  }
}
