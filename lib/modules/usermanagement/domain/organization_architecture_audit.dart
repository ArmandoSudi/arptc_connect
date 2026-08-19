class OrganizationArchitectureAuditReport {
  const OrganizationArchitectureAuditReport({
    required this.organizationId,
    required this.dryRun,
    required this.scanned,
    required this.truncated,
    required this.issues,
    required this.repairedCount,
    required this.repairedAgentIds,
    required this.skippedAgentIds,
  });

  final String organizationId;
  final bool dryRun;
  final Map<String, int> scanned;
  final bool truncated;
  final List<OrganizationArchitectureIssue> issues;
  final int repairedCount;
  final List<String> repairedAgentIds;
  final List<String> skippedAgentIds;

  int get issueCount => issues.length;
  bool get isClean => issueCount == 0 && !truncated;
  bool get canRepair => !dryRun ? false : !truncated && issueCount > 0;

  factory OrganizationArchitectureAuditReport.fromMap(
    Map<String, dynamic> map,
  ) {
    final rawScanned = map['scanned'];
    final scanned = <String, int>{};
    if (rawScanned is Map) {
      for (final entry in rawScanned.entries) {
        scanned[entry.key.toString()] = _integer(entry.value);
      }
    }
    final rawIssues = map['issues'];
    return OrganizationArchitectureAuditReport(
      organizationId: (map['organizationId'] ?? '').toString().trim(),
      dryRun: map['dryRun'] != false,
      scanned: Map.unmodifiable(scanned),
      truncated: map['truncated'] == true,
      issues: List.unmodifiable(
        rawIssues is Iterable
            ? rawIssues
                .whereType<Map>()
                .map((issue) => OrganizationArchitectureIssue.fromMap(
                      Map<String, dynamic>.from(issue),
                    ))
            : const <OrganizationArchitectureIssue>[],
      ),
      repairedCount: _integer(map['repairedCount']),
      repairedAgentIds: _strings(map['repairedAgentIds']),
      skippedAgentIds: _strings(map['skippedAgentIds']),
    );
  }
}

class OrganizationArchitectureIssue {
  const OrganizationArchitectureIssue({
    required this.type,
    required this.agentId,
    required this.unitId,
    required this.assignmentIds,
  });

  final String type;
  final String agentId;
  final String unitId;
  final List<String> assignmentIds;

  String get subjectId => agentId.isNotEmpty
      ? agentId
      : unitId.isNotEmpty
          ? unitId
          : assignmentIds.join(', ');

  factory OrganizationArchitectureIssue.fromMap(Map<String, dynamic> map) {
    return OrganizationArchitectureIssue(
      type: (map['type'] ?? 'UNKNOWN').toString().trim(),
      agentId: (map['agentId'] ?? '').toString().trim(),
      unitId: (map['unitId'] ?? '').toString().trim(),
      assignmentIds: _strings(
        map['assignmentIds'] ?? map['assignments'] ?? map['assignmentId'],
      ),
    );
  }
}

int _integer(Object? value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

List<String> _strings(Object? value) {
  final values = value is Iterable
      ? value
      : value == null
          ? const []
          : [value];
  return List.unmodifiable(
    values
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty),
  );
}
