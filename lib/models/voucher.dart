import 'package:cloud_firestore/cloud_firestore.dart';

class Voucher {
  final String agentName;
  final String dependantName;
  final bool isApproved;
  final String imageURL;
  final String agentReference;
  final String relationShip;
  final DocumentReference reference;

  Voucher.fromMap(Map<String, dynamic> map, {required this.reference})
      : assert(map['agent_name'] != null),
        assert(map['is_approved'] != null),
        agentName = map['agent_name'],
        dependantName = map['dependant_name'],
        isApproved = map['is_approved'],
        imageURL = map['image_url'],
        agentReference = map['agent_reference'],
        relationShip = map['relationship'];

  Voucher.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data() as Map<String, dynamic>, reference: snapshot.reference);

  @override
  String toString() => "Voucher:: <$agentName> - <$dependantName>";
}