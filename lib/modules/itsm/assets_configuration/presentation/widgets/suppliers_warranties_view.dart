import 'package:arptc_connect/widgets/corporate_components.dart';
import 'package:arptc_connect/widgets/status_chip.dart';
import 'package:flutter/material.dart';

import '../../application/assets_configuration_contracts.dart';
import '../assets_configuration_strings.dart';
import 'assets_configuration_state.dart';

class SuppliersWarrantiesView extends StatelessWidget {
  const SuppliersWarrantiesView({
    required this.suppliers,
    required this.contracts,
    required this.warranties,
    super.key,
    this.onSupplierSelected,
    this.onContractSelected,
    this.onWarrantySelected,
  });

  final List<SupplierSummary> suppliers;
  final List<ContractSummary> contracts;
  final List<WarrantySummary> warranties;
  final ValueChanged<SupplierSummary>? onSupplierSelected;
  final ValueChanged<ContractSummary>? onContractSelected;
  final ValueChanged<WarrantySummary>? onWarrantySelected;

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            isScrollable: true,
            tabs: [
              Tab(
                  text: strings.suppliers,
                  icon: const Icon(Icons.handshake_outlined)),
              Tab(
                  text: strings.contracts,
                  icon: const Icon(Icons.description_outlined)),
              Tab(
                  text: strings.warranties,
                  icon: const Icon(Icons.verified_user_outlined)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 560,
            child: TabBarView(
              children: [
                _SupplierList(
                  suppliers: suppliers,
                  onSelected: onSupplierSelected,
                ),
                _ContractList(
                  contracts: contracts,
                  onSelected: onContractSelected,
                ),
                _WarrantyList(
                  warranties: warranties,
                  onSelected: onWarrantySelected,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierList extends StatelessWidget {
  const _SupplierList({required this.suppliers, this.onSelected});

  final List<SupplierSummary> suppliers;
  final ValueChanged<SupplierSummary>? onSelected;

  @override
  Widget build(BuildContext context) {
    if (suppliers.isEmpty) return const _Empty(icon: Icons.handshake_outlined);
    return ListView.separated(
      itemCount: suppliers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final supplier = suppliers[index];
        return CorporateSurfaceCard(
          onTap: onSelected == null ? null : () => onSelected!(supplier),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.business_outlined)),
            title: Text(supplier.name),
            subtitle: Text(
              [supplier.contactName, supplier.email, supplier.supportTerms]
                  .where((value) => value.isNotEmpty)
                  .join(' • '),
            ),
            trailing: supplier.slaName.isEmpty
                ? null
                : Chip(label: Text(supplier.slaName)),
          ),
        );
      },
    );
  }
}

class _ContractList extends StatelessWidget {
  const _ContractList({required this.contracts, this.onSelected});

  final List<ContractSummary> contracts;
  final ValueChanged<ContractSummary>? onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    if (contracts.isEmpty) {
      return const _Empty(icon: Icons.description_outlined);
    }
    return ListView.separated(
      itemCount: contracts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final contract = contracts[index];
        return CorporateSurfaceCard(
          onTap: onSelected == null ? null : () => onSelected!(contract),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                const CircleAvatar(child: Icon(Icons.description_outlined)),
            title: Text(contract.title),
            subtitle: Text('${contract.number} • ${contract.supplierName}'),
            trailing: StatusChip(
              label: strings.contractState(contract.state),
              type: contract.state == ContractState.active
                  ? StatusType.success
                  : contract.state == ContractState.expired
                      ? StatusType.warning
                      : StatusType.neutral,
            ),
          ),
        );
      },
    );
  }
}

class _WarrantyList extends StatelessWidget {
  const _WarrantyList({required this.warranties, this.onSelected});

  final List<WarrantySummary> warranties;
  final ValueChanged<WarrantySummary>? onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    if (warranties.isEmpty) {
      return const _Empty(icon: Icons.verified_user_outlined);
    }
    return ListView.separated(
      itemCount: warranties.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final warranty = warranties[index];
        return CorporateSurfaceCard(
          onTap: onSelected == null ? null : () => onSelected!(warranty),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                const CircleAvatar(child: Icon(Icons.verified_user_outlined)),
            title: Text(warranty.name),
            subtitle: Text(
              '${warranty.supplierName} • ${warranty.coverage}\n'
              '${strings.linkedAssets}: ${warranty.linkedAssetCount}',
            ),
            trailing: warranty.expiresAt == null
                ? null
                : Text(
                    MaterialLocalizations.of(context)
                        .formatShortDate(warranty.expiresAt!),
                  ),
          ),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    return AssetsConfigurationEmptyState(
      title: strings.noData,
      description: strings.noDataDescription,
      icon: icon,
    );
  }
}
