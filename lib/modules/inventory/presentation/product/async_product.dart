import 'dart:developer';

import 'package:arptc_connect/modules/inventory/presentation/cart/cart_controller_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/inventory_serv.dart';
import '../../models/cart.dart';
import '../../models/product.dart';

part 'async_product.g.dart';

@riverpod
class AsyncProduct extends _$AsyncProduct {
  List<Product> products = [];

  @override
  FutureOr<List<Product>> build() async {
    products = await fetchItems();
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
    log("restocking: Restocking the products");
    state = const AsyncValue.loading();
    cartItems.forEach((cartItem) {
      int newQuantity = cartItem.product.quantity + cartItem.quantity;
      updateProductQuantity(cartItem.product, newQuantity);
    });
    ref.read(cartControllerProvider.notifier).clearCart();
    state = AsyncValue.data( await fetchItems());
  }

  void updateProductQuantity(Product product, int quantity)async {
    final newProduct = product.copyWith(quantity: quantity);
    await ref.read(inventoryServProvider).updateProduct(newProduct);
  }

  void deliverTo(List<CartItem> cartItems, String direction) async {
    state = const AsyncValue.loading();
    cartItems.forEach((cartItem) {
      int newQuantity = cartItem.product.quantity - cartItem.quantity;
      updateProductQuantity(cartItem.product, newQuantity);
    });
    ref.read(cartControllerProvider.notifier).clearCart();
    state = AsyncValue.data( await fetchItems());
  }
}