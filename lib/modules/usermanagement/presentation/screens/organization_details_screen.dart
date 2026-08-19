import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/user_management_access_gate.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/user_management_section_scaffold.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OrganizationDetailsScreen extends ConsumerWidget {
  const OrganizationDetailsScreen({
    required this.organizationId,
    super.key,
  });

  final String organizationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final organization = ref.watch(umOrganizationsProvider).whenData(
          (items) =>
              items.where((item) => item.id == organizationId).firstOrNull,
        );
    return UserManagementAccessGate(
      requirePrivateProfiles: true,
      child: UserManagementSectionScaffold(
        selectedIndex: 0,
        title: l10n.lookup('umOrganizationDetails'),
        subtitle: l10n.lookup('umOrganizationsDescription'),
        primaryAction: OutlinedButton.icon(
          onPressed: () => context.go('/service/usermanagement/organizations'),
          icon: const Icon(Icons.arrow_back),
          label: Text(l10n.back),
        ),
        primaryActionIsNavigation: true,
        body: organization.when(
          loading: () => LoadingStateView(message: l10n.lookup('umLoading')),
          error: (error, _) => ErrorStateView(
            title: l10n.lookup('umCommandFailed'),
            description: error.toString(),
          ),
          data: (item) {
            if (item == null) {
              return ErrorStateView(title: l10n.lookup('umNotFound'));
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              child: Text(
                                item.code.characters.take(2).toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  Text(item.code),
                                ],
                              ),
                            ),
                            Chip(label: Text(item.status.value)),
                          ],
                        ),
                        const Divider(height: 32),
                        _Detail(
                          label: l10n.lookup('umOrganizationDescription'),
                          value:
                              item.description.isEmpty ? '-' : item.description,
                        ),
                        _Detail(label: 'ID', value: item.id),
                        _Detail(
                          label: l10n.status,
                          value: item.status.value,
                        ),
                        _Detail(
                          label: 'Schema version',
                          value: item.schemaVersion.toString(),
                        ),
                        _Detail(
                          label: l10n.lookup('umActor'),
                          value: item.updatedBy.isEmpty
                              ? item.createdBy
                              : item.updatedBy,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () {
                            ref
                                .read(umSelectedOrganizationIdProvider.notifier)
                                .state = item.id;
                            context.go('/service/usermanagement/structure');
                          },
                          icon: const Icon(Icons.account_tree_outlined),
                          label: Text(l10n.lookup('umOpenStructure')),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            ref
                                .read(umSelectedOrganizationIdProvider.notifier)
                                .state = item.id;
                            context.go('/service/usermanagement/agents');
                          },
                          icon: const Icon(Icons.badge_outlined),
                          label: Text(l10n.lookup('umOpenAgents')),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.go(
                            '/service/usermanagement/organizations/'
                            '${item.id}/audit',
                          ),
                          icon: const Icon(Icons.history_outlined),
                          label: Text(l10n.lookup('umAuditHistory')),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
