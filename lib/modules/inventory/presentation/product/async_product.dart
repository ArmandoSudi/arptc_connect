import 'dart:developer';

import 'package:arptc_connect/modules/inventory/presentation/cart/cart_controller_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/inventory_serv.dart';
import '../../models/cart.dart';
import '../../models/product.dart';

part 'async_product.g.dart';

@Riverpod(keepAlive: true)
class AsyncProduct extends _$AsyncProduct {
  List<Product> products = [];

  @override
  FutureOr<List<Product>> build() async {
    products = await fetchItems();
    log("first product  quantity: ${products.first.quantity}");
    return products;
  }

  Future<List<Product>> fetchItems() {
    return ref.read(inventoryServProvider).fetchAllProducts();
  }

  Future<void> addProduct(Product product) async {
    state = const AsyncValue.loading();
    await ref.read(inventoryServProvider).addProduct(product);
    state = AsyncValue.data( await fetchItems());
  }

  void restock(List<CartItem> cartItems) async {

    state = const AsyncValue.loading();
    for (var cartItem in cartItems) {
      int newQuantity = cartItem.product.quantity + cartItem.quantity;
      updateProductQuantity(cartItem.product, newQuantity);

      log("restocking: Restocking ${cartItem.product.name} : $newQuantity");
    }
    ref.read(cartControllerProvider.notifier).clearCart();
    state = AsyncValue.data( await fetchItems());

  }

  // Update the product quantity in the DB
  void updateProductQuantity(Product product, int quantity)async {
    final newProduct = product.copyWith(quantity: quantity);
    await ref.read(inventoryServProvider).updateProduct(newProduct);
  }

  void deliverTo(List<CartItem> cartItems, String direction) async {

    state = const AsyncValue.loading();
    for (var cartItem in cartItems) {
      //TODO Make sure that there is enough product in stock before delivery
      int newQuantity = cartItem.product.quantity - cartItem.quantity;
      updateProductQuantity(cartItem.product, newQuantity);

      log("deliverTo: Delivery ${cartItem.product.name} : $newQuantity");
    }
    ref.read(cartControllerProvider.notifier).clearCart();
    state = AsyncValue.data( await fetchItems());
  }
}