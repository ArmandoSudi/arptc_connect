import 'package:arptc_connect/extensions/date_extension.dart';
import 'package:arptc_connect/modules/ticketing/presentation/controllers/async_ticket.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TicketsScreen extends ConsumerStatefulWidget {
  const TicketsScreen({super.key});

  @override
  ConsumerState createState() => _TicketsScreenState();
}

class _TicketsScreenState extends ConsumerState<TicketsScreen> {
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
                onPressed: (){
                  context.go("/service/ticketing/add");
                },
                icon: Icon(Icons.add),
                label: Text("créer ticket"))
          ],
        ),

        // LIST OF TICKETS
        asyncTickets.when(
          data: (data) {
            return Expanded(
              child: Card(
                elevation: 5,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(
                        Icons.circle,
                        color: Colors.lightGreen,
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
                      trailing:
                          Text("${data[index].creationDate.formatedDate}"),
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return const Divider();
                  },
                ),
              ),
            );
          },
          error: (error, stackTrace) {
            //TODO log the error that going to occur here
            return const Text("An error occurer when loading the items");
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        )
      ],
    )));
  }
}
