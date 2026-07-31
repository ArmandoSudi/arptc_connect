import 'package:arptc_connect/modules/inventory/models/product.dart';
import 'package:arptc_connect/modules/inventory/presentation/product/async_product.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/custom_dropdown_field.dart';
import 'package:arptc_connect/widgets/custom_filledbutton.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../widgets/page_header.dart';
import '../../../../core/constants.dart';
import '../cart/cart_controller_provider.dart';

class ManageItemScreen extends ConsumerStatefulWidget {
  const ManageItemScreen({super.key});

  @override
  ConsumerState createState() => _ManageItemScreenState();
}

class _ManageItemScreenState extends ConsumerState<ManageItemScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final asyncProducts = ref.watch(asyncProductProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: ContentView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    title: "Articles",
                    description: 'Gestion des articles en stock'),
                Expanded(child: Container()),
                const Gap(16),
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    await showCreateProductDialog(context);
                  },
                  label: const Text("Créer article",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Gap(16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                ),
                child: asyncProducts.when(
                  data: (data) {
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                            title: Text(
                              data[index].name,
                              style: theme.textTheme.bodyMedium!
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                            // subtitle: Text(
                            //   data[index].quantity.toString() + " " + data[index].unit + "(s)",
                            //   style: theme.textTheme.labelMedium,
                            // ),
                            trailing: Text(
                              "${data[index].quantity} ${data[index].unit}(s)",
                              style: theme.textTheme.labelMedium,
                            ));
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return const Divider();
                      },
                    );
                  },
                  error: (error, stackTrace) {
                    //TODO log the error that going to occur here
                    return const Text(
                        "An error occured when loading the items");
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showCreateProductDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    String? selectedUnitValue;

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
                    // NAME
                    CommonTextInput(
                      label: "Nom",
                      hintText: "nom de l'article",
                      type: CommonTextInputType.text,
                      controller: nameController,
                    ),
                    const Gap(12),

                    // QUANTITY
                    CommonTextInput(
                      label: "Quantité",
                      hintText: "quantité de l'article en stock",
                      type: CommonTextInputType.number,
                      controller: quantityController,
                    ),
                    const Gap(12),

                    // UNIT
                    CustomDropDown(
                        label: "Unité",
                        hintText: "Selectionner l'unité de l'article",
                        items: Constants.productUnits,
                        onChanged: (value) {
                          setState(() {
                            selectedUnitValue = value!;
                          });
                        }),
                    const Gap(32),

                    // BUTTON TO SAVE OR CANCEL
                    Row(
                      children: [
                        Expanded(
                          child: CustomFilledButton(
                            onPressed: () {
                              final product = Product(
                                name: nameController.text,
                                unit: selectedUnitValue ??
                                    Constants.productUnits.first,
                                quantity: int.parse(quantityController.text),
                              );

                              ref
                                  .read(asyncProductProvider.notifier)
                                  .addProduct(product);

                              Navigator.of(context).pop();
                            },
                            text: "Enregistrer",
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Expanded(
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

  Future<void> showSelectedItemDialog(
      BuildContext context, Product product) async {
    final TextEditingController quantityController =
        TextEditingController(text: "1");

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
                    const Gap(16),
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(16),
                    CommonTextInput(
                      label: "Quantité",
                      hintText: "0",
                      type: CommonTextInputType.number,
                      controller: quantityController,
                      borderRadius: 30,
                    ),
                    const Gap(16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomFilledButton(
                            onPressed: () {
                              //TODO Check that the required quantity is not more than quantity in stock
                              int quantity = int.parse(quantityController.text);
                              ref
                                  .read(cartControllerProvider.notifier)
                                  .addProduct(product, quantity);
                              Navigator.of(context).pop();
                            },
                            text: "Confirmer",
                            // backgroundColor: Colors.green,
                          ),
                        ),
                        const Gap(10),
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
            title: const Text('Article à ajouter au panier'),
          );
        });
  }
}
