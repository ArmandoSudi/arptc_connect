import 'package:cloud_firestore/cloud_firestore.dart';

class Dependant {
  final String name;
  final String relation;
  final DocumentReference reference;

  Dependant.fromMap(Map<String, dynamic> map, {required this.reference})
      : assert(map['name'] != null),
        assert(map['relation'] != null),
        name = map['name'],
        relation = map['relation'];

  Dependant.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data() as Map<String, dynamic>, reference: snapshot.reference);

  @override
  String toString() => "Dependant:: <$name>";
}