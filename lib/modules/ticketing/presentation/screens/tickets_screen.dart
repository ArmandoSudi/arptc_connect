import 'dart:developer';

import 'package:arptc_connect/extensions/date_extension.dart';
import 'package:arptc_connect/modules/ticketing/data/report_service.dart';
import 'package:arptc_connect/modules/ticketing/presentation/controllers/async_ticket.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../domain/ticket.dart';

class TicketsScreen extends ConsumerStatefulWidget {
  const TicketsScreen({super.key});

  @override
  ConsumerState createState() => _TicketsScreenState();
}

class _TicketsScreenState extends ConsumerState<TicketsScreen> {
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now(),
  );

  final List<Ticket> _tickets = [];

  @override
  Widget build(BuildContext context) {
    final asyncTickets = ref.watch(asyncTicketProvider);
    final theme = Theme.of(context);

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
                const PageHeader(
                    title: "Tickets",
                    description: 'Gestion des tickets d\'intervention'),
                Expanded(
                  child: Container(),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    DateTimeRange? dateTimeRange = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2021),
                      lastDate: DateTime.now(),
                      initialDateRange: _selectedDateRange,
                    );

                    if (dateTimeRange != null) {
                      setState(() {
                        _selectedDateRange = dateTimeRange;
                      });
                    }

                    ReportService().generateReport(_tickets);

                    // context.go("/service/ticketing/add");
                  },
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text("Rapport"),
                ),
                const Gap(16),
              ],
            ),

            // LIST OF TICKETS
            asyncTickets.when(
              data: (data) {
                // _tickets = data;
                _tickets.clear();

                // Order list in data by ticket creation date
                data.sort((a, b) => a.creationDate.compareTo(b.creationDate));

                _tickets.addAll(data);

                return Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Icon(
                          Icons.circle,
                          color: data[index].isSolved
                              ? Colors.grey
                              : Colors.lightGreen,
                        ),
                        title: Text(
                          data[index].subject,
                          style: theme.textTheme.bodyMedium!
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          data[index].agent,
                          style: theme.textTheme.labelMedium,
                        ),
                        trailing: Text(data[index].creationDate.formatedDate),
                        onTap: () {
                          context.go("/service/ticketing/${data[index].id}");
                        },
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return const Divider();
                    },
                  ),
                );
              },
              error: (error, stackTrace) {
                log("Error loading tickets:: $error");
                log("$stackTrace");
                return const Text("An error occurer when loading the items");
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => context.go("/service/ticketing/add"),
      ),
    );
  }
}
