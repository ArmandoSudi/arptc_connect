import 'package:arptc_connect/widgets/corporate_components.dart';
import 'package:flutter/material.dart';

import '../assets_configuration_strings.dart';

class AssetsConfigurationOverviewView extends StatelessWidget {
  const AssetsConfigurationOverviewView({
    required this.canOperate,
    super.key,
    this.onMyAssets,
    this.onAssetRegister,
    this.onStock,
    this.onLicences,
    this.onSuppliersWarranties,
    this.onCmdb,
  });

  final bool canOperate;
  final VoidCallback? onMyAssets;
  final VoidCallback? onAssetRegister;
  final VoidCallback? onStock;
  final VoidCallback? onLicences;
  final VoidCallback? onSuppliersWarranties;
  final VoidCallback? onCmdb;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AssetsConfigurationStrings.of(context);
    final destinations = <_Destination>[
      _Destination(
        title: strings.myAssets,
        subtitle: strings.myAssetsDescription,
        icon: Icons.devices_other_outlined,
        onTap: onMyAssets,
      ),
      if (canOperate) ...[
        _Destination(
          title: strings.assetRegister,
          subtitle: strings.assetRegisterDescription,
          icon: Icons.inventory_2_outlined,
          onTap: onAssetRegister,
        ),
        _Destination(
          title: strings.stock,
          subtitle: strings.stockDescription,
          icon: Icons.warehouse_outlined,
          onTap: onStock,
        ),
        _Destination(
          title: strings.licences,
          subtitle: strings.licencesDescription,
          icon: Icons.key_outlined,
          onTap: onLicences,
        ),
        _Destination(
          title: strings.suppliersWarranties,
          subtitle: strings.suppliersWarrantiesDescription,
          icon: Icons.handshake_outlined,
          onTap: onSuppliersWarranties,
        ),
        _Destination(
          title: strings.cmdb,
          subtitle: strings.cmdbDescription,
          icon: Icons.account_tree_outlined,
          onTap: onCmdb,
        ),
      ],
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1080
            ? 3
            : constraints.maxWidth >= 680
                ? 2
                : 1;
        const spacing = 16.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final destination in destinations)
              SizedBox(
                width: width,
                child: CorporateSurfaceCard(
                  accentColor: theme.colorScheme.primary,
                  onTap: destination.onTap,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          destination.icon,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              destination.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              destination.subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Destination {
  const _Destination({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
}
