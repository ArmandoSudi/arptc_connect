import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../../../utils/firebase_constants.dart';
import '../models/courrier_model.dart';

class CourrierService {
  CourrierService(this._firestore);

  final FirebaseFirestore _firestore;

  /// This getter will return a stream of all the courriers
  CollectionReference get courriers =>
      _firestore.collection(FirebaseConstants.courriersCollection);

  Future<void> deleteAnnotationAtIndex(Courrier courrier, int index){
    Map<String, String> annotationToRemove  = courrier.annotations[index];
    var annotations = courrier.annotations.toList();
    annotations.remove(annotationToRemove);
    return courriers.doc(courrier.id).update({'annotations': annotations});

  }

  Future<List<Courrier>> allCourriers(){
    return courriers.get().then((querySnapshot) {
      return querySnapshot.docs
          .map((doc) => Courrier.fromDocument(doc))
          .toList();
    }, onError: (e) {
      return [];
    });
  }

  Stream<Courrier> getCourrier(String id) {
     return courriers
         .doc(id)
         .snapshots()
         .map((event) => Courrier.fromDocument(event));
  }
  
  Future<void> addCourrier(Courrier courrier){
    return courriers.add(courrier.toJson());
  }

  Future<void> addAnnotationToCourrier(String courrierId,
      Map<String, String> annotation){
    return courriers.doc(courrierId).update({
      'annotations': FieldValue.arrayUnion([annotation])
    });
  }


  // listen to change to a single courrier document in firestore
  // Stream<Courrier> get(String id){
  //   final docRef = courriers.doc(id);
  //   docRef.snapshots().listen(
  //         (event) {
  //       // final source = (event.metadata.hasPendingWrites) ? "Local" : "Server";
  //           if(event.data() != null ){
  //             print("CourrierService::: ${event.data()}");
  //             return Courrier.fromDocument(event.data());
  //           }
  //
  //     },
  //     onError: (error) => print("Listen failed: $error"),
  //   );
  //
  //   return null;
  // }
}