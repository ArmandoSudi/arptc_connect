import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/cart.dart';
import '../../models/product.dart';
import '../../data/inventory_serv.dart';

class CartController extends StateNotifier<CartState> {

  final InventoryServ inventoryService;
  CartController(this.inventoryService) : super(const CartState(items: []));

  int get count => state.items.length;
  List<CartItem> get carItems => state.items;

  void addProduct(Product product, int quantity) {
    CartItem? existingItem = state.items.where(
            (item) => item.product.name == product.name).firstOrNull;
    if (existingItem != null) {
      state = state.copyWith(
          items: List.from(state.items)
            ..remove(existingItem)
            ..add(existingItem.copyWith(quantity: existingItem.quantity + quantity)));
    } else {
      state = state.copyWith(items: [...state.items, CartItem(product: product, quantity: quantity)]);
    }

    log("CartSize : ${state.items.length}");
  }

  void removeProduct(Product product){
    CartItem? existingItem = state.items
        .where(
            (item) => item.product.name == product.name)
        .firstOrNull;
    if (existingItem != null) {
      state = state.copyWith(items: List.from(state.items)
        ..remove(existingItem));
    }
  }

  void increaseQuantity(Product product) {
    CartItem? existingItem = state.items
        .where(
            (item) => item.product.name == product.name)
        .firstOrNull;
    if (existingItem != null) {

      // As we need to resinsert the product at the same index
      final indexOfExistingProduct = state.items.indexOf(existingItem);

      state = state.copyWith(items: List.from(state.items)
        ..remove(existingItem)
        ..insert(indexOfExistingProduct, existingItem.copyWith(quantity: existingItem.quantity + 1)));

    }
  }

  void decreaseQuantity(Product product) {
    CartItem? existingItem = state.items
        .where(
            (item) => item.product.name == product.name)
        .firstOrNull;
    if (existingItem != null) {

      // As we need to resinsert the product at the same index
      final indexOfExistingProduct = state.items.indexOf(existingItem);

      if (existingItem.quantity > 1) {
        state = state.copyWith(items: List.from(state.items)
          ..remove(existingItem)
          ..insert(indexOfExistingProduct,existingItem.copyWith(quantity: existingItem.quantity - 1)));
      }
    }
  }

  void updateQuantity(Product product, int quantity) {
    CartItem? existingItem = state.items.where(
            (item) => item.product.name == product.name).firstOrNull;
    if (existingItem != null) {
      state = state.copyWith(items: List.from(state.items)
        ..remove(existingItem)
        ..add(existingItem.copyWith(quantity: quantity)));
    }
  }

  void clearCart(){
    state = state.copyWith(items: []);
  }



  void updateProductQuantity(Product product, int quantity){
    final newProduct = product.copyWith(quantity: quantity);
    log("1. CartController::updateProductQuantity => PRODUCT ID : ${product.id}");
    inventoryService.updateProduct(newProduct);
  }
}

final cartControllerProvider = StateNotifierProvider.autoDispose<CartController, CartState>((ref){
  return CartController(ref.read(inventoryServProvider));
});