import 'dart:developer';

import 'package:arptc_connect/utils/firestore_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';

class InventoryServ {
  final FirestoreClient firestoreClient;

  InventoryServ(this.firestoreClient);

  Future<void> addProduct(Product product) async{
    try{
      String id = await firestoreClient.add(collection: "products", data: product.toMap());
      log("addProduct: ID of created product");
    } catch(err) {
      log("addProduct => Error : $err");
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      log("2. InventorySer::updateProduct => PRODUCT ID : ${product.id}");
      log("3. InventorySer::updateProduct => PRODUCT ID : ${product.toMap().toString()}");
      log("4. InventorySer::updateProduct => PRODUCT ID : ${product.toString()}");
      await firestoreClient.update(collection: 'products', data: product.toMap());
    } catch (err) {
      log("InventorySer::updateProduct => Error : ${err}");
    }
  }

  Future<List<Product>> fetchAllProducts() async {
    try {
      final results = await firestoreClient.fetchAll(collection: "products");
      log("InventoryServ::fetchAllProducts FIRST PRODUCT ID ${results.first.id}");
      return results.map((item) => Product.fromMap(item.data, id: item.id)).toList();
    } catch(err){
      log("InventoryServ: fetchAllProducts couldn't fetch");
      throw(Exception(err));
    }
  }

}

final inventoryServProvider = Provider<InventoryServ>((ref){
  return InventoryServ(ref.read(firestoreClientProvider));
});