import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/content_view.dart';
import '../../../widgets/page_header.dart';
import '../providers/async_item.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final asyncItem = ref.watch(asyncItemsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: ContentView(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    context.pop();
                  },
                ),
                const PageHeader(
                    title: "Panier",
                    description: 'Liste des articles dans le panier'),
                Expanded(child: Container()),
                const Gap(16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload_outlined),
                  onPressed: () async {
                    await showSelecteDirectionDialog(context);
                  },
                  label: const Text("Livrer",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Gap(16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.download_outlined),
                  onPressed: () async {
                    await showYesOrNoDialog(context, "Etes-vous sure de vouloir approvisionner les quantités en stock ?");
                  },
                  label: const Text("Approvisionner",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Gap(16),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      foregroundColor: Colors.grey),
                  onPressed: () {
                    // log("add_agent_screen:: Cancel");
                  },
                  child: const Text(
                    "Annuler pannier",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(32),
            asyncItem.when(
              data: (data) {
                return Expanded(
                  child: Card(
                    elevation: 5,
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: Text("${index + 1}. "),
                          title: Text(
                            data[index].name,
                            style: theme.textTheme.bodyMedium!
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          trailing: Text("X 10"),
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
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showSelecteDirectionDialog(BuildContext context) async {
    final TextEditingController quantityController = TextEditingController();
    int itemCount = 0;
    List<String> directions = <String>['DSI', 'DRMT', 'DRAJ', 'DEP'];
    var selectedValue = directions.first;

    return await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Gap(16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      value: selectedValue,
                      items: directions
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedValue = newValue!;
                        });
                      },
                      // Customize the button's appearance (optional)
                      hint: const Text('Select the direction'),
                      icon: const Icon(Icons.keyboard_arrow_down_outlined),
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
                          onPressed: () {},
                          child: const Text("Approvisionner",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.grey),
                              minimumSize: const Size.fromHeight(50),
                              foregroundColor: Colors.grey),
                          onPressed: () {},
                          child: const Text("Annuler",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            title: const Text('Selectionner la direction bénéficiaire'),
          );
        });
  }
  Future<void> showYesOrNoDialog(BuildContext context, String message) async {
    final TextEditingController quantityController = TextEditingController();
    int itemCount = 0;
    List<String> directions = <String>['DSI', 'DRMT', 'DRAJ', 'DEP'];
    var selectedValue = directions.first;

    return await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Gap(16),
                  Text(message),
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
                            Navigator.of(context).pop();
                          },
                          child: const Text("Oui",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.grey),
                              minimumSize: const Size.fromHeight(50),
                              foregroundColor: Colors.grey),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text("Non",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            title: const Text('Selectionner la direction bénéficiaire'),
          );
        });
  }
}
