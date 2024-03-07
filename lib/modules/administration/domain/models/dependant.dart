import 'package:cloud_firestore/cloud_firestore.dart';

class Dependant {
  final String name;
  final String relationship;
  final String imageURL;
  final DocumentReference reference;

  Dependant.fromMap(Map<String, dynamic> map, {required this.reference})
      : assert(map['name'] != null),
        assert(map['relationship'] != null),
        name = map['name'],
        relationship = map['relationship'],
        imageURL = map['image_url'];

  Dependant.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data() as Map<String, dynamic>, reference: snapshot.reference);

  @override
  String toString() => "Dependant:: <$name>";
}