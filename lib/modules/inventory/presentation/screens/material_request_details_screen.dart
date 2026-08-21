import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/domain/agent_directory_entry.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../application/inventory_contracts.dart';
import '../../application/inventory_providers.dart';
import '../../domain/inventory_domain.dart';
import '../widgets/inventory_reason_field.dart';
import '../widgets/inventory_shell.dart';
import '../widgets/inventory_status_badge.dart';

class MaterialRequestDetailsScreen extends ConsumerWidget {
  const MaterialRequestDetailsScreen({required this.requestId, super.key});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final request = ref.watch(materialRequestProvider(requestId));
    final lines = ref.watch(materialRequestLinesProvider(requestId));
    final allocations =
        ref.watch(materialRequestAllocationsProvider(requestId));
    final session = ref.watch(inventorySessionProvider).valueOrNull;
    final agents = ref.watch(umCurrentOrganizationAgentDirectoryProvider);
    return request.when(
      loading: () => Scaffold(body: LoadingStateView(message: l10n.loading)),
      error: (error, _) => Scaffold(
        body: ErrorStateView(
          title: l10n.unableToLoad,
          description: error.toString(),
        ),
      ),
      data: (value) {
        if (value == null || session == null) {
          return Scaffold(
            body: EmptyStateView(
              icon: Icons.receipt_long_outlined,
              title: l10n.notAvailable,
            ),
          );
        }
        final requestLines = lines.valueOrNull ?? const <MaterialRequestLine>[];
        final requestAllocations =
            allocations.valueOrNull ?? const <MaterialRequestAllocation>[];
        return InventoryShell(
          title: value.requestNumber,
          subtitle: l10n.lookup('invRequestDetails'),
          onBack: () => context.pop(),
          actions: _actions(
            context,
            ref,
            value,
            requestLines,
            requestAllocations,
            agents.valueOrNull ?? const [],
            session.userId,
            session.role,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RequestHeader(request: value),
              const SizedBox(height: 18),
              _RequestProgress(status: value.status),
              const SizedBox(height: 18),
              InventoryPanel(
                title: l10n.lookup('invRequestItems'),
                child: lines.when(
                  loading: () => LoadingStateView(message: l10n.loading),
                  error: (error, _) => Text(error.toString()),
                  data: (entries) => Column(
                    children: [
                      for (final line in entries)
                        _RequestLineCard(
                          request: value,
                          line: line,
                          allocations: requestAllocations
                              .where((entry) => entry.lineId == line.id)
                              .toList(growable: false),
                          canOperate: session.role == InventoryRole.manager &&
                              value.assignedManager?.userId == session.userId &&
                              [
                                MaterialRequestStatus.underReview,
                                MaterialRequestStatus.adjusted,
                              ].contains(value.status),
                        ),
                    ],
                  ),
                ),
              ),
              if (value.rejectedReason.isNotEmpty ||
                  value.cancelledReason.isNotEmpty ||
                  value.shortfallReason.isNotEmpty) ...[
                const SizedBox(height: 18),
                InventoryPanel(
                  title: l10n.lookup('invReason'),
                  child: Text([
                    value.rejectedReason,
                    value.cancelledReason,
                    value.shortfallReason,
                  ].where((entry) => entry.isNotEmpty).join('\n')),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  List<Widget> _actions(
    BuildContext context,
    WidgetRef ref,
    MaterialRequest request,
    List<MaterialRequestLine> lines,
    List<MaterialRequestAllocation> allocations,
    List<AgentDirectoryEntry> agents,
    String userId,
    InventoryRole role,
  ) {
    final l10n = S.of(context);
    final rejectionReasons = ref
            .watch(inventoryParametersProvider(
              InventoryParameterType.rejectionReason,
            ))
            .valueOrNull ??
        const <InventoryParameter>[];
    final shortfallReasons = ref
            .watch(inventoryParametersProvider(
              InventoryParameterType.shortfallReason,
            ))
            .valueOrNull ??
        const <InventoryParameter>[];
    if (role == InventoryRole.user) {
      return [
        if (request.canBeCancelledBy(userId))
          OutlinedButton.icon(
            onPressed: () => _reasonCommand(
              context,
              ref,
              InventoryCommands.cancelRequest,
              request.id,
              l10n.lookup('invCancelRequest'),
              reasonOptional: true,
            ),
            icon: const Icon(Icons.cancel_outlined),
            label: Text(l10n.lookup('invCancelRequest')),
          ),
        if (request.canBeConfirmedBy(userId))
          FilledButton.icon(
            onPressed: () => _simpleCommand(
              context,
              ref,
              InventoryCommands.confirmReceipt,
              request.id,
            ),
            icon: const Icon(Icons.fact_check_outlined),
            label: Text(l10n.lookup('invConfirmReceipt')),
          ),
      ];
    }
    if (role != InventoryRole.manager) return const [];
    final assignedId = request.assignedManager?.userId ?? '';
    final assignedToMe = assignedId == userId;
    return [
      if (request.status == MaterialRequestStatus.submitted &&
          assignedId.isEmpty)
        FilledButton.icon(
          onPressed: () => _simpleCommand(
            context,
            ref,
            InventoryCommands.startReview,
            request.id,
          ),
          icon: const Icon(Icons.manage_search_rounded),
          label: Text(l10n.lookup('invStartReview')),
        ),
      if (assignedId.isNotEmpty && !assignedToMe && !request.status.isTerminal)
        FilledButton.tonalIcon(
          onPressed: () => _reasonCommand(
            context,
            ref,
            InventoryCommands.takeOverRequest,
            request.id,
            l10n.lookup('invTakeOver'),
          ),
          icon: const Icon(Icons.assignment_ind_outlined),
          label: Text(l10n.lookup('invTakeOver')),
        ),
      if (assignedToMe &&
          [MaterialRequestStatus.underReview, MaterialRequestStatus.adjusted]
              .contains(request.status) &&
          lines.isNotEmpty &&
          lines.every(
              (line) => line.approved.isZero || line.reserved == line.approved))
        FilledButton.icon(
          onPressed: () => _simpleCommand(
            context,
            ref,
            InventoryCommands.markRequestReady,
            request.id,
          ),
          icon: const Icon(Icons.inventory_2_outlined),
          label: Text(l10n.lookup('invMarkReady')),
        ),
      if (assignedToMe &&
          [
            MaterialRequestStatus.readyForIssue,
            MaterialRequestStatus.partiallyFulfilled
          ].contains(request.status) &&
          allocations.any((entry) => entry.reserved > entry.issued))
        FilledButton.icon(
          onPressed: () => _issue(
            context,
            ref,
            request,
            allocations,
            agents,
          ),
          icon: const Icon(Icons.outbox_outlined),
          label: Text(l10n.lookup('invIssueStock')),
        ),
      if (assignedToMe &&
          request.status == MaterialRequestStatus.partiallyFulfilled)
        OutlinedButton.icon(
          onPressed: () => _reasonCommand(
            context,
            ref,
            InventoryCommands.closeShortfall,
            request.id,
            l10n.lookup('invCloseShort'),
            reasons: shortfallReasons,
          ),
          icon: const Icon(Icons.remove_circle_outline),
          label: Text(l10n.lookup('invCloseShort')),
        ),
      if (assignedToMe &&
          [
            MaterialRequestStatus.submitted,
            MaterialRequestStatus.underReview,
            MaterialRequestStatus.adjusted,
          ].contains(request.status))
        OutlinedButton.icon(
          onPressed: () => _reasonCommand(
            context,
            ref,
            InventoryCommands.rejectRequest,
            request.id,
            l10n.lookup('invRejectRequest'),
            reasons: rejectionReasons,
          ),
          icon: const Icon(Icons.block_rounded),
          label: Text(l10n.lookup('invRejectRequest')),
        ),
    ];
  }
}

class _RequestHeader extends StatelessWidget {
  const _RequestHeader({required this.request});
  final MaterialRequest request;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return InventoryPanel(
      child: Wrap(
        spacing: 42,
        runSpacing: 18,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          InventoryRequestStatusBadge(request.status),
          _Detail(
              label: l10n.lookup('invRequestedFor'),
              value: request.requestedFor.name),
          _Detail(label: l10n.createdBy, value: request.submittedBy.name),
          _Detail(
              label: l10n.lookup('invManagerAssigned'),
              value: request.assignedManager?.name ?? l10n.unassigned),
          _Detail(
              label: l10n.lookup('invDeliveryDestination'),
              value: request.deliveryDestination),
          _Detail(label: l10n.createdAt, value: _date(request.createdAt)),
        ],
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
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _RequestProgress extends StatelessWidget {
  const _RequestProgress({required this.status});
  final MaterialRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final steps = [
      MaterialRequestStatus.submitted,
      MaterialRequestStatus.underReview,
      MaterialRequestStatus.readyForIssue,
      MaterialRequestStatus.partiallyFulfilled,
      MaterialRequestStatus.awaitingConfirmation,
      MaterialRequestStatus.fulfilled,
    ];
    final current = switch (status) {
      MaterialRequestStatus.adjusted => 1,
      MaterialRequestStatus.closedShort => 5,
      MaterialRequestStatus.cancelled || MaterialRequestStatus.rejected => 0,
      _ => steps.indexOf(status).clamp(0, steps.length - 1),
    };
    return InventoryPanel(
      title: l10n.lookup('invStatusTimeline'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 720) {
            return Column(
              children: [
                for (var index = 0; index < steps.length; index++)
                  ListTile(
                    leading: Icon(
                      index <= current
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: index <= current
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                    title: Text(_statusText(context, steps[index])),
                    dense: true,
                  ),
              ],
            );
          }
          return Row(
            children: [
              for (var index = 0; index < steps.length; index++) ...[
                Expanded(
                  child: Column(
                    children: [
                      Icon(
                        index <= current
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: index <= current
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _statusText(context, steps[index]),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                if (index != steps.length - 1)
                  Expanded(
                    child: Divider(
                      color: index < current
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RequestLineCard extends ConsumerWidget {
  const _RequestLineCard({
    required this.request,
    required this.line,
    required this.allocations,
    required this.canOperate,
  });
  final MaterialRequest request;
  final MaterialRequestLine line;
  final List<MaterialRequestAllocation> allocations;
  final bool canOperate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final balances = ref.watch(inventoryBalancesProvider(line.itemId));
    final adjustmentReasons = ref
            .watch(inventoryParametersProvider(
              InventoryParameterType.adjustmentReason,
            ))
            .valueOrNull ??
        const <InventoryParameter>[];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  line.itemName,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              if (canOperate)
                Wrap(
                  children: [
                    TextButton(
                      onPressed: () => _adjustLine(
                        context,
                        ref,
                        request.id,
                        line,
                        adjustmentReasons,
                      ),
                      child: Text(l10n.lookup('invAdjustLine')),
                    ),
                    if (line.approved.isPositive && line.reserved.isZero)
                      FilledButton.tonal(
                        onPressed: () => _reserveLine(
                          context,
                          ref,
                          request.id,
                          line,
                          balances.valueOrNull ?? const [],
                        ),
                        child: Text(l10n.lookup('invReserveStock')),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _quantity(l10n.lookup('invRequestedQuantity'), line.requested),
              _quantity(l10n.lookup('invApprovedQuantity'), line.approved),
              _quantity(l10n.lookup('invReservedQuantity'), line.reserved),
              _quantity(l10n.lookup('invIssuedQuantity'), line.issued),
              _quantity(
                  l10n.lookup('invOutstandingQuantity'), line.outstanding),
            ],
          ),
          if (line.adjustmentReason.isNotEmpty ||
              line.declineReason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              line.declineReason.isNotEmpty
                  ? line.declineReason
                  : line.adjustmentReason,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (allocations.isNotEmpty) ...[
            const Divider(height: 24),
            for (final allocation in allocations)
              Text(
                '${allocation.warehouseName} / ${allocation.locationName}: ${allocation.issued.format()} / ${allocation.reserved.format()}',
              ),
          ],
        ],
      ),
    );
  }

  Widget _quantity(String label, InventoryQuantity value) =>
      Text('$label: ${value.format()}');
}

Future<void> _adjustLine(
  BuildContext context,
  WidgetRef ref,
  String requestId,
  MaterialRequestLine line,
  List<InventoryParameter> reasons,
) async {
  final input = await showDialog<_QuantityReasonInput>(
    context: context,
    builder: (context) => _QuantityReasonDialog(
      title: S.of(context).lookup('invAdjustLine'),
      initialQuantity: line.approved.format(),
      allowZero: true,
      reasons: reasons,
    ),
  );
  if (input == null || !context.mounted) return;
  await _run(context, ref, InventoryCommands.adjustRequestLine, {
    'requestId': requestId,
    'lineId': line.id,
    'approvedMilli': input.quantity.milliUnits,
    'reason': input.reason,
  });
}

Future<void> _reserveLine(
  BuildContext context,
  WidgetRef ref,
  String requestId,
  MaterialRequestLine line,
  List<InventoryBalance> balances,
) async {
  final input = await showDialog<List<_AllocationInput>>(
    context: context,
    builder: (context) => _ReservationDialog(
      approved: line.approved,
      balances: balances,
    ),
  );
  if (input == null || !context.mounted) return;
  await _run(context, ref, InventoryCommands.reserveRequestLine, {
    'requestId': requestId,
    'lineId': line.id,
    'allocations': [
      for (final allocation in input)
        {
          'balanceId': allocation.balanceId,
          'quantityMilli': allocation.quantity.milliUnits,
        },
    ],
  });
}

Future<void> _simpleCommand(
  BuildContext context,
  WidgetRef ref,
  String command,
  String requestId,
) =>
    _run(context, ref, command, {'requestId': requestId});

Future<void> _reasonCommand(
  BuildContext context,
  WidgetRef ref,
  String command,
  String requestId,
  String title, {
  bool reasonOptional = false,
  List<InventoryParameter> reasons = const [],
}) async {
  final reason = await showDialog<String>(
    context: context,
    builder: (context) => _ReasonDialog(
      title: title,
      optional: reasonOptional,
      reasons: reasons,
    ),
  );
  if (reason == null || !context.mounted) return;
  await _run(context, ref, command, {'requestId': requestId, 'reason': reason});
}

Future<void> _issue(
  BuildContext context,
  WidgetRef ref,
  MaterialRequest request,
  List<MaterialRequestAllocation> allocations,
  List<AgentDirectoryEntry> agents,
) async {
  final result = await showDialog<_IssueInput>(
    context: context,
    builder: (context) => _IssueDialog(
      allocations: allocations,
      agents: agents,
      defaultRecipientId: request.requestedFor.userId,
    ),
  );
  if (result == null || !context.mounted) return;
  await _run(context, ref, InventoryCommands.issueRequest, {
    'requestId': request.id,
    'recipientUserId': result.recipientId,
    'issues': [
      for (final issue in result.issues)
        {
          'allocationId': issue.allocationId,
          'quantityMilli': issue.quantity.milliUnits,
        },
    ],
  });
}

Future<void> _run(
  BuildContext context,
  WidgetRef ref,
  String command,
  Map<String, Object?> payload,
) async {
  try {
    await ref.read(inventoryCommandControllerProvider.notifier).execute(
          functionName: command,
          commandId: ref.read(inventoryCommandIdFactoryProvider)(),
          payload: payload,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).lookup('invActionCompleted'))),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({
    required this.title,
    required this.optional,
    required this.reasons,
  });
  final String title;
  final bool optional;
  final List<InventoryParameter> reasons;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _controller = TextEditingController();
  String _selectedReason = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        child: InventoryReasonField(
          options: widget.reasons,
          controller: _controller,
          selectedReason: _selectedReason,
          onSelected: (value) => setState(() => _selectedReason = value),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () {
            final value = _selectedReason.isNotEmpty
                ? _selectedReason
                : _controller.text.trim();
            if (!widget.optional && value.isEmpty) return;
            Navigator.pop(context, value);
          },
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}

class _QuantityReasonInput {
  const _QuantityReasonInput(this.quantity, this.reason);
  final InventoryQuantity quantity;
  final String reason;
}

class _QuantityReasonDialog extends StatefulWidget {
  const _QuantityReasonDialog({
    required this.title,
    required this.initialQuantity,
    required this.allowZero,
    required this.reasons,
  });
  final String title;
  final String initialQuantity;
  final bool allowZero;
  final List<InventoryParameter> reasons;

  @override
  State<_QuantityReasonDialog> createState() => _QuantityReasonDialogState();
}

class _QuantityReasonDialogState extends State<_QuantityReasonDialog> {
  late final TextEditingController _quantity;
  final _reason = TextEditingController();
  String _selectedReason = '';

  @override
  void initState() {
    super.initState();
    _quantity = TextEditingController(text: widget.initialQuantity);
  }

  @override
  void dispose() {
    _quantity.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CommonTextInput(
                label: l10n.lookup('invApprovedQuantity'),
                type: CommonTextInputType.decimal,
                controller: _quantity),
            const SizedBox(height: 12),
            InventoryReasonField(
              options: widget.reasons,
              controller: _reason,
              selectedReason: _selectedReason,
              onSelected: (value) => setState(() => _selectedReason = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () {
            try {
              final quantity = InventoryQuantity.parse(_quantity.text);
              if (quantity.isNegative ||
                  (!widget.allowZero && quantity.isZero)) {
                throw const FormatException();
              }
              final reason = _selectedReason.isNotEmpty
                  ? _selectedReason
                  : _reason.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(context, _QuantityReasonInput(quantity, reason));
            } on FormatException {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.lookup('invPositiveQuantity'))),
              );
            }
          },
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}

class _AllocationInput {
  const _AllocationInput(this.balanceId, this.quantity);
  final String balanceId;
  final InventoryQuantity quantity;
}

class _ReservationDialog extends StatefulWidget {
  const _ReservationDialog({required this.approved, required this.balances});
  final InventoryQuantity approved;
  final List<InventoryBalance> balances;

  @override
  State<_ReservationDialog> createState() => _ReservationDialogState();
}

class _ReservationDialogState extends State<_ReservationDialog> {
  final Map<String, TextEditingController> _quantities = {};

  @override
  void dispose() {
    for (final controller in _quantities.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return AlertDialog(
      title: Text(l10n.lookup('invReserveStock')),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                  '${l10n.lookup('invApprovedQuantity')}: ${widget.approved.format()}'),
              const SizedBox(height: 16),
              for (final balance in widget.balances)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CommonTextInput(
                    label:
                        '${balance.warehouseName} / ${balance.locationName} (${balance.available.format()})',
                    type: CommonTextInputType.decimal,
                    controller: _quantities.putIfAbsent(
                      balance.id,
                      () => TextEditingController(text: '0'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () {
            try {
              final result = <_AllocationInput>[];
              for (final balance in widget.balances) {
                final quantity =
                    InventoryQuantity.parse(_quantities[balance.id]!.text);
                if (quantity.isNegative || quantity > balance.available) {
                  throw const FormatException();
                }
                if (quantity.isPositive) {
                  result.add(_AllocationInput(balance.id, quantity));
                }
              }
              final total = result.fold(
                  InventoryQuantity.zero, (sum, entry) => sum + entry.quantity);
              if (total != widget.approved) throw const FormatException();
              Navigator.pop(context, result);
            } on FormatException {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.lookup('invPositiveQuantity'))),
              );
            }
          },
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}

class _IssueAllocationInput {
  const _IssueAllocationInput(this.allocationId, this.quantity);
  final String allocationId;
  final InventoryQuantity quantity;
}

class _IssueInput {
  const _IssueInput(this.recipientId, this.issues);
  final String recipientId;
  final List<_IssueAllocationInput> issues;
}

class _IssueDialog extends StatefulWidget {
  const _IssueDialog({
    required this.allocations,
    required this.agents,
    required this.defaultRecipientId,
  });
  final List<MaterialRequestAllocation> allocations;
  final List<AgentDirectoryEntry> agents;
  final String defaultRecipientId;

  @override
  State<_IssueDialog> createState() => _IssueDialogState();
}

class _IssueDialogState extends State<_IssueDialog> {
  late String _recipientId;
  final Map<String, TextEditingController> _quantities = {};

  @override
  void initState() {
    super.initState();
    _recipientId = widget.defaultRecipientId;
  }

  @override
  void dispose() {
    for (final controller in _quantities.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final active = widget.allocations
        .where((entry) => entry.reserved > entry.issued)
        .toList(growable: false);
    return AlertDialog(
      title: Text(l10n.lookup('invIssueStock')),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: widget.agents.any((entry) => entry.id == _recipientId)
                    ? _recipientId
                    : null,
                decoration:
                    InputDecoration(labelText: l10n.lookup('invRecipient')),
                items: [
                  for (final agent in widget.agents)
                    DropdownMenuItem(
                        value: agent.id, child: Text(agent.displayName)),
                ],
                onChanged: (value) =>
                    setState(() => _recipientId = value ?? ''),
              ),
              const SizedBox(height: 16),
              for (final allocation in active)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CommonTextInput(
                    label:
                        '${allocation.warehouseName} / ${allocation.locationName}',
                    type: CommonTextInputType.decimal,
                    controller: _quantities.putIfAbsent(
                      allocation.id,
                      () => TextEditingController(
                        text:
                            (allocation.reserved - allocation.issued).format(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () {
            try {
              if (_recipientId.isEmpty) throw const FormatException();
              final issues = <_IssueAllocationInput>[];
              for (final allocation in active) {
                final quantity =
                    InventoryQuantity.parse(_quantities[allocation.id]!.text);
                final remaining = allocation.reserved - allocation.issued;
                if (quantity.isNegative || quantity > remaining) {
                  throw const FormatException();
                }
                if (quantity.isPositive) {
                  issues.add(_IssueAllocationInput(allocation.id, quantity));
                }
              }
              if (issues.isEmpty) throw const FormatException();
              Navigator.pop(context, _IssueInput(_recipientId, issues));
            } on FormatException {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.lookup('invPositiveQuantity'))),
              );
            }
          },
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}

String _statusText(BuildContext context, MaterialRequestStatus status) =>
    S.of(context).lookup(switch (status) {
          MaterialRequestStatus.submitted => 'invSubmitted',
          MaterialRequestStatus.underReview => 'invUnderReview',
          MaterialRequestStatus.adjusted => 'invAdjusted',
          MaterialRequestStatus.readyForIssue => 'invReadyForIssue',
          MaterialRequestStatus.partiallyFulfilled => 'invPartiallyFulfilled',
          MaterialRequestStatus.awaitingConfirmation =>
            'invAwaitingConfirmation',
          MaterialRequestStatus.fulfilled => 'invFulfilled',
          MaterialRequestStatus.closedShort => 'invClosedShort',
          MaterialRequestStatus.cancelled => 'invCancelled',
          MaterialRequestStatus.rejected => 'invRejected',
        });

String _date(DateTime? value) =>
    value == null ? '-' : DateFormat.yMMMd().add_Hm().format(value.toLocal());
