import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/corporate_components.dart';
import 'package:arptc_connect/widgets/status_chip.dart';
import 'package:flutter/material.dart';

import '../../application/assets_configuration_contracts.dart';
import '../assets_configuration_strings.dart';
import 'assets_configuration_state.dart';

typedef StockSupportingDocumentUploader = Future<String?> Function(
  StockItemSummary item,
);

class StockWorkspaceView extends StatelessWidget {
  const StockWorkspaceView({
    required this.items,
    required this.movements,
    required this.onRecordMovement,
    super.key,
    this.onCreateLocation,
    this.onEditLocation,
    this.onCreateItem,
    this.onEditItem,
    this.onUploadSupportingDocument,
  });

  final List<StockItemSummary> items;
  final List<StockMovementSummary> movements;
  final ValueChanged<StockMovementDraft> onRecordMovement;
  final VoidCallback? onCreateLocation;
  final VoidCallback? onEditLocation;
  final VoidCallback? onCreateItem;
  final ValueChanged<StockItemSummary>? onEditItem;
  final StockSupportingDocumentUploader? onUploadSupportingDocument;

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    final lowStockCount = items.where((item) => item.isLowStock).length;
    final totalQuantity = items.fold<num>(
      0,
      (total, item) => total + item.quantity,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed:
                    items.isEmpty ? null : () => _scanAndOpenMovement(context),
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: Text(strings.scanBarcode),
              ),
              OutlinedButton.icon(
                onPressed: onCreateLocation,
                icon: const Icon(Icons.add_location_alt_outlined),
                label: Text(strings.addStockLocation),
              ),
              OutlinedButton.icon(
                onPressed: onEditLocation,
                icon: const Icon(Icons.edit_location_alt_outlined),
                label: Text(strings.editStockLocation),
              ),
              FilledButton.icon(
                onPressed: onCreateItem,
                icon: const Icon(Icons.add_box_outlined),
                label: Text(strings.addStockItem),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 680
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: width,
                  child: CorporateKpiCard(
                    title: strings.trackedQuantity,
                    value: totalQuantity.toString(),
                    icon: Icons.inventory_2_outlined,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: CorporateKpiCard(
                    title: strings.lowStock,
                    value: '$lowStockCount',
                    icon: Icons.warning_amber_rounded,
                    accentColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        CorporateSurfaceCard(
          title: strings.stockItems,
          subtitle: strings.stockDescription,
          child: items.isEmpty
              ? AssetsConfigurationEmptyState(
                  title: strings.noData,
                  description: strings.noDataDescription,
                  icon: Icons.warehouse_outlined,
                )
              : Column(
                  children: [
                    for (final item in items)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          child: Icon(
                            item.isConsumable
                                ? Icons.category_outlined
                                : Icons.devices_other_outlined,
                          ),
                        ),
                        title: Text(item.name),
                        subtitle: Text('${item.sku} • ${item.locationName}'),
                        trailing: Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            StatusChip(
                              label: item.isLowStock
                                  ? strings.lowStock
                                  : strings.available,
                              type: item.isLowStock
                                  ? StatusType.warning
                                  : StatusType.success,
                            ),
                            Text(
                              '${item.quantity}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            IconButton(
                              tooltip: strings.editStockItem,
                              onPressed: onEditItem == null
                                  ? null
                                  : () => onEditItem!(item),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: strings.recordMovement,
                              onPressed: () => showStockMovementDialog(
                                context,
                                item,
                                onRecordMovement,
                                onUploadSupportingDocument:
                                    onUploadSupportingDocument,
                              ),
                              icon: const Icon(Icons.swap_horiz_rounded),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 20),
        CorporateSurfaceCard(
          title: strings.stockMovements,
          subtitle: strings.stockDescription,
          child: movements.isEmpty
              ? AssetsConfigurationEmptyState(
                  title: strings.noData,
                  description: strings.noDataDescription,
                  icon: Icons.receipt_long_outlined,
                )
              : _MovementLedger(movements: movements),
        ),
      ],
    );
  }

  Future<void> _scanAndOpenMovement(BuildContext context) async {
    final item = await showDialog<StockItemSummary>(
      context: context,
      builder: (context) => _StockBarcodeDialog(items: items),
    );
    if (item == null || !context.mounted) return;
    await showStockMovementDialog(
      context,
      item,
      onRecordMovement,
      onUploadSupportingDocument: onUploadSupportingDocument,
    );
  }
}

class StockMovementDraft {
  const StockMovementDraft({
    required this.itemId,
    required this.type,
    required this.quantity,
    this.sourceLocationId,
    this.destinationLocationId,
    this.recipientUserId,
    this.relatedRequestId,
    this.supportingDocumentId,
    this.reservedQuantity = 0,
    this.targetReserved = 0,
    this.adjustmentDelta,
    this.reason,
  });

  final String itemId;
  final StockMovementType type;
  final num quantity;
  final String? sourceLocationId;
  final String? destinationLocationId;
  final String? recipientUserId;
  final String? relatedRequestId;
  final String? supportingDocumentId;
  final num reservedQuantity;
  final num targetReserved;
  final num? adjustmentDelta;
  final String? reason;
}

Future<void> showStockMovementDialog(
  BuildContext context,
  StockItemSummary item,
  ValueChanged<StockMovementDraft> onSubmit, {
  StockSupportingDocumentUploader? onUploadSupportingDocument,
}) async {
  final draft = await showDialog<StockMovementDraft>(
    context: context,
    builder: (context) => _StockMovementDialog(
      item: item,
      onUploadSupportingDocument: onUploadSupportingDocument,
    ),
  );
  if (draft != null) onSubmit(draft);
}

class _StockMovementDialog extends StatefulWidget {
  const _StockMovementDialog({
    required this.item,
    this.onUploadSupportingDocument,
  });

  final StockItemSummary item;
  final StockSupportingDocumentUploader? onUploadSupportingDocument;

  @override
  State<_StockMovementDialog> createState() => _StockMovementDialogState();
}

class _StockMovementDialogState extends State<_StockMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _source = TextEditingController();
  final _destination = TextEditingController();
  final _recipient = TextEditingController();
  final _request = TextEditingController();
  final _evidence = TextEditingController();
  final _reservedQuantity = TextEditingController(text: '0');
  final _targetReserved = TextEditingController(text: '0');
  final _reason = TextEditingController();
  StockMovementType _type = StockMovementType.receipt;
  bool _increaseAdjustment = true;
  bool _uploadingEvidence = false;

  @override
  void dispose() {
    _quantity.dispose();
    _source.dispose();
    _destination.dispose();
    _recipient.dispose();
    _request.dispose();
    _evidence.dispose();
    _reservedQuantity.dispose();
    _targetReserved.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    return AlertDialog(
      title: Text('${strings.recordMovement}: ${widget.item.name}'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<StockMovementType>(
                  value: _type,
                  decoration:
                      InputDecoration(labelText: strings.movementTypeLabel),
                  items: [
                    for (final type in StockMovementType.values)
                      DropdownMenuItem(
                        value: type,
                        child: Text(strings.movementType(type)),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _type = value ?? _type;
                  }),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    strings.movementRequirementsHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 16),
                CommonTextInput(
                  label: _type == StockMovementType.reconciliation
                      ? strings.targetOnHand
                      : strings.quantity,
                  type: CommonTextInputType.decimal,
                  controller: _quantity,
                  validator: (value) {
                    final quantity = num.tryParse(value ?? '');
                    final invalid = _type == StockMovementType.reconciliation
                        ? quantity == null || quantity < 0
                        : quantity == null || quantity <= 0;
                    return invalid ? strings.positiveQuantityError : null;
                  },
                ),
                if (_type == StockMovementType.adjustment) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<bool>(
                    value: _increaseAdjustment,
                    decoration:
                        InputDecoration(labelText: strings.adjustmentDirection),
                    items: [
                      DropdownMenuItem(
                        value: true,
                        child: Text(strings.increaseStock),
                      ),
                      DropdownMenuItem(
                        value: false,
                        child: Text(strings.decreaseStock),
                      ),
                    ],
                    onChanged: (value) => setState(
                      () => _increaseAdjustment = value ?? true,
                    ),
                  ),
                ],
                if (_type == StockMovementType.issue) ...[
                  const SizedBox(height: 12),
                  CommonTextInput(
                    label: strings.reservedQuantityFulfilled,
                    type: CommonTextInputType.decimal,
                    controller: _reservedQuantity,
                    validator: (value) {
                      final reserved = num.tryParse(value ?? '');
                      final quantity = num.tryParse(_quantity.text);
                      if (reserved == null || reserved < 0) {
                        return strings.nonNegativeNumberRequired;
                      }
                      if (quantity != null && reserved > quantity) {
                        return strings.reservedQuantityTooHigh;
                      }
                      return null;
                    },
                  ),
                ],
                if (_type == StockMovementType.reconciliation) ...[
                  const SizedBox(height: 12),
                  CommonTextInput(
                    label: strings.targetReserved,
                    type: CommonTextInputType.decimal,
                    controller: _targetReserved,
                    validator: (value) {
                      final reserved = num.tryParse(value ?? '');
                      final onHand = num.tryParse(_quantity.text);
                      if (reserved == null || reserved < 0) {
                        return strings.nonNegativeNumberRequired;
                      }
                      if (onHand != null && reserved > onHand) {
                        return strings.reservedQuantityTooHigh;
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 12),
                CommonTextInput(
                  label: strings.sourceLocation,
                  controller: _source,
                  validator: (value) =>
                      _requiresSource(_type) && (value?.trim().isEmpty ?? true)
                          ? strings.sourceLocationRequired
                          : null,
                ),
                const SizedBox(height: 12),
                CommonTextInput(
                  label: strings.destinationLocation,
                  controller: _destination,
                  validator: (value) => _requiresDestination(_type) &&
                          (value?.trim().isEmpty ?? true)
                      ? strings.destinationLocationRequired
                      : null,
                ),
                const SizedBox(height: 12),
                CommonTextInput(
                  label: strings.recipientUserId,
                  controller: _recipient,
                  validator: (value) => _requiresRecipient(_type) &&
                          (value?.trim().isEmpty ?? true)
                      ? strings.recipientRequired
                      : null,
                ),
                const SizedBox(height: 12),
                CommonTextInput(
                    label: strings.relatedRequest, controller: _request),
                const SizedBox(height: 12),
                CommonTextInput(
                  label: strings.supportingDocument,
                  controller: _evidence,
                  readOnly: true,
                  suffixIcon: IconButton(
                    tooltip: strings.chooseSupportingDocument,
                    onPressed: widget.onUploadSupportingDocument == null ||
                            _uploadingEvidence
                        ? null
                        : _uploadEvidence,
                    icon: _uploadingEvidence
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file_outlined),
                  ),
                  validator: (value) => _requiresEvidence(_type) &&
                          (value?.trim().isEmpty ?? true)
                      ? strings.evidenceRequired
                      : null,
                ),
                const SizedBox(height: 12),
                CommonTextInput(
                  label: strings.movementReason,
                  controller: _reason,
                  isMultiline: true,
                  validator: (value) =>
                      _requiresReason(_type) && (value?.trim().isEmpty ?? true)
                          ? strings.positiveQuantityError
                          : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              StockMovementDraft(
                itemId: widget.item.id,
                type: _type,
                quantity: num.parse(_quantity.text),
                sourceLocationId: _optional(_source.text),
                destinationLocationId: _optional(_destination.text),
                recipientUserId: _optional(_recipient.text),
                relatedRequestId: _optional(_request.text),
                supportingDocumentId: _optional(_evidence.text),
                reservedQuantity:
                    num.tryParse(_reservedQuantity.text.trim()) ?? 0,
                targetReserved: num.tryParse(_targetReserved.text.trim()) ?? 0,
                adjustmentDelta: _type == StockMovementType.adjustment
                    ? (_increaseAdjustment ? 1 : -1) * num.parse(_quantity.text)
                    : null,
                reason: _optional(_reason.text),
              ),
            );
          },
          child: Text(strings.recordMovement),
        ),
      ],
    );
  }

