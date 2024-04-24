import 'dart:async';
import 'dart:developer';

import 'package:arptc_connect/modules/administration/domain/models/agent.dart';
import 'package:arptc_connect/modules/administration/domain/models/direction.dart';
import 'package:arptc_connect/modules/administration/domain/models/service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/firestore_client.dart';
import 'models/bureau.dart';
import 'models/dependant.dart';

class AdministrationAPI {
  final FirebaseFirestore firestore;
  final FirestoreClient firestoreClient;

  AdministrationAPI({required this.firestore, required this.firestoreClient});

  CollectionReference get agents => firestore.collection('agents');

  CollectionReference get services => firestore.collection('services');

  CollectionReference get bureaux => firestore.collection('bureaux');

  CollectionReference get directions => firestore.collection('directions');

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

  Future<Direction> getDirectionById(String id) async {
    try{
      final result = await firestoreClient.fetchById(collection: "directions", id: id);
      return Direction.fromJson(result.data);
    } catch (err) {
      log("getDirectionById => Error : $err");
      throw (Exception(err));
    }
  }

  Future<void> addDirection(Direction direction) {
    return directions.add(direction.toJson());
  }

  Future<void> deleteDirection(String id) {
    return directions.doc(id).delete();
  }

  Future<void> addService(Service service){
    return services.add(service.toJson());
  }

  Future<void> deleteService(String id){
    return services.doc(id).delete();
  }

  Future<void> addBureau(Bureau bureau){
    return bureaux.add(bureau.toJson());
  }

  Future<void> deleteBureau(String id){
    return bureaux.doc(id).delete();
  }

  Future<Agent> getAgentById(String id) async {
    try{
      final result = await firestoreClient.fetchById(collection: "agents", id: id);
      return Agent.fromJson(result.data);
    } catch (err) {
      log("getAgentById => Error : $err");
      throw (Exception(err));
    }
  }

  Future<List<Dependant>> fetchDependants(String agentId) async {
    try {
      final results = await firestoreClient.fetchAll(collection: "agents/$agentId/dependants");
      return results.map((item) => Dependant.fromMap(item.data, id: item.id)).toList();
    }
    catch(err){
      log("AdministrationAPI: fetchDependants couldn't fetch");
      return [];
    }
  }
}
