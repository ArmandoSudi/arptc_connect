import 'dart:async';

import 'package:arptc_connect/models/agent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/direction.dart';
import '../../../models/service.dart';

class AdministrationService {
  final FirebaseFirestore _firestore;

  AdministrationService(this._firestore);

  CollectionReference get agents => _firestore.collection('agents');
  CollectionReference get services => _firestore.collection('services');
  CollectionReference get directions => _firestore.collection('directions');

  Stream<List<Agent>> allAgents(){
    return agents.snapshots().map((event) => event.docs.map((e) => Agent.fromDocument(e)).toList());
  }

  Stream<List<Direction>> allDirections(){
    return directions.snapshots().map((event) => event.docs.map((e) => Direction.fromDocument(e)).toList());
  }

  Stream<List<Service>> allServices(){
    return services.snapshots().map((event) => event.docs.map((e) => Service.fromDocument(e)).toList());
  }
  
  // Future<List<Direction>> allDirections(){
  //
  //   try {
  //     directions.get().then((querySnapshot) {
  //       return querySnapshot.docs.map((doc) {
  //         Direction.fromDocument(doc);
  //       }).toList();
  //     },
  //         onError: (e) {
  //           return [];
  //         });
  //   } catch (e) {
  //     // print("allDirections::: ${e.toString()}");
  //     return Future.value([]);
  //   } finally {
  //     return Future.value([]);
  //   }
  // }


}