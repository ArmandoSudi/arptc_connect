import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/custom_filledbutton.dart';
import 'package:arptc_connect/widgets/custom_form_field.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

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
            Card(
              clipBehavior: Clip.antiAlias,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Gap(16),

                    // AGENT NAME FIELD
                    CustomFormField(
                      label: "Nom",
                      hintText: "nom de l'agent",
                      textInputType: TextInputType.name,
                      controller: agentNameTEC,
                    ),
                    const Gap(24),

                    // SUBJECT FIELD
                    CustomFormField(
                      label: "Objet",
                      hintText: "object de l'intervention",
                      textInputType: TextInputType.name,
                      controller: subjectTEC,
                      maxLine: 2,
                    ),
                    const Gap(24),

                    // SOLUTION FIELD
                    CustomFormField(
                      label: "Solution",
                      hintText: "solution trouvée",
                      textInputType: TextInputType.name,
                      controller: solutionTEC,
                      maxLine: 4,
                    ),
                    const Gap(16),
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
              child: CustomFilledButton(
                onPressed: () {
                  saveTicket();
                  context.pop();
                },
                text: "Enregistrer"
              ),
            ),
            const Gap(16),
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
          ],
        ),
      ),
    );
  }

  // create a ticket object from the form fields

  void saveTicket() {
    String agentName = agentNameTEC.text;
    String subject = subjectTEC.text;
    String solution = solutionTEC.text;

    DateTime creationDate = DateTime.now();
    DateTime closingDate = DateTime.now();

    final ticket = Ticket(
      author: "Auteur",
      agent: agentName,
      subject: subject,
      solution: solution,
      creationDate: creationDate,
      closingDate: closingDate,
      isSolved: true,
    );

    ref.read(asyncTicketProvider.notifier).addTicket(ticket);
  }
}
