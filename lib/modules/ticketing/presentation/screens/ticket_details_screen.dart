import 'package:arptc_connect/extensions/date_extension.dart';
import 'package:arptc_connect/modules/ticketing/data/ticketing_service.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/custom_form_field.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../widgets/custom_filledbutton.dart';
import '../../../../widgets/page_header.dart';
import '../../../../widgets/responsive_center.dart';
import '../../domain/ticket.dart';

class TicketDetailsScreen extends ConsumerStatefulWidget {
  const TicketDetailsScreen({required this.ticketId, super.key});

  final String ticketId;

  @override
  ConsumerState createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends ConsumerState<TicketDetailsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Ticket? ticket;

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
                  title: 'Détails du ticket',
                  description: '',
                ),
                const Gap(16),
              ],
            ),
            const Gap(16),
            ResponsiveCenter(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FutureBuilder(
                        future: ref
                            .watch(ticketingServiceProvider)
                            .getTicketById(widget.ticketId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return const Center(
                                child: Text('Erreur de connection'));
                          }
                          ticket = snapshot.data as Ticket;
                          return TicketWidget(ticket: ticket!);
                        }),
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
                  onPressed: () async {
                    // saveTicket();
                    // context.pop();
                    await showSolutionFormDialog(context, widget.ticketId);
                  },
                  text: "Cloturer"),
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

  Future<void> showSolutionFormDialog(
      BuildContext context, String tickedId) async {
    final TextEditingController solutionTEC = TextEditingController();

    return await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: SizedBox(
              width: 500,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomFormField(
                      label: "Solution",
                      hintText: "",
                      textInputType: TextInputType.name,
                      controller: solutionTEC,
                      borderRadius: 30,
                      maxLine: 4,
                    ),
                    const Gap(16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomFilledButton(
                            onPressed: () {
                              ticket = ticket!.copyWith(
                                solution: solutionTEC.text,
                                isSolved: true,
                              );
                              ref
                                  .read(ticketingServiceProvider)
                                  .updateTicket(ticket!);
                              context.pop();
                            },
                            text: 'confirmer',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                                minimumSize: const Size.fromHeight(50)),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              "Annuler",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            title: const Text('Enregistrer la solution trouvée'),
          );
        });
  }
}

class TicketWidget extends StatelessWidget {
  final Ticket ticket;

  const TicketWidget({Key? key, required this.ticket}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          const Gap(16),
          _buildLabels(context, "agent", "date"),
          const Gap(4),
          _buildTitles(context, ticket.agent, ticket!.creationDate.formatedDate),
          const Gap(16),
          _buildDottedLine(context),
          const Gap(16),
          _buildLabels(context, "catégorie", "état"),
          const Gap(4),
          Row(
            children: [
              Text(
                  ticket.category,
                  style: Theme.of(context).textTheme.bodyLarge
              ),
              Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration:  ShapeDecoration(
                  color: ticket.isSolved ? Colors.grey: Colors.green, // Adjust color as needed
                  shape: StadiumBorder(),
                ),
                child: Text(
                  ticket.isSolved ? "Cloturé" : "Ouvert",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const Gap(16),
          Text("Numéro ticket", style: Theme.of(context).textTheme.titleSmall),
          const Gap(8),
        BarcodeWidget(
          width: 200,
          barcode: Barcode.code128(),
          data: 'XASFDEF',
        ),
        ],
      ),
    );
  }

  Widget _buildLabels(BuildContext context, String label1, String label2) {
    return Row(
      children: [
        Text(
            label1,
          style: Theme.of(context).textTheme.titleSmall
        ),
        Spacer(),
        Text(
          label2,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
  Widget _buildTitles(BuildContext context, String title1, String title2) {
    return Row(
      children: [
        Text(
          title1,
          style: Theme.of(context).textTheme.bodyLarge
        ),
        Spacer(),
        Text(
          title2,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Text(
          ticket.subject,
          style: Theme.of(context).textTheme.headline6,
        ),
        const Spacer(),
        const SizedBox(width: 10.0),
      ],
    );
  }

  Widget _buildDottedLine(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1.0),
      painter: DottedLinePainter(),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.0;

    final max = size.width;
    final dashWidth = 5.0;
    final dashSpace = 5.0;
    double startX = 0.0;

    while (startX < max) {
      canvas.drawLine(Offset(startX, 0.0), Offset(startX + dashWidth, 0.0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