  Future<void> _uploadEvidence() async {
    setState(() => _uploadingEvidence = true);
    try {
      final attachmentId =
          await widget.onUploadSupportingDocument?.call(widget.item);
      if (!mounted || attachmentId == null) return;
      setState(() => _evidence.text = attachmentId);
    } finally {
      if (mounted) setState(() => _uploadingEvidence = false);
    }
  }
}

StockItemSummary? findStockItemByBarcode(
  Iterable<StockItemSummary> items,
  String barcode,
) {
  final normalized = barcode.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  for (final item in items) {
    if (item.barcode.trim().toLowerCase() == normalized ||
        item.sku.trim().toLowerCase() == normalized) {
      return item;
    }
  }
  return null;
}

class _StockBarcodeDialog extends StatefulWidget {
  const _StockBarcodeDialog({required this.items});

  final List<StockItemSummary> items;

  @override
  State<_StockBarcodeDialog> createState() => _StockBarcodeDialogState();
}

class _StockBarcodeDialogState extends State<_StockBarcodeDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    return AlertDialog(
      title: Text(strings.scanBarcode),
      content: SizedBox(
        width: 420,
        child: CommonTextInput(
          label: strings.scanBarcodeHint,
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _select(),
          decoration: InputDecoration(
            errorText: _error,
            prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: _select,
          child: Text(strings.select),
        ),
      ],
    );
  }

  void _select() {
    final item = findStockItemByBarcode(widget.items, _controller.text);
    if (item == null) {
      setState(() {
        _error = AssetsConfigurationStrings.of(context).barcodeNotFound;
      });
      return;
    }
    Navigator.pop(context, item);
  }
}

