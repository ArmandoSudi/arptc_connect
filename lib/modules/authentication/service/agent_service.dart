import 'package:arptc_connect/modules/administration/domain/models/agent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/firebase_constants.dart';

class AgentService {
  AgentService(this._firestore);

  final FirebaseFirestore _firestore;

  // This getter will return a stream of all the agents
  CollectionReference get _agents =>
      _firestore.collection(FirebaseConstants.agentsCollection);

  Future<Agent> getAgentById(String firebaseAuthUid) {
    return _agents
        .doc(firebaseAuthUid)
        .get()
        .then((snapshot) => Agent.fromDocument(snapshot));
  }
}
