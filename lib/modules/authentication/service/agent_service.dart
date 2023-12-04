import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/agent.dart';
import '../../../utils/firebase_constants.dart';

class AgentService{

  AgentService(this._firestore);

  final FirebaseFirestore _firestore;

  // This getter will return a stream of all the agents
  CollectionReference get _agents => _firestore.collection(FirebaseConstants.agentsCollection);

  // Future<Map<String, dynamic>?> getAgentByEmail(String email) async {
  //   try {
  //     _firestore.collection('agents')
  //         .where("email", isEqualTo: email)
  //         .get()
  //         .then((value) => print("$value"));
  //   } catch (e) {
  //     log("getUserData::: ${e.toString()}");
  //     return null;
  //   }
  // }

  Future<Agent> getAgentByEmail(String email) {
    return _agents
        .doc(email)
        .get().then((snapshot) => Agent.fromDocument(snapshot));
  }


}