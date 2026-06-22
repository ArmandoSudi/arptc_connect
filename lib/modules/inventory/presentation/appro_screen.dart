import 'dart:developer';

import 'package:arptc_connect/modules/inventory/models/product.dart';
import 'package:arptc_connect/modules/inventory/presentation/cart/cart_controller_provider.dart';
import 'package:arptc_connect/modules/inventory/presentation/product/async_product.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/custom_filledbutton.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../widgets/page_header.dart';

class ApproScreen extends ConsumerStatefulWidget {
  const ApproScreen({super.key});

  @override
  ConsumerState createState() => _ApproScreenState();
}

class _ApproScreenState extends ConsumerState<ApproScreen> {
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
                    title: "Approvisionnement",
                    description: 'Mettre à jour le stock '),
              ],
            ),
            const Gap(16),
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: asyncProducts.when(
                      data: (data) {
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(5.0)),
                          ),
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
                                trailing: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.transparent,
                                      width:
                                          1.0, // Adjust border width as needed
                                    ),
                                  ),
                                  child: IconButton(
                                    onPressed: () async {
                                      await showSelectedItemDialog(
                                          context, data[index]);
                                      // context.pop();
                                    },
                                    icon: Icon(
                                      Icons.add,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              );
                            },
                            separatorBuilder:
                                (BuildContext context, int index) {
                              return const Divider();
                            },
                          ),
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(5.0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Panier",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20)),
                                Badge(
                                  label: Text(
                                      "${ref.watch(cartControllerProvider.notifier).count}"),
                                  isLabelVisible: ref
                                              .watch(cartControllerProvider
                                                  .notifier)
                                              .count >
                                          0
                                      ? true
                                      : false,
                                  child:
                                      const Icon(Icons.shopping_cart_outlined),
                                )
                              ],
                            ),
                          ),
                          cartController.items.isEmpty
                              ? const Expanded(
                                  child: Center(
                                    child: Text("Votre panier est vide..."),
                                  ),
                                )
                              : Expanded(
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: cartController.items.length,
                                    itemBuilder: (context, index) {
                                      return Slidable(
                                        key: ValueKey(index),
                                        endActionPane: ActionPane(
                                          extentRatio: 0.2,
                                          motion: const ScrollMotion(),
                                          children: [
                                            SlidableAction(
                                              // An action can be bigger than the others.
                                              flex: 1,
                                              onPressed: (value) {
                                                ref
                                                    .read(cartControllerProvider
                                                        .notifier)
                                                    .removeProduct(
                                                        cartController
                                                            .items[index]
                                                            .product);
                                              },
                                              backgroundColor: Colors.white,
                                              foregroundColor: Colors.grey,
                                              icon:
                                                  Icons.delete_forever_outlined,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ],
                                        ),
                                        child: ListTile(
                                          leading: Text("${index + 1} . "),
                                          title: Text(
                                            cartController
                                                .items[index].product.name,
                                            style: theme.textTheme.bodyMedium!
                                                .copyWith(
                                                    fontWeight:
                                                        FontWeight.w600),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.red[50],
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.transparent,
                                                    width:
                                                        1.0, // Adjust border width as needed
                                                  ),
                                                ),
                                                child: IconButton(
                                                  icon: const Icon(Icons.remove,
                                                      color: Colors.red),
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  onPressed: () {
                                                    log("reduce quantity");
                                                    ref
                                                        .read(
                                                            cartControllerProvider
                                                                .notifier)
                                                        .decreaseQuantity(
                                                            cartController
                                                                .items[index]
                                                                .product);
                                                  },
                                                ),
                                              ),
                                              SizedBox(
                                                width: 50,
                                                child: Text(
                                                  "${cartController.items[index].quantity}",
                                                  style:
                                                      theme.textTheme.bodyLarge,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.green[50],
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.transparent,
                                                    width:
                                                        1.0, // Adjust border width as needed
                                                  ),
                                                ),
                                                child: IconButton(
                                                  icon: const Icon(Icons.add,
                                                      color: Colors.green),
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  onPressed: () {
                                                    log("increase quantity");
                                                    ref
                                                        .read(
                                                            cartControllerProvider
                                                                .notifier)
                                                        .increaseQuantity(
                                                            cartController
                                                                .items[index]
                                                                .product);
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          onTap: null,
                                        ),
                                      );
                                    },
                                    separatorBuilder:
                                        (BuildContext context, int index) {
                                      return const Divider();
                                    },
                                  ),
                                ),
                          BottomAppBar(
                            // elevation: 5,
                            // shadowColor: Colors.grey,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: TextButton(
                                    child: const Text(
                                      "Annuler",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () {
                                      log("Annuler");
                                    },
                                  )),
                                  Expanded(
                                      child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(50),
                                    ),
                                    child: const Text(
                                      "Approvisionner",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () async {
                                      log("Appro");
                                      await showYesOrNoDialog(context,
                                          "Etes-vous sûr de vouloir mettre à jour le stock ?");
                                    },
                                  ))
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

  Future<void> showYesOrNoDialog(BuildContext context, String message) async {
    TextTheme textTheme = Theme.of(context).textTheme;

    return await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(16),
                  Text(message, style: textTheme.bodyLarge),
                  const Gap(32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              foregroundColor: Colors.grey),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text("Annuler",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () {
                            final cartItems = ref
                                .read(cartControllerProvider.notifier)
                                .carItems;
                            ref
                                .watch(asyncProductProvider.notifier)
                                .restock(cartItems);
                            Navigator.of(context).pop();
                            context.pop();
                          },
                          child: const Text("Confirmer",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            title: const Text('Confirmation'),
          );
        });
  }
}
