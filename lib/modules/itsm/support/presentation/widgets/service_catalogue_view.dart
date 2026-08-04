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
    required this.selectedCategoryId,
    required this.onSearchChanged,
    required this.onCategorySelected,
    required this.onItemSelected,
    super.key,
  });

  final List<ServiceCatalogueItem> items;
  final String languageCode;
  final String searchQuery;
  final String? selectedCategoryId;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCategorySelected;
  final ValueChanged<ServiceCatalogueItem> onItemSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final categories = <String, String>{
      for (final item in items)
        item.categoryId: item.categoryName.resolve(languageCode),
    };
    final visibleItems = items
        .where(
          (item) =>
              selectedCategoryId == null ||
              item.categoryId == selectedCategoryId,
        )
        .toList(growable: false);
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
                child: CorporateSurfaceCard(
                  accentColor: Theme.of(context).colorScheme.primary,
                  title: l10n.serviceCatalogueTitle,
                  subtitle: l10n.serviceCatalogueDescription,
                  child: CommonTextInput(
                    label: l10n.search,
                    hintText: l10n.serviceCatalogueSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    onChanged: onSearchChanged,
                  ),
                ),
              ),
            ),
            if (categories.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(l10n.allCatalogueCategories),
                        selected: selectedCategoryId == null,
                        onSelected: (_) => onCategorySelected(null),
                      ),
                      ...categories.entries.map(
                        (entry) => ChoiceChip(
                          label: Text(entry.value),
                          selected: selectedCategoryId == entry.key,
                          onSelected: (_) => onCategorySelected(entry.key),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (visibleItems.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView(
                  icon: Icons.inventory_2_outlined,
                  title: l10n.serviceCatalogueEmpty,
                  description: l10n.serviceCatalogueEmptyDescription,
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
                    mainAxisExtent: 270,
                  ),
                  itemCount: visibleItems.length,
                  itemBuilder: (context, index) {
                    final item = visibleItems[index];
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
          Text(
            item.fulfilmentSla?.resolve(languageCode) ??
                S.of(context).estimatedDelivery,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(item.code, style: theme.textTheme.labelMedium),
              const SizedBox(width: 8),
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
