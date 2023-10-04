import 'package:cloud_firestore/cloud_firestore.dart';

class Agent {
  final String name;
  final String email;
  final String genre;
  final String matricule;
  final String dob;
  String? direction;
  String? service;
  String? bureau;
  String? fonction;
  final String category;
  final List<String> roles;
  final DocumentReference reference;

  Agent.fromMap(Map<String, dynamic> map, {required this.reference})
      : assert(map['name'] != null),
        assert(map['email'] != null),
        assert(map['genre'] != null),
        assert(map['matricule'] != null),
        name = map['name'],
        email = map['email'],
        genre = map['genre'],
        matricule = map['matricule'],
        dob = map['dob'],
        category = map['category'],
        roles = map['roles'].cast<String>(),
        direction = map['direction'],
        service = map['service'];
        // bureau = map['bureau'],
        // fonction = map['fonction'];

  Agent.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data() as Map<String, dynamic>, reference: snapshot.reference);

  @override
  String toString() => "Agent:: <$name>";
}