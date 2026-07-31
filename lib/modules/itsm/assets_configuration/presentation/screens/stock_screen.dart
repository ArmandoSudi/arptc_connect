import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/application/itsm_providers.dart';
import '../../../shared/data/trusted_command_gateways.dart';
import '../../application/assets_attachment.dart';
import '../../application/assets_configuration_contracts.dart';
import '../../application/assets_configuration_providers.dart';
import '../assets_attachment_picker.dart';
import '../assets_configuration_strings.dart';
import '../widgets/assets_configuration_shell.dart';
import '../widgets/assets_configuration_state.dart';
import '../widgets/stock_view.dart';
import '../widgets/manager_configuration_dialogs.dart';

class StockScreen extends ConsumerWidget {
  const StockScreen({
    super.key,
    this.onBack,
    this.limit = 50,
    this.attachmentPicker,
    this.attachmentIdFactory,
  });

  final VoidCallback? onBack;
  final int limit;
  final AssetsAttachmentFilePicker? attachmentPicker;
  final String Function()? attachmentIdFactory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(stockItemsProvider(limit));
    final movements = ref.watch(stockMovementsProvider(limit));
    final strings = AssetsConfigurationStrings.of(context);
    return AssetsConfigurationShell(
      title: strings.stock,
      subtitle: strings.stockDescription,
      onBack: onBack,
      child: AssetsConfigurationAsyncView<List<StockItemSummary>>(
        value: items,
        onRetry: () => ref.invalidate(stockItemsProvider(limit)),
        data: (stockItems) =>
            AssetsConfigurationAsyncView<List<StockMovementSummary>>(
          value: movements,
          onRetry: () => ref.invalidate(stockMovementsProvider(limit)),
          data: (stockMovements) => StockWorkspaceView(
            items: stockItems,
            movements: stockMovements,
            onRecordMovement: (draft) => _recordMovement(context, ref, draft),
            onCreateLocation: () => showSaveStockLocationDialog(context, ref),
            onEditLocation: () =>
                showSaveStockLocationDialog(context, ref, editing: true),
            onCreateItem: () => showSaveStockItemDialog(context, ref),
            onEditItem: (item) =>
                showSaveStockItemDialog(context, ref, item: item),
            onUploadSupportingDocument: (item) =>
                _uploadSupportingDocument(context, ref, item),
          ),
        ),
      ),
    );
  }

  Future<void> _recordMovement(
    BuildContext context,
    WidgetRef ref,
    StockMovementDraft draft,
  ) async {
    try {
      final session = await ref.read(itsmSessionProvider.future);
      if (session == null) return;
      final controller =
          await ref.read(assetsConfigurationCommandControllerProvider.future);
      final nonce = DateTime.now().microsecondsSinceEpoch;
      await controller.recordStockMovement(
        StockMovementCommand(
          context: ItsmCommandContext(
            idempotencyKey: 'stock-${draft.itemId}-${draft.type.name}-$nonce',
            correlationId: 'stock-${draft.itemId}-$nonce',
            actorUserId: session.userId,
            actorRole: session.role,
            actorDisplayName: session.displayName,
          ),
          itemId: draft.itemId,
          type: draft.type,
          quantity: draft.quantity,
          actorUserId: session.userId,
          sourceLocationId: draft.sourceLocationId,
          destinationLocationId: draft.destinationLocationId,
          recipientUserId: draft.recipientUserId,
          relatedRequestId: draft.relatedRequestId,
          supportingDocumentId: draft.supportingDocumentId,
          reason: draft.reason,
          reservedQuantity: draft.reservedQuantity,
          adjustmentDelta: draft.adjustmentDelta,
          targetOnHand: draft.type == StockMovementType.reconciliation
              ? draft.quantity
              : null,
          targetReserved: draft.targetReserved,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<String?> _uploadSupportingDocument(
    BuildContext context,
    WidgetRef ref,
    StockItemSummary item,
  ) async {
    try {
      final file =
          await (attachmentPicker ?? const PlatformAssetsAttachmentFilePicker())
              .pick(imagesOnly: false);
      if (file == null) return null;
      final session = await ref.read(itsmSessionProvider.future);
      if (session == null) return null;
      final attachmentId = (attachmentIdFactory ?? _newAttachmentId).call();
      final result = await ref
          .read(assetsAttachmentGatewayProvider)
          .uploadAndAwaitRegistration(
            AssetsAttachmentUploadRequest(
              parentId: item.id,
              kind: AssetsAttachmentKind.stockSupportingDocument,
              attachmentId: attachmentId,
              uploadedByUserId: session.userId,
              file: file,
            ),
          );
      if (!context.mounted) return result.attachmentId;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AssetsConfigurationStrings.of(context).uploadSuccessful,
          ),
        ),
      );
      return result.attachmentId;
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
      return null;
    }
  }

  String _newAttachmentId() {
    final random = Random.secure().nextInt(0x7fffffff);
    return 'stock_${DateTime.now().microsecondsSinceEpoch}_$random';
  }
}
