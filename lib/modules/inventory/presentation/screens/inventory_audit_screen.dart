import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../application/inventory_providers.dart';
import '../widgets/inventory_shell.dart';

class InventoryAuditScreen extends ConsumerWidget {
  const InventoryAuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final events = ref.watch(inventoryAuditProvider(100));
    return InventoryShell(
      title: l10n.lookup('invAuditHistory'),
      subtitle: l10n.lookup('invAdminSubtitle'),
      onBack: () => context.pop(),
      child: events.when(
        loading: () => LoadingStateView(message: l10n.loading),
        error: (error, _) => ErrorStateView(
          title: l10n.unableToLoad,
          description: error.toString(),
        ),
        data: (entries) => entries.isEmpty
            ? EmptyStateView(
                icon: Icons.policy_outlined,
                title: l10n.lookup('invNoAuditEvents'),
              )
            : InventoryPanel(
                child: Column(
                  children: [
                    for (final event in entries)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          child: Icon(Icons.history_rounded),
                        ),
                        title: Text(event.action.replaceAll('_', ' ')),
                        subtitle: Text(
                          '${event.entityType} / ${event.entityId}\n${event.actor.name}${event.reason.isEmpty ? '' : ' | ${event.reason}'}',
                        ),
                        isThreeLine: true,
                        trailing: Text(_date(event.createdAt)),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

String _date(DateTime? value) =>
    value == null ? '-' : DateFormat.yMMMd().add_Hm().format(value.toLocal());
