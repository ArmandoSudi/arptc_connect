import 'dart:developer';

import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/custom_form_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../widgets/page_header.dart';
import '../models/item.dart';
import '../providers/async_item.dart';
import '../../../core/constants.dart';

class ManageItemScreen extends ConsumerStatefulWidget {
  const ManageItemScreen({super.key});

  @override
  ConsumerState createState() => _ManageItemScreenState();
}

class _ManageItemScreenState extends ConsumerState<ManageItemScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final asyncItem = ref.watch(asyncItemsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: ContentView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const PageHeader(
                    title: "Articles",
                    description: 'Gestion des articles en stock'),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    await showInformationDialog(context);
                  },
                  label: const Text("Enregistrer article",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const Gap(16),
            const CupertinoSearchTextField(
              placeholder: "Rechercher un article",
            ),
            const Gap(16),
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
                          title: Text(
                            data[index].name,
                            style: theme.textTheme.bodyMedium!
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            data[index].quantity.toString(),
                            style: theme.textTheme.labelMedium,
                          ),
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

  Future<void> showInformationDialog(BuildContext context) async {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _modelController = TextEditingController();
    final TextEditingController _categoryController = TextEditingController();
    final TextEditingController _quantityController = TextEditingController();

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
                      label: "Nom",
                      hintText: "nom ou modéle de l'article",
                      textInputType: TextInputType.text,
                      controller: _nameController,
                    ),
                    const Gap(12),
                    CustomFormField(
                      label: "Marque",
                      hintText: "marque de l'article",
                      textInputType: TextInputType.text,
                      controller: _modelController,
                    ),
                    const Gap(12),
                    CustomFormField(
                      label: "Quantité",
                      hintText: "quantité de l'article en stock",
                      textInputType: TextInputType.text,
                      controller: _quantityController,
                    ),
                    const Gap(12),
                    DropdownMenu(
                      label: const Text("Catégorie"),
                      dropdownMenuEntries: Constants.itemCategories
                          .map((e) => DropdownMenuEntry(
                                value: e,
                                label: e,
                              ))
                          .toList(),
                    ),
                    CustomFormField(
                      label: "Catégorie",
                      hintText: "catégorie de l'article",
                      textInputType: TextInputType.text,
                      controller: _categoryController,
                    ),
                    const Gap(32),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              shape: const StadiumBorder(),
                            ),
                            onPressed: () {
                              final item = Item(
                                  name: _nameController.text,
                                  quantity: int.parse(_quantityController.text),
                                  category: _categoryController.text,
                                  model: _modelController.text,
                                  unit: "pièce");

                              ref
                                  .watch(asyncItemsProvider.notifier)
                                  .addItem(item);

                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              "Enregistrer",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
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
                              log("add_courrier_screen:: cancel");

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
            title: const Text('Créer un nouvel article'),
          );
        });
  }
}