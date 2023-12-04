import 'package:arptc_connect/modules/social/screens/admin_social_dashboard_page.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class MainDashboardScreen extends StatelessWidget {
  const MainDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ContentView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const PageHeader(title: "Dashboard", description: "Bureau Social"),
          Gap(16),
          // This Part will be loaded dynamically depending on the user role
          AdminSocialStatistics(),
        ],
      ),
    );
  }
}
