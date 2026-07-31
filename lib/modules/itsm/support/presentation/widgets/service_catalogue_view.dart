import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/corporate_components.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:flutter/material.dart';

import '../../domain/service_catalogue.dart';

class ServiceCatalogueView extends StatelessWidget {
  const ServiceCatalogueView({
    required this.items,
    required this.languageCode,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onItemSelected,
    super.key,
  });

  final List<ServiceCatalogueItem> items;
  final String languageCode;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ServiceCatalogueItem> onItemSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1180
            ? 3
            : constraints.maxWidth >= 720
                ? 2
                : 1;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              sliver: SliverToBoxAdapter(
                child: CommonTextInput(
                  label: l10n.search,
                  hintText: l10n.itsmServiceCatalogue,
                  prefixIcon: const Icon(Icons.search),
                  onChanged: onSearchChanged,
                ),
              ),
            ),
            if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView(
                  icon: Icons.inventory_2_outlined,
                  title: l10n.noDataAvailable,
                  description: l10n.noDataDescription,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 250,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _CatalogueCard(
                      item: item,
                      languageCode: languageCode,
                      onTap: () => onItemSelected(item),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CatalogueCard extends StatelessWidget {
  const _CatalogueCard({
    required this.item,
    required this.languageCode,
    required this.onTap,
  });

  final ServiceCatalogueItem item;
  final String languageCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CorporateSurfaceCard(
      onTap: onTap,
      accentColor: theme.colorScheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: Icon(_catalogueIcon(item.iconKey)),
              ),
              const Spacer(),
              Chip(
                label: Text(item.categoryName.resolve(languageCode)),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            item.name.resolve(languageCode),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 58,
            child: Text(
              item.description.resolve(languageCode),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(item.code, style: theme.textTheme.labelMedium),
              const Spacer(),
              Icon(Icons.arrow_forward, color: theme.colorScheme.primary),
            ],
          ),
        ],
      ),
    );
  }
}

IconData _catalogueIcon(String key) {
  return switch (key.trim().toLowerCase()) {
    'computer' || 'install_desktop' => Icons.computer,
    'build' => Icons.build_outlined,
    'key' => Icons.key_outlined,
    'manage_accounts' => Icons.manage_accounts_outlined,
    'security' => Icons.security_outlined,
    'swap_horiz' => Icons.swap_horiz,
    'report_problem' => Icons.report_problem_outlined,
    _ => Icons.support_agent,
  };
}
