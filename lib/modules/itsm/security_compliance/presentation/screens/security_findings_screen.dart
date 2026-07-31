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

class SecurityFindingsScreen extends ConsumerStatefulWidget {
  const SecurityFindingsScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  ConsumerState<SecurityFindingsScreen> createState() =>
      _SecurityFindingsScreenState();
}

class _SecurityFindingsScreenState
    extends ConsumerState<SecurityFindingsScreen> {
  static const _pageSize = PageRequest.defaultLimit;
  SecurityFindingStatus? _status;

  @override
  Widget build(BuildContext context) {
    final strings = SecurityComplianceStrings.of(context);
    final access = ref.watch(securityComplianceAccessProvider);
    final query = SecurityComplianceQuery(
      scope: SecurityComplianceScope.operational,
      status: _status?.value,
    );
    final request = SecurityComplianceFirstPageRequest(
      query: query,
      limit: _pageSize,
    );
    return SecurityComplianceShell(
      title: strings.value('securityFindingsTitle'),
      subtitle: strings.value('securityFindingsSubtitle'),
      onBack: widget.onBack,
      actions: [
        FilledButton.icon(
          onPressed: access.valueOrNull?.canOperate == true
              ? () => _createFinding(strings)
              : null,
          icon: const Icon(Icons.add_rounded),
          label: Text(strings.value('newFinding')),
        ),
      ],
      child: access.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => SecurityComplianceMessageState(
          icon: Icons.error_outline_rounded,
          title: strings.value('unableToLoad'),
        ),
        data: (value) {
          if (!value.canOperate) {
            return SecurityComplianceMessageState(
              icon: Icons.lock_outline_rounded,
              title: strings.value('accessDenied'),
              description: strings.value('managerAccessRequired'),
            );
          }
          final firstPage = ref.watch(
            securityFindingsFirstPageProvider(request),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: DropdownButton<SecurityFindingStatus?>(
                  value: _status,
                  hint: Text(strings.value('allStatuses')),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(strings.value('allStatuses')),
                    ),
                    for (final status in SecurityFindingStatus.values)
                      DropdownMenuItem(
                        value: status,
                        child: Text(strings.findingStatus(status)),
                      ),
                  ],
                  onChanged: (value) => setState(() => _status = value),
                ),
              ),
              const SizedBox(height: 16),
              SecurityCompliancePagedList<SecurityFinding>(
                firstPage: firstPage,
                onRetry: () => ref.invalidate(
                  securityFindingsFirstPageProvider(request),
                ),
                cursorOf: (finding) => PageCursor({
                  'sortAt': finding.updatedAt,
                  'id': finding.id,
                }),
                loadPage: (cursor) => ref.read(
                  securityFindingsPageProvider(
                    SecurityCompliancePageRequest(
                      query: query,
                      page: PageRequest(limit: _pageSize, cursor: cursor),
                    ),
                  ).future,
                ),
                itemBuilder: (_, finding) => SecurityFindingCard(
                  finding: finding,
                  action: PopupMenuButton<SecurityComplianceCommandType>(
                    onSelected: (command) =>
                        _runFindingAction(finding, command),
                    itemBuilder: (_) => [
                      for (final command in _findingActions(finding.status))
                        PopupMenuItem(
                          value: command,
                          child: Text(strings.findingCommand(command)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createFinding(SecurityComplianceStrings strings) async {
    final values = await showSecurityComplianceActionDialog(
      context,
      title: strings.value('newFinding'),
      submitLabel: strings.value('save'),
      cancelLabel: strings.value('cancel'),
      requiredFieldLabel: strings.value('requiredField'),
      fields: [
        SecurityDialogField(keyName: 'title', label: strings.value('title')),
        SecurityDialogField(
          keyName: 'description',
          label: strings.value('description'),
          multiline: true,
        ),
        SecurityDialogField(keyName: 'source', label: strings.value('source')),
      ],
    );
    if (values == null || !mounted) return;
    await executeSecurityComplianceCommand(
      ref,
      context,
      type: SecurityComplianceCommandType.createFinding,
      payload: {
        ...values,
        'severity': SecurityFindingSeverity.medium.name,
        'risk': SecurityFindingRisk.medium.name,
      },
    );
  }

  List<SecurityComplianceCommandType> _findingActions(
    SecurityFindingStatus status,
  ) =>
      switch (status) {
        SecurityFindingStatus.detected => const [
            SecurityComplianceCommandType.triageFinding,
            SecurityComplianceCommandType.cancelFinding,
          ],
        SecurityFindingStatus.triaged => const [
            SecurityComplianceCommandType.assignFinding,
            SecurityComplianceCommandType.acceptFindingRisk,
            SecurityComplianceCommandType.cancelFinding,
          ],
        SecurityFindingStatus.assigned => const [
            SecurityComplianceCommandType.planRemediation,
            SecurityComplianceCommandType.acceptFindingRisk,
            SecurityComplianceCommandType.cancelFinding,
          ],
        SecurityFindingStatus.remediation => const [
            SecurityComplianceCommandType.submitFindingValidation,
          ],
        SecurityFindingStatus.validation => const [
            SecurityComplianceCommandType.validateFinding,
          ],
        SecurityFindingStatus.riskAccepted => const [
            SecurityComplianceCommandType.closeFinding,
          ],
        SecurityFindingStatus.closed ||
        SecurityFindingStatus.cancelled =>
          const [],
      };

  Future<void> _runFindingAction(
    SecurityFinding finding,
    SecurityComplianceCommandType command,
  ) async {
    final strings = SecurityComplianceStrings.of(context);
    final fields = switch (command) {
      SecurityComplianceCommandType.assignFinding => [
          SecurityDialogField(
            keyName: 'ownerUserId',
            label: strings.value('ownerUserId'),
          ),
        ],
      SecurityComplianceCommandType.planRemediation => [
          SecurityDialogField(
            keyName: 'remediationPlan',
            label: strings.value('remediationPlan'),
            multiline: true,
          ),
        ],
      SecurityComplianceCommandType.validateFinding => [
          SecurityDialogField(
            keyName: 'result',
            label: strings.value('validationResult'),
            options: [
              SecurityDialogOption(
                'passed',
                strings.value('validationPassed'),
              ),
              SecurityDialogOption(
                'failed',
                strings.value('validationFailed'),
              ),
              SecurityDialogOption(
                'partially_validated',
                strings.value('validationPartial'),
              ),
            ],
          ),
          SecurityDialogField(
            keyName: 'comment',
            label: strings.value('comment'),
            multiline: true,
          ),
        ],
      SecurityComplianceCommandType.acceptFindingRisk ||
      SecurityComplianceCommandType.cancelFinding =>
        [
          SecurityDialogField(
            keyName: 'reason',
            label: strings.value('reason'),
            multiline: true,
          ),
        ],
      SecurityComplianceCommandType.submitFindingValidation ||
      SecurityComplianceCommandType.closeFinding =>
        [
          SecurityDialogField(
            keyName: 'comment',
            label: strings.value('comment'),
            multiline: true,
          ),
        ],
      _ => const <SecurityDialogField>[],
    };
    Map<String, String> values = const {};
    if (fields.isNotEmpty) {
      final result = await showSecurityComplianceActionDialog(
        context,
        title: strings.findingCommand(command),
        submitLabel: strings.value('save'),
        cancelLabel: strings.value('cancel'),
        requiredFieldLabel: strings.value('requiredField'),
        fields: fields,
      );
      if (result == null || !mounted) return;
      values = result;
    }
    final revision = await ref.read(
      securityComplianceRevisionProvider(
        SecurityComplianceIdentity(
          type: SecurityComplianceEntityType.finding,
          id: finding.id,
          scope: SecurityComplianceScope.operational,
        ),
      ).future,
    );
    if (!mounted) return;
    await executeSecurityComplianceCommand(
      ref,
      context,
      type: command,
      payload: {
        'findingId': finding.id,
        'expectedRevision': revision,
        if (command == SecurityComplianceCommandType.triageFinding) ...{
          'severity': finding.severity.name,
          'risk': finding.risk.name,
          'dueAt': finding.dueAt?.toIso8601String(),
        },
        if (command == SecurityComplianceCommandType.planRemediation)
          'remediationLinks': const <Object?>[],
        ...values,
      },
    );
  }
}
