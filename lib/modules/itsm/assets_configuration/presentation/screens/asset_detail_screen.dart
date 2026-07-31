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
import '../widgets/asset_views.dart';
import '../widgets/assets_configuration_shell.dart';
import '../widgets/assets_configuration_state.dart';
import '../widgets/manager_configuration_dialogs.dart';

class AssetDetailScreen extends ConsumerStatefulWidget {
  const AssetDetailScreen({
    required this.assetId,
    required this.selfService,
    super.key,
    this.onBack,
    this.onCatalogueAction,
    this.attachmentPicker,
    this.attachmentIdFactory,
  });

  final String assetId;
  final bool selfService;
  final VoidCallback? onBack;
  final void Function(String assetId, AssetCatalogueAction action)?
      onCatalogueAction;
  final AssetsAttachmentFilePicker? attachmentPicker;
  final String Function()? attachmentIdFactory;

  @override
  ConsumerState<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends ConsumerState<AssetDetailScreen> {
  var _uploading = false;

  @override
  Widget build(BuildContext context) {
    final identity = AssetIdentity(
      id: widget.assetId,
      selfService: widget.selfService,
    );
    final detail = ref.watch(assetDetailProvider(identity));
    final strings = AssetsConfigurationStrings.of(context);
    return AssetsConfigurationShell(
      title: strings.assetDetails,
      subtitle: widget.selfService
          ? strings.myAssetsDescription
          : strings.assetRegisterDescription,
      onBack: widget.onBack,
      child: AssetsConfigurationAsyncView<AssetDetail?>(
        value: detail,
        onRetry: () => ref.invalidate(assetDetailProvider(identity)),
        data: (value) => value == null
            ? AssetsConfigurationEmptyState(
                title: strings.noAssets,
                description: strings.noDataDescription,
              )
            : AssetDetailView(
                detail: value,
                isManager: !widget.selfService,
                isUploading: _uploading,
                onCatalogueAction: widget.selfService
                    ? (action) =>
                        widget.onCatalogueAction?.call(widget.assetId, action)
                    : null,
                onEdit: widget.selfService
                    ? null
                    : () => showEditAssetDialog(context, ref, value),
                onAssign: widget.selfService
                    ? null
                    : () => showAssignAssetDialog(context, ref, value),
                onReturn: widget.selfService
                    ? null
                    : () => showReturnAssetDialog(context, ref, value),
                onTransition: widget.selfService
                    ? null
                    : () => showAssetLifecycleTransitionDialog(
                          context,
                          ref,
                          value,
                        ),
                onUploadAttachment: widget.selfService || _uploading
                    ? null
                    : () => _upload(value, AssetsAttachmentKind.assetFile),
                onUploadPhotograph: widget.selfService || _uploading
                    ? null
                    : () =>
                        _upload(value, AssetsAttachmentKind.assetPhotograph),
              ),
      ),
    );
  }

  Future<void> _upload(
    AssetDetail detail,
    AssetsAttachmentKind kind,
  ) async {
    setState(() => _uploading = true);
    try {
      final file = await (widget.attachmentPicker ??
              const PlatformAssetsAttachmentFilePicker())
          .pick(imagesOnly: kind == AssetsAttachmentKind.assetPhotograph);
      if (file == null) return;
      final session = await ref.read(itsmSessionProvider.future);
      if (session == null) return;
      final attachmentId =
          (widget.attachmentIdFactory ?? _newAttachmentId).call();
      final result = await ref
          .read(assetsAttachmentGatewayProvider)
          .uploadAndAwaitRegistration(
            AssetsAttachmentUploadRequest(
              parentId: widget.assetId,
              kind: kind,
              attachmentId: attachmentId,
              uploadedByUserId: session.userId,
              file: file,
            ),
          );
      final controller =
          await ref.read(assetsConfigurationCommandControllerProvider.future);
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final isPhotograph = kind == AssetsAttachmentKind.assetPhotograph;
      await controller.operateAsset(
        AssetOperationalCommand(
          context: ItsmCommandContext(
            idempotencyKey:
                'asset-${widget.assetId}-${kind.name}-$attachmentId',
            correlationId: 'asset-upload-$timestamp',
            actorUserId: session.userId,
            actorRole: session.role,
            actorDisplayName: session.displayName,
          ),
          assetId: widget.assetId,
          operation: 'update',
          fields: {
            if (isPhotograph)
              'photoAttachmentIds': {
                ...detail.photographIds,
                result.attachmentId,
              }.toList(growable: false)
            else
              'attachmentIds': {
                ...detail.attachmentNames,
                result.attachmentId,
              }.toList(growable: false),
          },
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AssetsConfigurationStrings.of(context).uploadSuccessful)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _newAttachmentId() {
    final random = Random.secure().nextInt(0x7fffffff);
    return 'asset_${DateTime.now().microsecondsSinceEpoch}_$random';
  }
}
