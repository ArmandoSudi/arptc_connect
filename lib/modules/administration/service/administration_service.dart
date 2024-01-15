import 'dart:async';

import 'package:arptc_connect/models/agent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/direction.dart';
import '../../../models/service.dart';

class AdministrationAPI {
  final FirebaseFirestore _firestore;

  AdministrationAPI(this._firestore);

  CollectionReference get agents => _firestore.collection('agents');

  CollectionReference get services => _firestore.collection('services');

  CollectionReference get bureaux => _firestore.collection('bureaux');

  CollectionReference get directions => _firestore.collection('directions');

  Stream<List<Agent>> allAgents() {
    return agents
        .snapshots()
        .map((event) => event.docs.map((e) => Agent.fromDocument(e)).toList());
  }

  Stream<List<Direction>> allDirections() {
    return directions.snapshots().map(
        (event) => event.docs.map((e) => Direction.fromDocument(e)).toList());
  }

  Future<List<Direction>> fetchDirections() {
    return directions.get().then((querySnapshot) {
      return querySnapshot.docs
          .map((doc) => Direction.fromDocument(doc))
          .toList();
    }, onError: (e) {
      return [];
    });
  }

  Future<List<Service>> allServices() {
    return services.get().then((querySnapshot) {
      return querySnapshot.docs
          .map((doc) => Service.fromDocument(doc))
          .toList();
    }, onError: (e) {
      return [];
    });
  }

  Future<List<Service>> fetchBureaux() {
    return bureaux.get().then((querySnapshot) {
      return querySnapshot.docs
          .map((doc) => Service.fromDocument(doc))
          .toList();
    }, onError: (e) {
      return [];
    });
  }
}