bool _requiresSource(StockMovementType type) => switch (type) {
      StockMovementType.reservation ||
      StockMovementType.issue ||
      StockMovementType.transfer ||
      StockMovementType.adjustment ||
      StockMovementType.reconciliation =>
        true,
      _ => false,
    };

bool _requiresDestination(StockMovementType type) => switch (type) {
      StockMovementType.receipt ||
      StockMovementType.returnToStock ||
      StockMovementType.transfer =>
        true,
      _ => false,
    };

bool _requiresRecipient(StockMovementType type) => switch (type) {
      StockMovementType.reservation || StockMovementType.issue => true,
      _ => false,
    };

bool _requiresEvidence(StockMovementType type) =>
    type == StockMovementType.adjustment ||
    type == StockMovementType.reconciliation;

bool _requiresReason(StockMovementType type) =>
    type == StockMovementType.adjustment ||
    type == StockMovementType.reconciliation;

class _MovementLedger extends StatelessWidget {
  const _MovementLedger({required this.movements});

  final List<StockMovementSummary> movements;

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    return Column(
      children: [
        for (final movement in movements)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text(
              '${movement.itemName} • ${strings.movementType(movement.type)}',
            ),
            subtitle: Text(
              '${movement.actorName} • '
              '${MaterialLocalizations.of(context).formatShortDate(movement.occurredAt)}'
              '${movement.recipientName.isEmpty ? '' : ' • ${movement.recipientName}'}',
            ),
            trailing: Text(
              '${movement.quantity}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
      ],
    );
  }
}

String? _optional(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}
