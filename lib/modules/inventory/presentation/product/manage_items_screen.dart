import 'package:arptc_connect/modules/inventory/models/product.dart';
import 'package:arptc_connect/modules/inventory/presentation/product/async_product.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/custom_dropdown_field.dart';
import 'package:arptc_connect/widgets/custom_form_field.dart';
import 'package:flutter/cupertino.dart';
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
    final cartController = ref.watch(cartControllerProvider);

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
                    title: "Articles",
                    description: 'Gestion des articles en stock'),
                Expanded(child: Container()),
                IconButton(
                  onPressed: () => context.go('/service/inventory/cart'),
                  icon: Badge(
                    label: Text("${ref.watch(cartControllerProvider.notifier).count}"),
                    isLabelVisible: ref.watch(cartControllerProvider.notifier).count > 0 ? true : false,
                    child: Icon(Icons.shopping_cart_outlined),
                  ),
                ),
                const Gap(16),
                ElevatedButton.icon(
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
            asyncProducts.when(
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
                          trailing: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                                // minimumSize: const Size.fromHeight(50),
                                side: const BorderSide(color: Colors.grey),
                                foregroundColor: Colors.black),
                            onPressed: () async {
                              await showSelectedItemDialog(
                                  context, data[index]);
                              // context.pop();
                            },
                            child: const Text("ajouter au panier",
                                style: TextStyle(fontWeight: FontWeight.bold)),
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

  Future<void> showCreateProductDialog(BuildContext context) async {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _quantityController = TextEditingController();
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
                    CustomFormField(
                      label: "Nom",
                      hintText: "nom de l'article",
                      textInputType: TextInputType.text,
                      controller: _nameController,
                    ),
                    const Gap(12),

                    // QUANTITY
                    CustomFormField(
                      label: "Quantité",
                      hintText: "quantité de l'article en stock",
                      textInputType: TextInputType.number,
                      controller: _quantityController,
                    ),
                    const Gap(12),

                    // UNIT
                    // DropdownButtonFormField<String>(
                    //   // Customize the button's appearance (optional)
                    //
                    //   hint: const Text('Selectionner l\'unité de l\'article'),
                    //   decoration: InputDecoration(
                    //       contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    //       hintText: 'Selectionner l\'unité de l\'article',
                    //       border: OutlineInputBorder(
                    //           borderRadius: BorderRadius.all(
                    //               Radius.circular( 5)
                    //           )
                    //       ),
                    //       // suffixIcon: Icon(Icons.arrow_drop_down)
                    //   ),
                    //   icon: const Icon(Icons.keyboard_arrow_down_outlined),
                    //   isExpanded: true,
                    //   value: selectedValue,
                    //   items: Constants.productUnits
                    //       .map<DropdownMenuItem<String>>((String value) {
                    //     return DropdownMenuItem<String>(
                    //       value: value,
                    //       child: Text(value),
                    //     );
                    //   }).toList(),
                    //   onChanged: (String? newValue) {
                    //     setState(() {
                    //       selectedValue = newValue!;
                    //     });
                    //   },
                    // ),
                    CustomDropDown(
                        label: "Unité",
                        hintText: "Selectionner l\'unité de l\'article",
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
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              shape: const StadiumBorder(),
                            ),
                            onPressed: () {
                              final product = Product(
                                name: _nameController.text,
                                unit: selectedUnitValue ??
                                    Constants.productUnits.first,
                                quantity: int.parse(_quantityController.text),
                              );

                              ref.read(asyncProductProvider.notifier).addProduct(product);

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

  Future<void> showSelectedItemDialog(
      BuildContext context, Product product) async {
    final TextEditingController quantityController = TextEditingController(text: "1");

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
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(16),
                    CustomFormField(
                      label: "Quantité",
                      hintText: "0",
                      textInputType: TextInputType.number,
                      controller: quantityController,
                      borderRadius: 30,
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
                            onPressed: () {
                              //TODO Check that the required quantity is not more than quantity in stock
                              int quantity = int.parse(quantityController.text);
                              ref.read(cartControllerProvider.notifier).addProduct(product, quantity);
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              "Ajouter",
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
