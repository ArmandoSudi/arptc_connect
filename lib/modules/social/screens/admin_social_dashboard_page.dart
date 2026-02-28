import 'package:arptc_connect/modules/social/screens/admin_social_refunds_screen.dart';
import 'package:arptc_connect/modules/social/screens/admin_social_voucher_screen.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../administration/presentation/screens/agents_screen.dart';

/// Admin Social Statistics Dashboard
///
/// Displays key metrics in M3 styled dashboard cards
class AdminSocialStatistics extends StatelessWidget {
  AdminSocialStatistics({super.key});

  final db = FirebaseFirestore.instance;

  final DocumentReference socialRef =
      FirebaseFirestore.instance.collection('dashboard').doc('social');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Dashboard'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<DocumentSnapshot>(
            future: socialRef.get(),
            builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (snapshot.hasError) {
                return const ErrorStateView(
                  title: 'Error loading data',
                  description: 'Failed to load dashboard statistics',
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingStateView(message: 'Loading statistics...');
              }

              if (snapshot.hasData && !snapshot.data!.exists) {
                return const ErrorStateView(
                  title: 'No data available',
                  description: 'Dashboard data does not exist',
                );
              }

              Map<String, dynamic> data =
                  snapshot.data!.data() as Map<String, dynamic>;

              return LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive grid based on screen width
                  final crossAxisCount = constraints.maxWidth > 900
                      ? 3
                      : constraints.maxWidth > 600
                          ? 2
                          : 1;

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _DashboardCard(
                        title: 'Agents',
                        count: '${data['agent_count'] ?? 0}',
                        icon: Icons.people_outline,
                        iconFilled: Icons.people,
                        color: Colors.blue,
                        onViewPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AgentsScreen(),
                            ),
                          );
                        },
                      ),
                      _DashboardCard(
                        title: 'Demandes de Bon',
                        count: '${data['voucher_count'] ?? 0}',
                        icon: Icons.receipt_long_outlined,
                        iconFilled: Icons.receipt_long,
                        color: Colors.green,
                        onViewPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AdminSocialVouchersScreen(),
                            ),
                          );
                        },
                      ),
                      _DashboardCard(
                        title: 'Remboursements',
                        count: '${data['refund_count'] ?? 0}',
                        icon: Icons.payments_outlined,
                        iconFilled: Icons.payments,
                        color: Colors.orange,
                        onViewPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AdminSocialRefundsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Material Design 3 Dashboard Card
///
/// A metric card with icon, count, title, and action button
class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.iconFilled,
    required this.color,
    required this.onViewPressed,
  });

  final String title;
  final String count;
  final IconData icon;
  final IconData iconFilled;
  final Color color;
  final VoidCallback onViewPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 28,
                      color: color,
                    ),
                  ),
                  Text(
                    count,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: onViewPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: color.withOpacity(0.15),
                    foregroundColor: color.withOpacity(1),
                  ),
                  child: const Text('View All'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
