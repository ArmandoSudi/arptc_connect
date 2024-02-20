import 'dart:developer';

import 'package:arptc_connect/modules/inventory/presentation/product/async_product.dart';
import 'package:arptc_connect/modules/inventory/presentation/cart/cart_controller_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../widgets/content_view.dart';
import '../../../../widgets/page_header.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartController = ref.watch(cartControllerProvider);

    return Scaffold(
      body: ContentView(
        child: Column(
          children: [
            // TOP PORTION
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    context.pop();
                  },
                ),
                const PageHeader(
                    title: "Panier",
                    description: 'Liste des articles dans le panier'),
                Expanded(child: Container()),
                FilledButton.icon(
                  icon: const Icon(Icons.upload),
                  onPressed: () async {
                    await showSelectedDirectionDialog(context);
                  },
                  label: const Text("Livrer",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Gap(16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  onPressed: () async {
                    await showYesOrNoDialog(context, "Etes-vous sûr de vouloir mettre à jour le stock ?");
                  },
                  label: const Text("Approvisionner",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                )

              ],
            ),

            // LIST OF ITEMS IN THE CART
            const Gap(32),
            Expanded(
              child: Card(
                elevation: 5,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: cartController.items.length,
                  itemBuilder: (context, index) {
                    return Slidable(
                      key: ValueKey(index),
                      endActionPane:  ActionPane(
                        extentRatio: 0.2 ,
                        motion: const ScrollMotion(),
                        children: [
                          SlidableAction(
                            // An action can be bigger than the others.
                            flex: 1,
                            onPressed: (value){
                              ref
                                  .read(cartControllerProvider.notifier)
                                  .removeProduct(cartController.items[index].product);
                            },
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.grey,
                            icon: Icons.delete_forever_outlined,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Text("${index + 1} . "),
                        title: Text(
                          cartController.items[index].product.name,
                          style: theme.textTheme.bodyMedium!
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        trailing: Container(
                          decoration: const ShapeDecoration(
                            shape: StadiumBorder(side: BorderSide(color: Colors.grey)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                               IconButton(
                                icon: const Icon(Icons.remove),
                                visualDensity: VisualDensity.compact,
                                onPressed: (){
                                  log("reduce quantity");
                                  ref.read(cartControllerProvider.notifier)
                                      .decreaseQuantity(cartController.items[index].product);
                                },
                              ),
                              SizedBox(
                                  width:50,
                                  child: Text(
                                    "${cartController.items[index].quantity}",
                                    style: theme.textTheme.bodyLarge,
                                    textAlign: TextAlign.center,
                                  ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                visualDensity: VisualDensity.compact,
                                onPressed: (){
                                  log("increase quantity");
                                  ref.read(cartControllerProvider.notifier)
                                      .increaseQuantity(cartController.items[index].product);
                                },
                              ),
                            ],
                          ),
                        ),

                        onTap: null,
                      ),
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return const Divider();
                  },
                )
              )
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            const Gap(32),
            Text("Total :  ${cartController.items.length} Articles", style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            Expanded(child: Container()),
            FilledButton(
              onPressed: () {
                // log("add_agent_screen:: Cancel");
                ref.read(cartControllerProvider.notifier).clearCart();
              },
              child: const Text(
                "Annuler pannier",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Gap(32),
          ],
        ),
      ),
    );
  }

  Future<void> showSelectedDirectionDialog(BuildContext context) async {
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
                          onPressed: () {
                            final cartItems = ref.read(cartControllerProvider.notifier).carItems;
                            ref.read(asyncProductProvider.notifier).deliverTo(cartItems, selectedValue);
                            Navigator.of(context).pop();
                            context.pop();
                          },
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
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text("Annuler",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            title: const Text('Sélectionner la direction bénéficiaire'),
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
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () {
                            final cartItems = ref.read(cartControllerProvider.notifier).carItems;
                            ref.read(asyncProductProvider.notifier).restock(cartItems);
                            Navigator.of(context).pop();
                            context.pop();
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
            title: const Text('Confirmation'),
          );
        });
  }
}
