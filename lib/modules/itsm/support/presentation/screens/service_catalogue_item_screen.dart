import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/widgets/corporate_components.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/support_providers.dart';
import '../../domain/service_catalogue.dart';

class ServiceCatalogueItemScreen extends ConsumerStatefulWidget {
  const ServiceCatalogueItemScreen({
    required this.catalogueItemId,
    super.key,
    this.onCreateRequest,
  });

  final String catalogueItemId;
  final ValueChanged<ServiceCatalogueItem>? onCreateRequest;

  @override
  ConsumerState<ServiceCatalogueItemScreen> createState() =>
      _ServiceCatalogueItemScreenState();
}

class _ServiceCatalogueItemScreenState
    extends ConsumerState<ServiceCatalogueItemScreen> {
  late final DateTime _effectiveAt;

  @override
  void initState() {
    super.initState();
    _effectiveAt = DateTime.now().toUtc();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final catalogueContext =
        ref.watch(serviceRequestCatalogueContextProvider).valueOrNull;
    final request = PublishedCatalogueItemRequest(
      id: widget.catalogueItemId,
      at: _effectiveAt,
      departmentId: catalogueContext?.departmentId,
      serviceId: catalogueContext?.serviceId,
    );
    final item = ref.watch(publishedServiceCatalogueItemProvider(request));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.itsmServiceCatalogue)),
      body: item.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorStateView(
          title: l10n.unableToLoad,
          description: error.toString(),
          onRetry: () =>
              ref.invalidate(publishedServiceCatalogueItemProvider(request)),
        ),
        data: (value) {
          if (value == null) {
            return EmptyStateView(
              icon: Icons.inventory_2_outlined,
              title: l10n.noDataAvailable,
              description: l10n.noDataDescription,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CorporateSurfaceCard(
                title: value.name.resolve(locale),
                subtitle: value.description.resolve(locale),
                accentColor: Theme.of(context).colorScheme.primary,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text(value.code)),
                    Chip(label: Text(value.categoryName.resolve(locale))),
                  ],
                ),
              ),
              if (value.formFields.isNotEmpty) ...[
                const SizedBox(height: 16),
                CorporateSurfaceCard(
                  title: l10n.agentInformation,
                  child: Column(
                    children: value.formFields
                        .map(
                          (field) => ListTile(
                            leading: const Icon(Icons.input_outlined),
                            title: Text(field.label.resolve(locale)),
                            subtitle: field.helpText == null
                                ? null
                                : Text(field.helpText!.resolve(locale)),
                            trailing: field.required
                                ? const Icon(Icons.star, size: 14)
                                : null,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ],
              if (value.requiredDocuments.isNotEmpty) ...[
                const SizedBox(height: 16),
                CorporateSurfaceCard(
                  title: l10n.documents,
                  child: Column(
                    children: value.requiredDocuments
                        .map(
                          (document) => ListTile(
                            leading: const Icon(Icons.description_outlined),
                            title: Text(document.label.resolve(locale)),
                            trailing: document.required
                                ? const Icon(Icons.star, size: 14)
                                : null,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: widget.onCreateRequest == null
                    ? null
                    : () => widget.onCreateRequest!(value),
                icon: const Icon(Icons.add_task),
                label: Text(l10n.create),
              ),
            ],
          );
        },
      ),
    );
  }
}
