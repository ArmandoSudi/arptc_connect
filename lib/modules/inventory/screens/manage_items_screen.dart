import 'dart:developer';

import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/custom_form_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../widgets/page_header.dart';
import '../providers/item_provider.dart';

class ManageItemScreen extends ConsumerStatefulWidget {
  const ManageItemScreen({super.key});

  @override
  ConsumerState createState() => _ManageItemScreenState();
}

class _ManageItemScreenState extends ConsumerState<ManageItemScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final asyncItem = ref.watch(asyncItemProvider);

    return Scaffold(
        body: ContentView(
            child: Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const PageHeader(
              title: "Articles", description: 'Gestion des articles en stock'),
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
            return Card(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: data.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(data[index].name),
                    subtitle: Text(data[index].quantity.toString()),
                  );
                },
              ),
            );
          },
          error: (error, stackTrace) {
            //TODO log the error that going to occur here
            return const Text("An error occurer when loading the items");
          },
          loading: () => const Center(child: CircularProgressIndicator()))
    ])));
  }

  Future<void> showInformationDialog(BuildContext context) async {
    return await showDialog(
        context: context,
        builder: (context) {
          bool? isChecked = false;

          return StatefulBuilder(builder: (context, setState) {
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
                        controller: _textEditingController,
                      ),
                      const Gap(12),
                      CustomFormField(
                        label: "Marque",
                        hintText: "marque de l'article",
                        textInputType: TextInputType.text,
                        controller: _textEditingController,
                      ),
                      const Gap(12),
                      CustomFormField(
                        label: "Quantité",
                        hintText: "quantité de l'article en stock",
                        textInputType: TextInputType.text,
                        controller: _textEditingController,
                      ),
                      const Gap(12),
                      CustomFormField(
                        label: "Catégorie",
                        hintText: "catégorie de l'article",
                        textInputType: TextInputType.text,
                        controller: _textEditingController,
                      ),
                      const Gap(12),
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
              title: Text('Créer un nouvel article'),
            );
          });
        });
  }
}
