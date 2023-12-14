import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';

class InventoryService {
  InventoryService(this._firestore);

  final FirebaseFirestore _firestore;

  /// This getter will return a stream of all the items
  CollectionReference get items =>
      _firestore.collection('items');

  Future<List<Item>> allItems() {
    return items.get().then((querySnapshot) {
      return querySnapshot.docs
          .map((doc) => Item.fromDocument(doc))
          .toList();
    }, onError: (e) {
      return [];
    });
  }

  Stream<Item> getItem(String id) {
    return items
        .doc(id)
        .snapshots()
        .map((event) => Item.fromDocument(event));
  }

  Future<void> addItem(Item item) {
    return items.add(item.toJson());
  }

  Future<void> updateItem(Item item) {
    return items.doc(item.id).update(item.toJson());
  }

  Future<void> deleteItem(Item item) {
    return items.doc(item.id).delete();
  }


// listen to change to a single item document in firestore
// Stream<Item> get(String id){
//   final docRef = items.doc(id);
//   docRef.snapshots().listen(
//         (event) {
//       // final source = (event.metadata.hasPendingWrites) ? "Local" : "Server";
//           if(event.data() != null ){
//             print("InventoryService::: ${event.data()}");
//             return Item.fromDocument(event.data());
//           }
//
//     },
//     onError: (error) => print("Listen failed: $error"),
//   );
//
//   return null;
// }

}