import 'package:flutter/material.dart';

import '../../domain/security_compliance_domain.dart';
import '../security_compliance_strings.dart';
import 'security_compliance_shell.dart';

class SecurityFindingCard extends StatelessWidget {
  const SecurityFindingCard({
    required this.finding,
    super.key,
    this.action,
  });

  final SecurityFinding finding;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final strings = SecurityComplianceStrings.of(context);
    return SecurityComplianceCard(
      title: finding.title,
      subtitle: finding.reference,
      trailing:
          action ?? _StatusChip(label: strings.findingStatus(finding.status)),
      child: _Details(
        values: {
          strings.value('severity'): strings.findingSeverity(finding.severity),
          strings.value('risk'): strings.findingRisk(finding.risk),
          strings.value('owner'):
              finding.owner?.displayName ?? strings.value('notAssigned'),
          strings.value('evidence'): finding.evidence.length.toString(),
        },
      ),
    );
  }
}

class SecurityExceptionCard extends StatelessWidget {
  const SecurityExceptionCard({
    required this.exception,
    super.key,
    this.action,
  });

  final SecurityException exception;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final strings = SecurityComplianceStrings.of(context);
    return SecurityComplianceCard(
      title: exception.title,
      subtitle: exception.reference,
      trailing: action ??
          _StatusChip(label: strings.exceptionStatus(exception.status)),
      child: _Details(
        values: {
          strings.value('scope'): exception.scope,
          strings.value('reviewDate'): _date(exception.reviewAt),
          strings.value('period'):
              '${_date(exception.requestedStartAt)} – ${_date(exception.requestedEndAt)}',
          strings.value('owner'):
              exception.owner?.displayName ?? exception.requester.displayName,
        },
      ),
    );
  }
}

class AssetComplianceAssessmentCard extends StatelessWidget {
  const AssetComplianceAssessmentCard({required this.assessment, super.key});

  final AssetComplianceAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final strings = SecurityComplianceStrings.of(context);
    return SecurityComplianceCard(
      title: assessment.assetName,
      subtitle: assessment.assetTag,
      trailing: _StatusChip(
        label: strings.assessmentResult(assessment.result),
      ),
      child: _Details(
        values: {
          strings.value('assetId'): assessment.assetId,
          strings.value('assessedAt'): _date(assessment.assessedAt),
          strings.value('owner'): assessment.assignedUserName,
          strings.value('evidence'): assessment.evidence.length.toString(),
        },
      ),
    );
  }
}

class OwnComplianceCard extends StatelessWidget {
  const OwnComplianceCard({required this.projection, super.key});

  final OwnDeviceComplianceProjection projection;

  @override
  Widget build(BuildContext context) {
    final strings = SecurityComplianceStrings.of(context);
    return SecurityComplianceCard(
      title: projection.assetName,
      subtitle: projection.assetTag,
      trailing: _StatusChip(
        label: strings.complianceStatus(projection.status),
      ),
      child: _Details(
        values: {
          strings.value('assetId'): projection.assetId,
          strings.value('assessedAt'): _date(projection.assessedAt),
          strings.value('updated'): _date(projection.updatedAt),
        },
      ),
    );
  }
}

class AccessReviewCampaignCard extends StatelessWidget {
  const AccessReviewCampaignCard({
    required this.campaign,
    super.key,
    this.action,
  });

  final AccessReviewCampaign campaign;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final strings = SecurityComplianceStrings.of(context);
    return SecurityComplianceCard(
      title: campaign.title,
      subtitle: campaign.reference,
      trailing:
          action ?? _StatusChip(label: strings.campaignStatus(campaign.status)),
      child: _Details(
        values: {
          strings.value('system'): campaign.systemName,
          strings.value('scope'): campaign.scope,
          strings.value('owner'): campaign.owner.displayName,
          strings.value('dueDate'): _date(campaign.dueAt),
        },
      ),
    );
  }
}

class AccessReviewItemCard extends StatelessWidget {
  const AccessReviewItemCard({
    required this.item,
    super.key,
    this.action,
  });

  final AccessReviewItem item;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final strings = SecurityComplianceStrings.of(context);
    return SecurityComplianceCard(
      title: item.systemName,
      subtitle: item.subjectUser.displayName,
      trailing: action ??
          _StatusChip(label: strings.reviewStatus(item.completionStatus)),
      child: _Details(
        values: {
          strings.value('currentAccess'): item.currentAccess,
          strings.value('currentRole'): item.currentRole,
          strings.value('department'): item.departmentName,
          strings.value('dueDate'): _date(item.dueAt),
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Chip(
        label: Text(label),
        visualDensity: VisualDensity.compact,
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      );
}

class _Details extends StatelessWidget {
  const _Details({required this.values});

  final Map<String, String> values;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in values.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(flex: 3, child: Text(entry.value)),
              ],
            ),
          ),
      ],
    );
  }
}

String _date(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}
