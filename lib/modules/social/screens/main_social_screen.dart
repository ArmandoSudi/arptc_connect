import 'package:arptc_connect/modules/social/screens/social_agents_page.dart';
import 'package:arptc_connect/modules/social/screens/social_refunds_page.dart';
import 'package:arptc_connect/modules/social/screens/social_vouchers_page.dart';
import 'package:flutter/material.dart';

class MainSocialScreen extends StatelessWidget {
  const MainSocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: "Agents"),
              Tab(text: "Bons"),
              Tab(text: "Remboursements"),
            ],
          ),
          title: const Text("Bureau Social")
        ),
        body: TabBarView(
          children: [
            SocialAgentsPage(),
            SocialVouchersPage(),
            SocialRefundsPage(),
          ],
        ),
      ),
    );
  }
}