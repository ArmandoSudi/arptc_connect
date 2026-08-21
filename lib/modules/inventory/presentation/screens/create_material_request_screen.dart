import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/domain/agent_directory_entry.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/widgets/app_search_bar.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/inventory_contracts.dart';
import '../../application/inventory_providers.dart';
import '../../domain/inventory_access.dart';
import '../widgets/inventory_shell.dart';

class CreateMaterialRequestScreen extends ConsumerStatefulWidget {
  const CreateMaterialRequestScreen({super.key});

  @override
  ConsumerState<CreateMaterialRequestScreen> createState() =>
      _CreateMaterialRequestScreenState();
}

class _CreateMaterialRequestScreenState
    extends ConsumerState<CreateMaterialRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _justification = TextEditingController();
  final _destination = TextEditingController();
  AgentDirectoryEntry? _requestedFor;

  @override
  void dispose() {
    _justification.dispose();
    _destination.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final session = ref.watch(inventorySessionProvider).valueOrNull;
    if (session == null) return const SizedBox.shrink();
    final draft = ref.watch(inventoryRequestDraftProvider(session.sessionKey));
    final agents = ref.watch(umCurrentOrganizationAgentDirectoryProvider);
    return InventoryShell(
      title: l10n.lookup('invRequestCart'),
      subtitle: l10n.lookup('invUserSubtitle'),
      onBack: () => context.pop(),
      child: draft.lines.isEmpty
          ? EmptyStateView(
              icon: Icons.shopping_basket_outlined,
              title: l10n.lookup('invCartEmpty'),
              actionLabel: l10n.lookup('invCatalogue'),
              onAction: () => context.go('/service/inventory/catalog'),
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InventoryPanel(
                    title: l10n.lookup('invRequestItems'),
                    child: Column(
                      children: [
                        for (final line in draft.lines)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(line.item.name),
                            subtitle: Text(
                              '${line.quantity.format()} ${line.item.unitOfMeasureName}',
                            ),
                            trailing: IconButton(
                              onPressed: () => ref
                                  .read(inventoryRequestDraftProvider(
                                          session.sessionKey)
                                      .notifier)
                                  .remove(line.item.id),
                              icon: const Icon(Icons.delete_outline_rounded),
                              tooltip: l10n.delete,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  InventoryPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (session.role == InventoryRole.manager) ...[
                          _AgentSelectionField(
                            selected: _requestedFor,
                            agents: agents.valueOrNull ?? const [],
                            onSelect: (agent) =>
                                setState(() => _requestedFor = agent),
                          ),
                          const SizedBox(height: 16),
                        ],
                        CommonTextInput(
                          label: l10n.lookup('invDeliveryDestination'),
                          controller: _destination,
                          validator: _required,
                        ),
                        const SizedBox(height: 16),
                        CommonTextInput(
                          label: l10n.lookup('invJustification'),
                          controller: _justification,
                          isMultiline: true,
                        ),
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: ref
                                  .watch(inventoryCommandControllerProvider)
                                  .isLoading
                              ? null
                              : () => _submit(session.sessionKey),
                          icon: const Icon(Icons.send_rounded),
                          label: Text(l10n.lookup('invSubmitRequest')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? S.of(context).lookup('invRequired')
      : null;

  Future<void> _submit(String sessionKey) async {
    final session = ref.read(inventorySessionProvider).valueOrNull;
    final draft = ref.read(inventoryRequestDraftProvider(sessionKey));
    if (session == null || !_formKey.currentState!.validate()) return;
    if (session.role == InventoryRole.manager && _requestedFor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).lookup('invSelectAgent'))),
      );
      return;
    }
    try {
      final result =
          await ref.read(inventoryCommandControllerProvider.notifier).execute(
        functionName: InventoryCommands.submitRequest,
        commandId: ref.read(inventoryCommandIdFactoryProvider)(),
        payload: {
          if (_requestedFor != null) 'requestedForUserId': _requestedFor!.id,
          'deliveryDestination': _destination.text.trim(),
          'justification': _justification.text.trim(),
          'lines': [
            for (final line in draft.lines)
              {
                'itemId': line.item.id,
                'quantityMilli': line.quantity.milliUnits,
              },
          ],
        },
      );
      ref.read(inventoryRequestDraftProvider(sessionKey).notifier).clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).lookup('invRequestSubmitted'))),
      );
      context.go('/service/inventory/requests/${result.entityId}');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }
}

class _AgentSelectionField extends StatelessWidget {
  const _AgentSelectionField({
    required this.selected,
    required this.agents,
    required this.onSelect,
  });

  final AgentDirectoryEntry? selected;
  final List<AgentDirectoryEntry> agents;
  final ValueChanged<AgentDirectoryEntry> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return InkWell(
      onTap: () async {
        final value = await showDialog<AgentDirectoryEntry>(
          context: context,
          builder: (context) => _AgentPickerDialog(agents: agents),
        );
        if (value != null) onSelect(value);
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.lookup('invRequestedFor'),
          suffixIcon: const Icon(Icons.search_rounded),
        ),
        child: Text(
          selected?.displayName ?? l10n.lookup('invSelectAgent'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _AgentPickerDialog extends StatefulWidget {
  const _AgentPickerDialog({required this.agents});

  final List<AgentDirectoryEntry> agents;

  @override
  State<_AgentPickerDialog> createState() => _AgentPickerDialogState();
}

class _AgentPickerDialogState extends State<_AgentPickerDialog> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final normalized = _search.trim().toLowerCase();
    final filtered = widget.agents
        .where((agent) =>
            normalized.isEmpty ||
            '${agent.displayName} ${agent.email}'
                .toLowerCase()
                .contains(normalized))
        .toList(growable: false);
    return AlertDialog(
      title: Text(l10n.lookup('invSelectAgent')),
      content: SizedBox(
        width: 560,
        height: 460,
        child: Column(
          children: [
            AppSearchBar(
              hintText: l10n.lookup('invSelectAgent'),
              onChanged: (value) => setState(() => _search = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final agent = filtered[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline_rounded),
                    ),
                    title: Text(agent.displayName),
                    subtitle: Text(agent.organizationBreadcrumb),
                    onTap: () => Navigator.pop(context, agent),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
