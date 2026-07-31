import 'package:arptc_connect/widgets/corporate_components.dart';
import 'package:arptc_connect/widgets/status_chip.dart';
import 'package:flutter/material.dart';

import '../../application/assets_configuration_contracts.dart';
import '../assets_configuration_strings.dart';
import 'assets_configuration_state.dart';

class LicencesView extends StatelessWidget {
  const LicencesView({
    required this.licences,
    super.key,
    this.onSelected,
  });

  final List<LicenceSummary> licences;
  final ValueChanged<LicenceSummary>? onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    if (licences.isEmpty) {
      return AssetsConfigurationEmptyState(
        title: strings.noData,
        description: strings.noDataDescription,
        icon: Icons.key_outlined,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1050
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
            for (final licence in licences)
              SizedBox(
                width: width,
                child: CorporateSurfaceCard(
                  onTap: onSelected == null ? null : () => onSelected!(licence),
                  accentColor:
                      _complianceColor(context, licence.complianceState),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.key_outlined),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              licence.productName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${licence.vendorName} • ${licence.licenceType}'),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: licence.purchasedQuantity == 0
                            ? 0
                            : licence.allocatedQuantity /
                                licence.purchasedQuantity,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${strings.allocation}: ${licence.allocatedQuantity} • '
                        '${strings.available}: ${licence.availableQuantity}',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatusChip(
                            label: strings.complianceState(
                              licence.complianceState,
                            ),
                            type: _complianceType(licence.complianceState),
                          ),
                          if (licence.expiresAt != null)
                            Text(
                              '${strings.expires}: '
                              '${MaterialLocalizations.of(context).formatShortDate(licence.expiresAt!)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
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

StatusType _complianceType(ComplianceState state) => switch (state) {
      ComplianceState.compliant => StatusType.success,
      ComplianceState.actionRequired => StatusType.warning,
      ComplianceState.assessmentPending => StatusType.neutral,
    };

Color _complianceColor(BuildContext context, ComplianceState state) {
  return switch (state) {
    ComplianceState.compliant => Colors.green.shade700,
    ComplianceState.actionRequired => Colors.orange.shade800,
    ComplianceState.assessmentPending => Theme.of(context).colorScheme.outline,
  };
}
