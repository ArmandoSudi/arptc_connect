class UnplacedAgentSummary {
  const UnplacedAgentSummary({
    required this.id,
    required this.displayName,
    required this.email,
    required this.isActive,
    required this.hasCanonicalIdentity,
  });

  final String id;
  final String displayName;
  final String email;
  final bool isActive;
  final bool hasCanonicalIdentity;

  factory UnplacedAgentSummary.fromMap(Map<String, dynamic> map) {
    return UnplacedAgentSummary(
      id: (map['id'] ?? '').toString().trim(),
      displayName: (map['displayName'] ?? '').toString().trim(),
      email: (map['email'] ?? '').toString().trim().toLowerCase(),
      isActive: map['isActive'] == true,
      hasCanonicalIdentity: map['hasCanonicalIdentity'] == true,
    );
  }
}

class UnplacedAgentPage {
  const UnplacedAgentPage({
    required this.items,
    required this.nextCursor,
    required this.scannedCount,
  });

  final List<UnplacedAgentSummary> items;
  final String? nextCursor;
  final int scannedCount;
  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;

  factory UnplacedAgentPage.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    final items = rawItems is Iterable
        ? rawItems
            .whereType<Map>()
            .map((item) => UnplacedAgentSummary.fromMap(
                  Map<String, dynamic>.from(item),
                ))
            .where((item) => item.id.isNotEmpty)
            .toList(growable: false)
        : const <UnplacedAgentSummary>[];
    final cursor = (map['nextCursor'] ?? '').toString().trim();
    return UnplacedAgentPage(
      items: items,
      nextCursor: cursor.isEmpty ? null : cursor,
      scannedCount: (map['scannedCount'] as num?)?.toInt() ?? 0,
    );
  }
}
