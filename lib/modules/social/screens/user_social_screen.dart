import 'package:arptc_connect/modules/social/screens/user_dependant_page.dart';
import 'package:arptc_connect/modules/social/screens/user_refund_page.dart';
import 'package:arptc_connect/modules/social/screens/user_vouchers_page.dart';
import 'package:flutter/material.dart';

/// User Social Screen
///
/// Tabbed interface for social module features using M3 design
class UserSocialScreen extends StatefulWidget {
  const UserSocialScreen({super.key});

  @override
  State<UserSocialScreen> createState() => _UserSocialScreenState();
}

class _UserSocialScreenState extends State<UserSocialScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Social'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.people_outline),
                text: "Dépendants",
              ),
              Tab(
                icon: Icon(Icons.receipt_long_outlined),
                text: "Bons",
              ),
              Tab(
                icon: Icon(Icons.payments_outlined),
                text: "Remboursements",
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            UserDependantPage(),
            UserVoucherPage(),
            UserRefundPage(),
          ],
        ),
      ),
    );
  }
}
