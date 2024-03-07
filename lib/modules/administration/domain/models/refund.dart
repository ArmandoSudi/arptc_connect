import 'package:cloud_firestore/cloud_firestore.dart';

class Refund {
  final String agentName;
  final String agentReference;
  final String amount;
  final String hospital;
  final bool isApproved;
  final DateTime date;
  final DocumentReference reference;

  Refund.fromMap(Map<String, dynamic> map, {required this.reference})
      : assert(map['amount'] != null),
        assert(map['hospital'] != null),
        agentName = map['agent_name'],
        agentReference = map['agent_reference'],
        amount = map['amount'],
        hospital = map['hospital'],
        isApproved = map['is_approved'],
        date = map['date'].toDate();

  Refund.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data() as Map<String, dynamic>, reference: snapshot.reference);

  @override
  String toString() => "Refund:: <$amount> - <$hospital>";
}