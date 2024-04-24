import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:arptc_connect/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../widgets/bar_chart.dart';
import '../widgets/line_chart.dart';
import '../widgets/ticketing_pie_chart.dart';

class MainDashboardScreen extends StatelessWidget {
  const MainDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveCenter(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Gap(16),
            PageHeader(title: "Tableaud de bord", description: ""),
            Gap(32),
            Card(child: PieChartSample2()),
            Gap(32),
            Card(child: BarChartSample3()),
            Gap(32),
            Card(child: LineChartSample1()),
            // This Part will be loaded dynamically depending on the user role
            // AdminSocialStatistics(),
          ],
        ),
      ),
    );
  }
}
