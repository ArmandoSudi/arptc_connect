import 'package:arptc_connect/modules/inventory/models/product.dart';

class CartState {
  final List<CartItem> items;

  const CartState({
    required this.items,
  });

  CartState copyWith({required List<CartItem> items}){
    return CartState(items: items);
  }

}

class CartItem {
  final Product product;
  final int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  CartItem copyWith({Product? product, int? quantity }){
    return CartItem(
        product: product ?? this.product,
      quantity: quantity ?? this.quantity
    );
  }


}