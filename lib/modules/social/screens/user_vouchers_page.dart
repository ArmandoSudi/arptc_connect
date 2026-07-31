import 'package:arptc_connect/modules/administration/domain/models/voucher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserVoucherPage extends StatelessWidget {
  UserVoucherPage({super.key});

  final db = FirebaseFirestore.instance;

  final CollectionReference vouchersRef = FirebaseFirestore.instance
      .collection('agents/PyKV8iGiDzcTdQSaRzWD/vouchers');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
              stream: vouchersRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _ErrorView(message: "Something went wrong");
                }

                if (snapshot.data == null ||
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const _EmptyView(message: "No vouchers yet");
                }
                return _buildVoucherList(context, snapshot.data?.docs ?? []);
              })),
    );
  }

  Widget _buildVoucherList(
      BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: snapshot.length,
      itemBuilder: (context, index) => _buildVoucher(context, snapshot[index]),
    );
  }

  Widget _buildVoucher(BuildContext context, DocumentSnapshot data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final voucher = Voucher.fromSnapshot(data);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        child: Icon(
          Icons.receipt_long,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(voucher.agentName),
      subtitle: Text(
        voucher.dependantName,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      trailing: _StatusChip(
        isApproved: voucher.isApproved,
      ),
      onTap: () {
        debugPrint("Doc ID: ${voucher.reference.id}");
      },
    );
  }
}

/// Status chip for voucher approval state
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isApproved});

  final bool isApproved;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isApproved
            ? Colors.green.withOpacity(0.15)
            : colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        isApproved ? "Approuvé" : "En attente",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color:
              isApproved ? Colors.green.shade700 : colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}

/// Empty state view
class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Error state view
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}
