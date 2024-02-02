import 'package:arptc_connect/modules/inventory/models/item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartController extends StateNotifier<AsyncValue<List<Item>>> {
  CartController({required FirebaseFirestore db}) :
      super(const AsyncData([]));


}