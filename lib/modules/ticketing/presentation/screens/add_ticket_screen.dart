import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/custom_filledbutton.dart';
import 'package:arptc_connect/widgets/custom_form_field.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:arptc_connect/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/shared_preferences_provider.dart';
import '../../../../widgets/custom_dropdown_field.dart';
import '../../domain/ticket.dart';
import '../controllers/async_ticket.dart';

class AddTicketScreen extends ConsumerStatefulWidget {
  const AddTicketScreen({super.key});

  @override
  ConsumerState createState() => _AddTicketScreenState();
}

class _AddTicketScreenState extends ConsumerState<AddTicketScreen> {
  TextEditingController agentNameTEC = TextEditingController();
  TextEditingController subjectTEC = TextEditingController();
  TextEditingController solutionTEC = TextEditingController();

  final categories = [
    "Internet",
    "Imprimante ou autre péripherie ",
    "Cosap",
    "Mail",
    "Téléphonie IP",
    "Autre assistance IT"
  ];
  String selectedCategory = "Informatique";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ContentView(
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
                  title: 'Enregistrer un ticket',
                  description: 'formulaire d\'enregistrement de ticket',
                ),
                const Gap(16),
              ],
            ),
            const Gap(16),
            ResponsiveCenter(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Gap(16),

                    // AGENT NAME FIELD
                    CustomFormField(
                      label: "Demandeur",
                      hintText: "nom de l'agent demandeur",
                      textInputType: TextInputType.name,
                      controller: agentNameTEC,
                    ),
                    const Gap(24),

                    // CATEGORY FIELD
                    CustomDropDown(
                      label: "Catégorie de l'incident",
                      hintText: "Sélectionner la catégorie",
                      items: categories,
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value!;
                        });
                      },
                    ),
                    const Gap(24),

                    // SUBJECT FIELD
                    CustomFormField(
                      label: "Incident",
                      hintText:
                          "Quel est le problème que l'agent a rencontré ?",
                      textInputType: TextInputType.name,
                      controller: subjectTEC,
                      maxLine: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () {
                  context.pop();
                },
                child: const Text("Annuler"),
              ),
            ),
            const Gap(16),
            Expanded(
              child: CustomFilledButton(
                  onPressed: () {
                    saveTicket();
                    context.pop();
                  },
                  text: "Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }

  // create a ticket object from the form fields

  void saveTicket() async {
    String agentName = agentNameTEC.text;
    String subject = subjectTEC.text;
    String email = await ref.watch(sharedPrefUtilityProvider).getEmail();

    DateTime creationDate = DateTime.now();

    final ticket = Ticket(
      author: email,
      agent: agentName,
      category: selectedCategory,
      subject: subject,
      solution: null,
      creationDate: creationDate,
      isSolved: false,
    );

    ref.read(asyncTicketProvider.notifier).addTicket(ticket);
  }
}
