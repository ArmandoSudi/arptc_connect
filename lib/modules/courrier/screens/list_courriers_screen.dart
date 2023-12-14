import 'package:arptc_connect/modules/courrier/providers/courrier_provider.dart';
import 'package:arptc_connect/modules/courrier/providers/courrier_service_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/content_view.dart';
import '../../../widgets/page_header.dart';
import '../models/courrier_model.dart';
import 'add_courrier_screen.dart';

class ListCourriersScreen extends ConsumerStatefulWidget {
  const ListCourriersScreen({super.key});

  @override
  ConsumerState createState() => _ListCourriersScreenState();
}

class _ListCourriersScreenState extends ConsumerState<ListCourriersScreen> {
  String _searchDate = "Date d'enregistrement";
  bool isFiltering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final courrierState = ref.watch(asyncCourrierProvider);

    return Scaffold(
      body: ContentView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const PageHeader(
                  title: 'Courriers',
                  description: 'La liste des courriers de la DEP',
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => AddCourrierScreen()));
                  },
                  label: const Text("Enregistrer courrier",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const Gap(16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: CupertinoSearchTextField(
                    placeholder: "Rechercher un courrier",
                    onChanged: _onSearchChanged,
                  ),
                ),
                const Gap(16),
                ElevatedButton.icon(
                  icon: isFiltering
                      ? const Icon(Icons.cancel_outlined)
                      : const Icon(Icons.filter_alt_rounded),
                  onPressed: () async {

                    ref.read(dateFilterProvider.notifier).state = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2021),
                      lastDate: DateTime.now(),
                      initialEntryMode: DatePickerEntryMode.calendarOnly,
                    );

                    setState(() {
                      isFiltering = !isFiltering;
                    });

                  }, label: isFiltering
                    ? Text("${ref.read(dateFilterProvider)?.toString()}}",
                    style: const TextStyle(fontWeight: FontWeight.bold))
                    : const Text("Filtrer par date",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Gap(16),
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: courrierState.when(
                  data: (data) {
                    if (data.isEmpty) {
                      return const Center(child: Text("Aucun courrier trouvé"));
                    }

                    return ListView.separated(
                      itemCount: data.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final courrier = data[index];
                        return ListTile(
                          title: Text(
                            courrier.sender,
                            style: theme.textTheme.bodyMedium!
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            courrier.object,
                            style: theme.textTheme.labelMedium,
                          ),
                          trailing: const Icon(Icons.navigate_next_outlined),
                          onTap: () {
                            // UserPageRoute(userId: user.userId).go(context);
                            context.go('/courriers/${courrier.id}');
                          },
                        );
                      },
                    );
                  },
                  error: (error, stackTrace) {
                    return const Text("something went wrong");
                  },
                  loading: () => const CircularProgressIndicator(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    ref.watch(asyncCourrierProvider.notifier).filteredList(value);
  }
}
