import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/pagination.dart';
import '../../application/security_compliance_application.dart';
import '../../data/security_compliance_repository.dart';
import '../../domain/security_compliance_domain.dart';
import '../security_compliance_strings.dart';
import '../widgets/security_compliance_action_dialog.dart';
import '../widgets/security_compliance_cards.dart';
import '../widgets/security_compliance_command_action.dart';
import '../widgets/security_compliance_paged_list.dart';
import '../widgets/security_compliance_shell.dart';
import '../widgets/security_compliance_state.dart';

class AssetComplianceScreen extends ConsumerWidget {
  const AssetComplianceScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  static const _pageSize = PageRequest.defaultLimit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = SecurityComplianceStrings.of(context);
    final access = ref.watch(securityComplianceAccessProvider);
    return SecurityComplianceShell(
      title: strings.value('assetComplianceTitle'),
      subtitle: strings.value('assetComplianceSubtitle'),
      onBack: onBack,
      actions: [
        FilledButton.icon(
          onPressed: access.valueOrNull?.canOperate == true
              ? () => _recordAssessment(context, ref, strings)
              : null,
          icon: const Icon(Icons.fact_check_outlined),
          label: Text(strings.value('recordAssessment')),
        ),
      ],
      child: access.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => SecurityComplianceMessageState(
          icon: Icons.error_outline_rounded,
          title: strings.value('unableToLoad'),
        ),
        data: (value) {
          if (value.canOperate) {
            return _buildOperational(context, ref);
          }
          if (value.canViewOwnCompliance) {
            return _buildOwn(context, ref);
          }
          return SecurityComplianceMessageState(
            icon: Icons.lock_outline_rounded,
            title: strings.value('accessDenied'),
            description: strings.value('ownComplianceUnavailable'),
          );
        },
      ),
    );
  }

  Widget _buildOperational(BuildContext context, WidgetRef ref) {
    const query = SecurityComplianceQuery(
      scope: SecurityComplianceScope.operational,
    );
    const request = SecurityComplianceFirstPageRequest(
      query: query,
      limit: _pageSize,
    );
    final firstPage = ref.watch(
      assetComplianceAssessmentsFirstPageProvider(request),
    );
    return SecurityCompliancePagedList<AssetComplianceAssessment>(
      firstPage: firstPage,
      onRetry: () => ref.invalidate(
        assetComplianceAssessmentsFirstPageProvider(request),
      ),
      cursorOf: (assessment) => PageCursor({
        'sortAt': assessment.updatedAt,
        'id': assessment.id,
      }),
      loadPage: (cursor) => ref.read(
        assetComplianceAssessmentsPageProvider(
          SecurityCompliancePageRequest(
            query: query,
            page: PageRequest(limit: _pageSize, cursor: cursor),
          ),
        ).future,
      ),
      itemBuilder: (_, assessment) =>
          AssetComplianceAssessmentCard(assessment: assessment),
    );
  }

  Widget _buildOwn(BuildContext context, WidgetRef ref) {
    final firstPage = ref.watch(ownDeviceComplianceProvider(_pageSize));
    return SecurityCompliancePagedList<OwnDeviceComplianceProjection>(
      firstPage: firstPage,
      onRetry: () => ref.invalidate(ownDeviceComplianceProvider(_pageSize)),
      cursorOf: (projection) => PageCursor({
        'sortAt': projection.updatedAt,
        'id': projection.id,
      }),
      loadPage: (cursor) => ref.read(
        ownDeviceCompliancePageProvider(
          PageRequest(limit: _pageSize, cursor: cursor),
        ).future,
      ),
      itemBuilder: (_, projection) => OwnComplianceCard(projection: projection),
    );
  }

  Future<void> _recordAssessment(
    BuildContext context,
    WidgetRef ref,
    SecurityComplianceStrings strings,
  ) async {
    final values = await showSecurityComplianceActionDialog(
      context,
      title: strings.value('recordAssessment'),
      submitLabel: strings.value('save'),
      cancelLabel: strings.value('cancel'),
      requiredFieldLabel: strings.value('requiredField'),
      fields: [
        SecurityDialogField(
            keyName: 'assetId', label: strings.value('assetId')),
        SecurityDialogField(
          keyName: 'assetTag',
          label: strings.value('assetTag'),
        ),
        SecurityDialogField(
          keyName: 'assetName',
          label: strings.value('assetName'),
        ),
        SecurityDialogField(
          keyName: 'summary',
          label: strings.value('remediationSummary'),
          multiline: true,
        ),
        for (final control in const [
          ('operating_system_support', 'controlOperatingSystem'),
          ('patch_status', 'controlPatchStatus'),
          ('antivirus_edr', 'controlAntivirus'),
          ('encryption', 'controlEncryption'),
          ('backup', 'controlBackup'),
          ('approved_software', 'controlApprovedSoftware'),
          ('security_baseline', 'controlSecurityBaseline'),
        ])
          SecurityDialogField(
            keyName: control.$1,
            label: strings.value(control.$2),
            options: [
              SecurityDialogOption(
                'compliant',
                strings.value('complianceCompliant'),
              ),
              SecurityDialogOption(
                'non_compliant',
                strings.value('complianceActionRequired'),
              ),
              SecurityDialogOption(
                'not_applicable',
                strings.value('notApplicable'),
              ),
              SecurityDialogOption(
                'unknown',
                strings.value('unknown'),
              ),
            ],
          ),
      ],
    );
    if (values == null || !context.mounted) return;
    await executeSecurityComplianceCommand(
      ref,
      context,
      type: SecurityComplianceCommandType.assessCompliance,
      payload: {
        'assetId': values['assetId'],
        'assetTag': values['assetTag'],
        'assetName': values['assetName'],
        'checks': [
          for (final control in const [
            'operating_system_support',
            'patch_status',
            'antivirus_edr',
            'encryption',
            'backup',
            'approved_software',
            'security_baseline',
          ])
            {
              'control': control,
              'result': values[control],
              'summary': values['summary'],
              'evidenceIds': const <String>[],
            },
        ],
        'remediationSummary': values['summary'],
        'evidenceIds': const <String>[],
      },
    );
  }
}
