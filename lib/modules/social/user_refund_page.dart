import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/refund.dart';

class UserRefundPage extends StatelessWidget {
  UserRefundPage({super.key});

  final db = FirebaseFirestore.instance;

  CollectionReference vouchersRef =
  FirebaseFirestore.instance.collection('agents/PyKV8iGiDzcTdQSaRzWD/refunds');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
              stream: vouchersRef.snapshots(),
              builder: (context, snapshot) {

                if (snapshot.hasError) {
                  return const Text("something wen wrong");
                }

                if (snapshot.data == null || snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (!snapshot.hasData) {
                  return const Text("There is no dependant yet");
                }
                // print("Directions size : ${snapshot.data!.length}");
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
      title: Text("${refund.amount}"),
      subtitle: Text("${refund.hospital}"),
      trailing: refund.isApproved ? Text("Approuvé", style: TextStyle(color: Colors.green)) : Text("En attente", style: TextStyle(color: Colors.red)),
      onTap: () {
        debugPrint("Doc ID: ${refund.reference.id}");
      },
    );
  }
}
