import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';

import '../../../models/voucher.dart';

class SocialVouchersPage extends StatefulWidget {
  const SocialVouchersPage({super.key});

  @override
  State<SocialVouchersPage> createState() => _SocialVouchersPageState();
}

class _SocialVouchersPageState extends State<SocialVouchersPage> {

  final db = FirebaseFirestore.instance;
  bool _isSearching = false;

  CollectionReference agentsRef =
  FirebaseFirestore.instance.collection('vouchers');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // title: _isSearching ? CupertinoSearchTextField() : Container(),
        title: const CupertinoSearchTextField(placeholder: "Rechercher un bon",),
      ),
      body: Padding(
          padding: ResponsiveBreakpoints.of(context).isMobile
              ? const EdgeInsets.all(16)
              : const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: StreamBuilder<QuerySnapshot>(
              stream: agentsRef.snapshots(),
              builder: (context, snapshot) {

                if (snapshot.hasError) {
                  return const Text("Une erreur est survenue");
                }

                if (snapshot.data == null || snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (!snapshot.hasData) {
                  return const Text("Il n'y a aucun bon");
                }

                List<Voucher>? vouchers = snapshot.data?.docs.map((data) => Voucher.fromSnapshot(data)).toList();

                return Card(
                    child: ListView.separated(
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(vouchers![index].agentName),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              debugPrint("Doc ID: ${vouchers?[index].reference}");
                              // Navigator.of(context).push(
                              //   MaterialPageRoute(
                              //     builder: (context) => DirectionDetailsScreen(),
                              //   ),
                              // );
                            },
                          );
                        },
                        separatorBuilder: (context, index) => Divider(),
                        itemCount: vouchers?.length ?? 0)
                );
              }

          )
      ),
    );
  }
}
