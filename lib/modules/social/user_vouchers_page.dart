import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/voucher.dart';

class UserVoucherPage extends StatelessWidget {
  UserVoucherPage({super.key});

  final db = FirebaseFirestore.instance;

  CollectionReference vouchersRef =
  FirebaseFirestore.instance.collection('agents/PyKV8iGiDzcTdQSaRzWD/voucher');

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
      title: Text(voucher.name),
      trailing: voucher.status ? Text("Approuvé", style: TextStyle(color: Colors.green)) : Text("En attente", style: TextStyle(color: Colors.red)),
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
