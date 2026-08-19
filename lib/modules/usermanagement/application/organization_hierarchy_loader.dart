import 'package:arptc_connect/modules/usermanagement/domain/organization_query.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_unit.dart';

typedef OrganizationUnitPageFetcher = Future<OrganizationPage<OrganizationUnit>>
    Function({
  required OrganizationUnitListQuery query,
  required OrganizationPageRequest page,
});

class OrganizationHierarchyLoader {
  const OrganizationHierarchyLoader({
    required this.fetchPage,
    this.pageSize = OrganizationPageRequest.maximumLimit,
    this.maximumUnits = 5000,
  })  : assert(pageSize > 0),
        assert(pageSize <= OrganizationPageRequest.maximumLimit),
        assert(maximumUnits >= pageSize);

  final OrganizationUnitPageFetcher fetchPage;
  final int pageSize;
  final int maximumUnits;

  Future<List<OrganizationUnit>> load(String organizationId) async {
    final normalizedOrganizationId = organizationId.trim();
    if (normalizedOrganizationId.isEmpty) {
      return const <OrganizationUnit>[];
    }

    final unitsById = <String, OrganizationUnit>{};
    OrganizationPageCursor? cursor;

    while (true) {
      final page = await fetchPage(
        query: OrganizationUnitListQuery(
          organizationId: normalizedOrganizationId,
          status: OrganizationListStatusFilter.active,
          limit: pageSize,
        ),
        page: OrganizationPageRequest(
          limit: pageSize,
          afterNameLower: cursor?.nameLower,
          afterId: cursor?.id,
        ),
      );

      for (final unit in page.items) {
        unitsById[unit.id] = unit;
      }

      final nextCursor = page.nextCursor;
      if (nextCursor == null) break;
      if (unitsById.length >= maximumUnits) {
        throw StateError(
          'The organization hierarchy exceeds the supported form limit.',
        );
      }
      if (cursor?.nameLower == nextCursor.nameLower &&
          cursor?.id == nextCursor.id) {
        throw StateError('The organization hierarchy cursor did not advance.');
      }
      cursor = nextCursor;
    }

    final units = unitsById.values.toList(growable: false);
    units.sort((left, right) {
      final byName = left.nameLower.compareTo(right.nameLower);
      return byName != 0 ? byName : left.id.compareTo(right.id);
    });
    return units;
  }
}
