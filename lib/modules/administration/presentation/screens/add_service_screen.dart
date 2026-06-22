import 'package:arptc_connect/modules/administration/data/service_provider.dart';
import 'package:arptc_connect/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../widgets/content_view.dart';
import '../../../../widgets/custom_filledbutton.dart';
import '../../../../widgets/common_text_input.dart';
import '../../../../widgets/page_header.dart';
import '../../data/directions_provider.dart';
import '../../domain/models/service.dart';

class AddServiceScreen extends ConsumerStatefulWidget {
  const AddServiceScreen({super.key});

  @override
  ConsumerState createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends ConsumerState<AddServiceScreen> {
  TextEditingController directionNameController = TextEditingController();
  TextEditingController abreviationController = TextEditingController();

  String? directionId;

  @override
  Widget build(BuildContext context) {
    final directionsAsync = ref.watch(directionsControllerProvider);

    return Scaffold(
      body: ContentView(
        child: SafeArea(
          child: Stack(
            children: [
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
                          title: 'Créer un service',
                          description:
                              'Remplissez le formulaire pour créer un nouveau service dans une direction donnée',
                        ),
                      ],
                    ),
                    const Gap(16),
                    ResponsiveCenter(
                      child: Column(
                        children: [
                          // DIRECTIONS DROPDOWN
                          directionsAsync.when(
                            data: (data) {
                              if (data.isEmpty) {
                                return Container();
                              }

                              directionId = data.first.id!;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Directions",
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
                                      directionId = value!;
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
                          const Gap(16),

                          // SERVICE NAME
                          CommonTextInput(
                            label: "Service",
                            hintText: "nom du service",
                            type: CommonTextInputType.name,
                            controller: directionNameController,
                          ),
                          const SizedBox(height: 20),

                          // SERVICE SHORT NAME
                          CommonTextInput(
                            label: "Abreviation",
                            hintText: "l'abréviation du service",
                            type: CommonTextInputType.name,
                            controller: abreviationController,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            Expanded(
              child: CustomFilledButton(
                text: "Enregistrer",
                onPressed: () {
                  createService();
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

  void createService() {
    final service = Service(
      name: directionNameController.text,
      directionRef: directionId!,
    );
    ref.read(asyncServiceProvider.notifier).add(service);
  }
}
