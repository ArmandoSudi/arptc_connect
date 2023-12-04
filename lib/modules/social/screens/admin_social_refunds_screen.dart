import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/refund.dart';

class AdminSocialRefundsScreen extends StatelessWidget {
  AdminSocialRefundsScreen({super.key});

  final db = FirebaseFirestore.instance;

  CollectionReference vouchersRef =
  FirebaseFirestore.instance.collection('refunds');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Liste des remboursements"),
      ),
      body: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
              stream: vouchersRef.snapshots(),
              builder: (context, snapshot) {

                if (snapshot.hasError) {
                  return const Text("something went wrong");
                }

                if (snapshot.data == null || snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (!snapshot.hasData) {
                  return const Text("There is no dependant yet");
                }

                return _buildRefundList(context, snapshot.data?.docs ?? []);
              }

          )
      ),
    );
  }

  Widget _buildRefundList( BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      children: snapshot.map((data) => _buildRefund(context, data)).toList(),
    );
  }

  Widget _buildRefund(BuildContext context, DocumentSnapshot data) {
    final refund = Refund.fromSnapshot(data);
    return ListTile(
      leading: const Icon(Icons.person),
      title: Text(refund.amount.toString() + " \$"),
      subtitle: Text(refund.hospital),
      trailing: refund.isApproved ? Text("Approuvé", style: TextStyle(color: Colors.green)) : Text("En attente", style: TextStyle(color: Colors.red)),
      onTap: () {
        debugPrint("Doc ID: ${refund.reference.id}");
        // Navigator.of(context).push(
        //   MaterialPageRoute(
        //     builder: (context) => DirectionDetailsScreen(),
        //   ),
        // );
      },
    );
  }
}
