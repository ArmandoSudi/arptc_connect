import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_architecture_audit.dart';
import 'package:flutter/material.dart';

enum OrganizationAuditDialogAction { close, repair }

Future<OrganizationAuditDialogAction?> showOrganizationAuditReportDialog(
  BuildContext context, {
  required OrganizationArchitectureAuditReport report,
}) {
  return showDialog<OrganizationAuditDialogAction>(
    context: context,
    builder: (context) => OrganizationAuditReportDialog(report: report),
  );
}

class OrganizationAuditReportDialog extends StatelessWidget {
  const OrganizationAuditReportDialog({
    required this.report,
    super.key,
  });

  final OrganizationArchitectureAuditReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(
        report.isClean ? Icons.verified_outlined : Icons.fact_check_outlined,
        color: report.isClean ? colors.primary : colors.tertiary,
      ),
      title: Text(l10n.lookup('umArchitectureAudit')),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 540),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _AuditSummary(report: report),
              if (report.truncated) ...[
                const SizedBox(height: 12),
                Material(
                  color: colors.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      l10n.lookup('umAuditTruncated'),
                      style: TextStyle(color: colors.onErrorContainer),
                    ),
                  ),
                ),
              ],
              if (report.issues.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  l10n.lookup('umAuditIssues'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                ...report.issues.take(25).map(
                      (issue) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.warning_amber_rounded),
                        title: Text(_readableIssueType(issue.type)),
                        subtitle: issue.subjectId.isEmpty
                            ? null
                            : Text(issue.subjectId),
                      ),
                    ),
                if (report.issues.length > 25)
                  Text(
                    '+${report.issues.length - 25} ${l10n.lookup('umMoreIssues')}',
                  ),
              ],
              if (!report.dryRun) ...[
                const SizedBox(height: 12),
                Text(
                  '${l10n.lookup('umRepairedProjections')}: '
                  '${report.repairedCount}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (report.skippedAgentIds.isNotEmpty)
                  Text(
                    '${l10n.lookup('umSkippedAgents')}: '
                    '${report.skippedAgentIds.length}',
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            OrganizationAuditDialogAction.close,
          ),
          child: Text(l10n.close),
        ),
        if (report.canRepair)
          FilledButton.icon(
            onPressed: () => Navigator.pop(
              context,
              OrganizationAuditDialogAction.repair,
            ),
            icon: const Icon(Icons.build_circle_outlined),
            label: Text(l10n.lookup('umRepairProjections')),
          ),
      ],
    );
  }
}

class _AuditSummary extends StatelessWidget {
  const _AuditSummary({required this.report});

  final OrganizationArchitectureAuditReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final colors = Theme.of(context).colorScheme;
    final rows = report.scanned.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return Material(
      color: report.isClean
          ? colors.primaryContainer
          : colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.isClean
                  ? l10n.lookup('umAuditClean')
                  : '${report.issueCount} ${l10n.lookup('umAuditIssuesFound')}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rows
                  .map(
                    (entry) => Chip(
                      label: Text('${entry.key}: ${entry.value}'),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

String _readableIssueType(String value) {
  final words =
      value.toLowerCase().split('_').where((word) => word.isNotEmpty).toList();
  if (words.isEmpty) return value;
  final text = words.join(' ');
  return '${text[0].toUpperCase()}${text.substring(1)}';
}
