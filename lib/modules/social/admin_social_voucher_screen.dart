import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/voucher.dart';

class AdminSocialVouchersScreen extends StatelessWidget {
  AdminSocialVouchersScreen({super.key});

  final db = FirebaseFirestore.instance;

  CollectionReference vouchersRef =
  FirebaseFirestore.instance.collection('vouchers');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Liste des bons"),
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

                return _buildVoucherList(context, snapshot.data?.docs ?? []);
              }

          )
      ),
    );
  }

  Widget _buildVoucherList( BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      children: snapshot.map((data) => _buildVoucher(context, data)).toList(),
    );
  }

  Widget _buildVoucher(BuildContext context, DocumentSnapshot data) {
    final voucher = Voucher.fromSnapshot(data);
    return ListTile(
      leading: const Icon(Icons.person),
      title: Text(voucher.agentName),
      subtitle: Text(voucher.dependantName),
      trailing: voucher.isApproved ? Text("Approuvé", style: TextStyle(color: Colors.green)) : Text("En attente", style: TextStyle(color: Colors.red)),
      onTap: () {
        debugPrint("Doc ID: ${voucher.reference.id}");
        // Navigator.of(context).push(
        //   MaterialPageRoute(
        //     builder: (context) => DirectionDetailsScreen(),
        //   ),
        // );
      },
    );
  }
}
