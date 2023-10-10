import 'package:arptc_connect/modules/social/admin_social_refunds_screen.dart';
import 'package:arptc_connect/modules/social/admin_social_voucher_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../administration/screens/agents_screen.dart';

class AdminSocialDashboardPage extends StatelessWidget {
  AdminSocialDashboardPage({super.key});

  final db = FirebaseFirestore.instance;

  DocumentReference socialRef =
      FirebaseFirestore.instance.collection('dashboard').doc('social');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Social"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<DocumentSnapshot>(
          future: socialRef.get(),
          builder:
              (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.hasError) {
              return Text('Failed loading user data');
            }
            if (snapshot.hasData && !snapshot.data!.exists) {
              return Text('User data does not exist');
            }
            if (snapshot.connectionState == ConnectionState.done) {
              Map<String, dynamic> data =
                  snapshot.data!.data() as Map<String, dynamic>;
              return Column(
                children: [
                  Card(
                      color: const Color(0xFFCDE7FB),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${data['agent_count']}",
                                  style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Text(
                                  "Agents",
                                  style: TextStyle(fontSize: 22),
                                ),
                                const SizedBox(height: 20),
                                OutlinedButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  AgentsScreen()));
                                    },
                                    child: const Text("    Voir    "),
                                    style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.black,
                                        side: BorderSide(color: Colors.black)))
                              ],
                            ),
                            const Icon(
                              Icons.person,
                              size: 100,
                              color: Colors.white,
                            )
                          ],
                        ),
                      )),
                  Card(
                      color: const Color(0xFFDAF9CF),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${data['voucher_count']}",
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  "Demandes de Bon",
                                  style: TextStyle(fontSize: 22),
                                ),
                                const SizedBox(height: 20),
                                OutlinedButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AdminSocialVouchersScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text("    Voir    "),
                                    style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.black,
                                        side: BorderSide(color: Colors.black)))
                              ],
                            ),
                            const Icon(
                              Icons.file_present_outlined,
                              size: 100,
                              color: Colors.white,
                            )
                          ],
                        ),
                      )),
                  Card(
                      color: const Color(0xFFF5F5F5),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${data['refund_count']}",
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Demandes de Remboursement",
                                    softWrap: true,
                                    maxLines: 2,
                                    style: TextStyle(fontSize: 22),
                                  ),
                                  const SizedBox(height: 20),
                                  OutlinedButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AdminSocialRefundsScreen(),
                                          ),
                                        );
                                      },
                                      child: Text("    Voir    "),
                                      style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.black,
                                          side:
                                              BorderSide(color: Colors.black)))
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.monetization_on_outlined,
                              size: 100,
                              color: Colors.white,
                            )
                          ],
                        ),
                      )),
                ],
              );
            }
            return const Text('Loading user data');
          },
        ),
      ),
    );
  }
}
