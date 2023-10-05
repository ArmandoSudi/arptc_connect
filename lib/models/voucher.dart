import 'package:cloud_firestore/cloud_firestore.dart';

class Voucher {
  final String name;
  final bool status;
  final DocumentReference reference;

  Voucher.fromMap(Map<String, dynamic> map, {required this.reference})
      : assert(map['name'] != null),
        assert(map['status'] != null),
        name = map['name'],
        status = map['status'];

  Voucher.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data() as Map<String, dynamic>, reference: snapshot.reference);

  @override
  String toString() => "Voucher:: <$name>";
}