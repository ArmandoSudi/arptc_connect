import 'package:arptc_connect/modules/administration/domain/models/refund.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:arptc_connect/widgets/status_chip.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// User Refund Page
///
/// Displays list of refund requests with M3 styling
class UserRefundPage extends StatelessWidget {
  UserRefundPage({super.key});

  final db = FirebaseFirestore.instance;

  final CollectionReference vouchersRef =
  FirebaseFirestore.instance.collection('agents/PyKV8iGiDzcTdQSaRzWD/refunds');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: vouchersRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const ErrorStateView(
                title: "Something went wrong",
                description: "Unable to load refunds",
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingStateView(message: "Loading refunds...");
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const EmptyStateView(
                icon: Icons.payments_outlined,
                title: "No refunds yet",
                description: "Your refund requests will appear here",
              );
            }

            return _buildRefundList(context, snapshot.data!.docs);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Request refund
        },
        icon: const Icon(Icons.add),
        label: const Text("Request Refund"),
      ),
    );
  }

  Widget _buildRefundList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: snapshot.length,
      itemBuilder: (context, index) => _buildRefund(context, snapshot[index]),
    );
  }

  Widget _buildRefund(BuildContext context, DocumentSnapshot data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final refund = Refund.fromSnapshot(data);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.tertiaryContainer,
        child: Icon(
          Icons.receipt_long,
          color: colorScheme.onTertiaryContainer,
        ),
      ),
      title: Text(
        "${refund.amount} FC",
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        refund.hospital,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      trailing: StatusChip(
        label: refund.isApproved ? "Approuvé" : "En attente",
        type: refund.isApproved ? StatusType.success : StatusType.warning,
      ),
      onTap: () {
        debugPrint("Doc ID: ${refund.reference.id}");
      },
    );
  }
}
