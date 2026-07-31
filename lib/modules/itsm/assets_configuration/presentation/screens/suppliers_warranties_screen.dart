import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/assets_configuration_contracts.dart';
import '../../application/assets_configuration_providers.dart';
import '../assets_configuration_strings.dart';
import '../widgets/assets_configuration_shell.dart';
import '../widgets/assets_configuration_state.dart';
import '../widgets/suppliers_warranties_view.dart';
import '../widgets/manager_configuration_dialogs.dart';

class SuppliersWarrantiesScreen extends ConsumerWidget {
  const SuppliersWarrantiesScreen({
    super.key,
    this.onBack,
    this.onAddSupplier,
    this.onAddContract,
    this.onAddWarranty,
    this.onWarrantySelected,
    this.limit = 50,
  });

  final VoidCallback? onBack;
  final ManagerDialogAction? onAddSupplier;
  final ManagerDialogAction? onAddContract;
  final ManagerDialogAction? onAddWarranty;
  final ManagerWarrantyDialogAction? onWarrantySelected;
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliers = ref.watch(suppliersProvider(limit));
    final contracts = ref.watch(contractsProvider(limit));
    final warranties = ref.watch(warrantiesProvider(limit));
    final strings = AssetsConfigurationStrings.of(context);
    return AssetsConfigurationShell(
      title: strings.suppliersWarranties,
      subtitle: strings.suppliersWarrantiesDescription,
      onBack: onBack,
      actions: [
        OutlinedButton.icon(
          onPressed:
              onAddSupplier == null ? null : () => onAddSupplier!(context, ref),
          icon: const Icon(Icons.add_business_outlined),
          label: Text(strings.addSupplier),
        ),
        OutlinedButton.icon(
          onPressed:
              onAddContract == null ? null : () => onAddContract!(context, ref),
          icon: const Icon(Icons.note_add_outlined),
          label: Text(strings.addContract),
        ),
        FilledButton.icon(
          onPressed:
              onAddWarranty == null ? null : () => onAddWarranty!(context, ref),
          icon: const Icon(Icons.verified_user_outlined),
          label: Text(strings.addWarranty),
        ),
      ],
      child: AssetsConfigurationAsyncView<List<SupplierSummary>>(
        value: suppliers,
        data: (supplierItems) =>
            AssetsConfigurationAsyncView<List<ContractSummary>>(
          value: contracts,
          data: (contractItems) =>
              AssetsConfigurationAsyncView<List<WarrantySummary>>(
            value: warranties,
            data: (warrantyItems) => SuppliersWarrantiesView(
              suppliers: supplierItems,
              contracts: contractItems,
              warranties: warrantyItems,
              onSupplierSelected: (supplier) => showAddSupplierDialog(
                context,
                ref,
                supplier: supplier,
              ),
              onContractSelected: (contract) => showAddContractDialog(
                context,
                ref,
                contract: contract,
              ),
              onWarrantySelected: (warranty) => _manageWarranty(
                context,
                ref,
                warranty,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _manageWarranty(
    BuildContext context,
    WidgetRef ref,
    WarrantySummary warranty,
  ) async {
    final strings = AssetsConfigurationStrings.of(context);
    final action = await showDialog<_WarrantyAction>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text('${strings.manageWarranty}: ${warranty.name}'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(
              dialogContext,
              _WarrantyAction.edit,
            ),
            child: Text(strings.editWarranty),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(
              dialogContext,
              _WarrantyAction.recordClaim,
            ),
            child: Text(strings.recordWarrantyClaim),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(
              dialogContext,
              _WarrantyAction.transitionClaim,
            ),
            child: Text(strings.transitionWarrantyClaim),
          ),
        ],
      ),
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case _WarrantyAction.edit:
        await showAddWarrantyDialog(context, ref, warranty: warranty);
      case _WarrantyAction.recordClaim:
        if (onWarrantySelected != null) {
          await onWarrantySelected!(context, ref, warranty);
        } else {
          await showWarrantyClaimDialog(context, ref, warranty);
        }
      case _WarrantyAction.transitionClaim:
        await showWarrantyClaimTransitionDialog(context, ref, warranty);
    }
  }
}

enum _WarrantyAction { edit, recordClaim, transitionClaim }
