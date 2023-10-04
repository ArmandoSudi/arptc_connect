import 'package:cloud_firestore/cloud_firestore.dart';

class Entity {
  final String name;
  final String shortName;
  final DocumentReference reference;

  Entity.fromMap(Map<String, dynamic> map, {required this.reference})
      : assert(map['name'] != null),
        assert(map['short_name'] != null),
        name = map['name'],
        shortName = map['short_name'];

  Entity.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data() as Map<String, dynamic>, reference: snapshot.reference);

  @override
  String toString() => "Direction:: <$name>";
}