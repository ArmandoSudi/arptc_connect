import 'dart:developer';

import 'package:arptc_connect/utils/firestore_document.dart';
import 'package:arptc_connect/utils/firestore_filter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/firebase_providers.dart';

class FirestoreClient {
  final FirebaseFirestore _firestore;

  FirebaseFirestore get firestore => _firestore;

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

  Future<void> delete({
    required String collection,
    required String id,
  }) async {
    try {
      final docRef = _firestore.collection(collection).doc(id);
      await docRef.delete();
    } catch (exception) {
      log("FireStoreClient::delete err => $exception");
      log("FireStoreClient::delete id => $id");
      throw Exception('Error deleting document: $exception');
    }
  }

  Future<void> update({
    required String collection,
    required Map<String,dynamic> data,
  }) async {
    try {
      final docRef = _firestore
          .collection(collection)
          .doc(data["id"] as String);
      await docRef.update(data);
    } catch (exception){
      log("FireStoreClient::update err => $exception");
      log("FireStoreClient::update data[id] => ${data["id"]}");
      throw Exception('Error updating document: $exception');
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
      throw Exception('Error fetching all documents: $err');
    }
  }

  Stream<List<FirestoreDocument>> streamAll({required String collection}) {
    try {
      final colRef = _firestore.collection(collection);
      return colRef.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => FirestoreDocument(id: doc.id, data: doc.data()))
            .toList();
      });
    } catch (err) {
      throw Exception('Error streaming all documents: $err');
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
      throw Exception('Error fetching all by documents: $err');
    }
  }

  // Fetch all documents with a multiple specific field values
  // Future<List<FirestoreDocument>> fetchAllByMultiple({
  //   required String collection,
  //   required Map<String, dynamic> filters,
  // }) async {
  //   try {
  //     Query query = _firestore.collection(collection);
  //     filters.forEach((field, value) {
  //       query = query.where(field, isEqualTo: value);
  //     });
  //     final documents = await query.get();
  //     return documents.docs
  //         .map((doc) => FirestoreDocument(id: doc.id, data: doc.data()))
  //         .toList();
  //   } catch (err) {
  //     throw Exception('Error fetching all by multiple documents: $err');
  //   }
  // }

  Future<FirestoreDocument> fetchById({
    required String collection,
    required String id,
  }) async {
    try {
      final docRef = _firestore.collection(collection).doc(id);
      final doc = await docRef.get();
      return FirestoreDocument(id: doc.id, data: doc.data()!);
    } catch (err) {
      throw Exception('Error fetching by id document: $err');
    }
  }

  Future<List<FirestoreDocument>> fetchWhereWithFilters({
    required String collection,
    required List<FirestoreFilter> filters,
  }) async {
    try {
      Query query = _firestore.collection(collection);
      for (final filter in filters) {
        query = query.where(
          filter.field,
          isEqualTo: filter.isEqualTo,
          isGreaterThan: filter.isGreaterThan,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
          isLessThan: filter.isLessThan,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
          arrayContains: filter.arrayContains,
          arrayContainsAny: filter.arrayContainsAny,
          whereIn: filter.whereIn,
          whereNotIn: filter.whereNotIn,
          isNull: filter.isNull,
        );
      }
      final documents = await query.get();
      return documents.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return FirestoreDocument(id: doc.id, data: data);
      }).toList();
    } catch (err) {
      throw Exception('Error fetching documents with filters: $err');
    }
  }

  // Stream version for real-time updates
  Stream<List<FirestoreDocument>> streamWhereWithFilters({
    required String collection,
    required List<FirestoreFilter> filters,
  }) {
    try {
      Query query = _firestore.collection(collection);
      for (final filter in filters) {
        query = query.where(
          filter.field,
          isEqualTo: filter.isEqualTo,
          isGreaterThan: filter.isGreaterThan,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
          isLessThan: filter.isLessThan,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
          arrayContains: filter.arrayContains,
          arrayContainsAny: filter.arrayContainsAny,
          whereIn: filter.whereIn,
          whereNotIn: filter.whereNotIn,
          isNull: filter.isNull,
        );
      }
      return query.snapshots().map((snapshot) => snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return FirestoreDocument(id: doc.id, data: data);
      }).toList());
    } catch (err) {
      throw Exception('Error streaming documents with filters: $err');
    }
  }
}

final firestoreClientProvider = Provider<FirestoreClient>((ref){
  return FirestoreClient(firestore: ref.read(fireStoreProvider));
});