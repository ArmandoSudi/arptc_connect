import 'dart:collection';

/// A selectable catalogue dependency backed by a trusted configuration record.
class CatalogueFormOption {
  const CatalogueFormOption({
    required this.id,
    required this.label,
    this.version,
  });

  final String id;
  final String label;
  final int? version;
}

/// Values that a service-catalogue manager may select while drafting a service.
class CatalogueFormParameters {
  CatalogueFormParameters({
    Iterable<CatalogueFormOption> categories = const [],
    Iterable<CatalogueFormOption> configurationItems = const [],
    Iterable<CatalogueFormOption> workflows = const [],
    Iterable<CatalogueFormOption> fulfilmentGroups = const [],
    Iterable<CatalogueFormOption> slaPolicies = const [],
    Iterable<CatalogueFormOption> approvalPolicies = const [],
  })  : categories = _freeze(categories),
        configurationItems = _freeze(configurationItems),
        workflows = _freeze(workflows),
        fulfilmentGroups = _freeze(fulfilmentGroups),
        slaPolicies = _freeze(slaPolicies),
        approvalPolicies = _freeze(approvalPolicies);

  const CatalogueFormParameters.empty()
      : categories = const [],
        configurationItems = const [],
        workflows = const [],
        fulfilmentGroups = const [],
        slaPolicies = const [],
        approvalPolicies = const [];

  final List<CatalogueFormOption> categories;
  final List<CatalogueFormOption> configurationItems;
  final List<CatalogueFormOption> workflows;
  final List<CatalogueFormOption> fulfilmentGroups;
  final List<CatalogueFormOption> slaPolicies;
  final List<CatalogueFormOption> approvalPolicies;

  static List<CatalogueFormOption> _freeze(
    Iterable<CatalogueFormOption> values,
  ) {
    final byId = <String, CatalogueFormOption>{
      for (final value in values)
        if (value.id.trim().isNotEmpty) value.id.trim(): value,
    };
    final sorted = byId.values.toList()
      ..sort(
        (left, right) => left.label.toLowerCase().compareTo(
              right.label.toLowerCase(),
            ),
      );
    return UnmodifiableListView(sorted);
  }
}
