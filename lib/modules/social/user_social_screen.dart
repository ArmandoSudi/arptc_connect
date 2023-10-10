import 'package:arptc_connect/modules/social/user_dependant_page.dart';
import 'package:arptc_connect/modules/social/user_refund_page.dart';
import 'package:arptc_connect/modules/social/user_vouchers_page.dart';
import 'package:flutter/material.dart';

class UserSocialScreen extends StatefulWidget {
  const UserSocialScreen({super.key});

  @override
  State<UserSocialScreen> createState() => _UserSocialScreenState();
}

class _UserSocialScreenState extends State<UserSocialScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(text: "Dependants"),
                Tab(text: "Bons"),
                Tab(text: "Remboursements"),
              ],
            ),
            title: const Text('Social'),
          ),
          body: TabBarView(
            children: [
              UserDependantPage(),
              UserVoucherPage(),
              UserRefundPage(),
            ],
          ),
        ),
      ),
    );
  }
}


