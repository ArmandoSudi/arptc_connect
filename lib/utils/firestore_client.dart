import 'package:arptc_connect/utils/firestore_document.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/firebase_providers.dart';

class FirestoreClient {
  final FirebaseFirestore _firestore;

  FirestoreClient({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<String> add({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    try {
      final docRef = await _firestore.collection(collection).add(data);
      return docRef.id;
    } catch (err) {
      throw Exception('Error adding a document: $err');
    }
  }

  Future<List<FirestoreDocument>> fetchAll({
    required String collection,
  }) async {
    try {
      final colRef = _firestore.collection(collection);
      final documents = await colRef.get();
      return documents.docs
          .map((doc) => FirestoreDocument(id: doc.id, data: doc.data()))
          .toList();
    } catch (err) {
      throw Exception('Error fetching documents: $err');
    }
  }

  Future<List<FirestoreDocument>> fetchAllBy({
    required String collection,
    required String field,
    required String value,
  }) async {
    try {
      final colRef = _firestore.collection(collection);
      final query = colRef.where(field, isEqualTo: value);
      final documents = await query.get();
      return documents.docs
          .map((doc) => FirestoreDocument(id: doc.id, data: doc.data()))
          .toList();
    } catch (err) {
      throw Exception('Error fetching documents: $err');
    }
  }

  // Future<List<FirestoreDocument>> fetchAllFromBundle<T>({
  //   required String collection, // bundleId
  //   required String bundleUrl,
  // }) async {
  //   final response = await http.get(Uri.parse('$bundleUrl/$collection'));
  //   final buffer = Uint8List.fromList(response.body.codeUnits);
  //   final task = _firestore.loadBundle(buffer);
  //
  //   task.stream.listen((taskStateProgress) {
  //     if (taskStateProgress.taskState == LoadBundleTaskState.success) {
  //       print('Bundle loaded successfully');
  //     }
  //   });
  //
  //   await task.stream.last;
  //
  //   final querySnap = _firestore.collection(collection).get(
  //     const GetOptions(source: Source.cache),
  //   );
  //
  //   return querySnap.then((querySnap) {
  //     return querySnap.docs
  //         .map((doc) => DbRecord(id: doc.id, data: doc.data()))
  //         .toList();
  //   });
  // }

  Stream<List<FirestoreDocument>> streamAll({required String collection}) {
    final colRef = _firestore.collection(collection);
    return colRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => FirestoreDocument(id: doc.id, data: doc.data()))
          .toList();
    });
  }

  Stream<List<FirestoreDocument>> streamAllBy({
    required String collection,
    required String field,
    required String value,
  }) {
    final colRef = _firestore.collection(collection);
    final query = colRef.where(field, isEqualTo: value);
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => FirestoreDocument(id: doc.id, data: doc.data()))
          .toList();
    });
  }
}

final firestoreClientProvider = Provider<FirestoreClient>((ref){
  return FirestoreClient(firestore: ref.read(fireStoreProvider));
});