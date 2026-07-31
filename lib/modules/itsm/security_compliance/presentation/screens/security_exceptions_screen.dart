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

class SecurityExceptionsScreen extends ConsumerStatefulWidget {
  const SecurityExceptionsScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  ConsumerState<SecurityExceptionsScreen> createState() =>
      _SecurityExceptionsScreenState();
}

class _SecurityExceptionsScreenState
    extends ConsumerState<SecurityExceptionsScreen> {
  static const _pageSize = PageRequest.defaultLimit;
  SecurityExceptionStatus? _status;

  @override
  Widget build(BuildContext context) {
    final strings = SecurityComplianceStrings.of(context);
    final access = ref.watch(securityComplianceAccessProvider);
    return SecurityComplianceShell(
      title: strings.value('securityExceptionsTitle'),
      subtitle: strings.value('securityExceptionsSubtitle'),
      onBack: widget.onBack,
      actions: [
        FilledButton.icon(
          onPressed: access.valueOrNull?.canSubmitException == true
              ? () => _submitException(strings)
              : null,
          icon: const Icon(Icons.add_rounded),
          label: Text(strings.value('submitException')),
        ),
      ],
      child: access.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => SecurityComplianceMessageState(
          icon: Icons.error_outline_rounded,
          title: strings.value('unableToLoad'),
        ),
        data: (value) {
          if (!value.canOperate && !value.canUseSelfService) {
            return SecurityComplianceMessageState(
              icon: Icons.lock_outline_rounded,
              title: strings.value('accessDenied'),
              description: strings.value('selfServiceAccessRequired'),
            );
          }
          return _buildList(strings, value.canOperate);
        },
      ),
    );
  }

  Widget _buildList(
    SecurityComplianceStrings strings,
    bool operational,
  ) {
    final query = SecurityComplianceQuery(
      scope: operational
          ? SecurityComplianceScope.operational
          : SecurityComplianceScope.selfService,
      status: _status?.value,
    );
    final request = SecurityComplianceFirstPageRequest(
      query: query,
      limit: _pageSize,
    );
    final firstPage = ref.watch(securityExceptionsFirstPageProvider(request));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!operational)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(strings.value('selfServiceOnlyNotice')),
          ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: DropdownButton<SecurityExceptionStatus?>(
            value: _status,
            hint: Text(strings.value('allStatuses')),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(strings.value('allStatuses')),
              ),
              for (final status in SecurityExceptionStatus.values)
                DropdownMenuItem(
                  value: status,
                  child: Text(strings.exceptionStatus(status)),
                ),
            ],
            onChanged: (value) => setState(() => _status = value),
          ),
        ),
        const SizedBox(height: 16),
        SecurityCompliancePagedList<SecurityException>(
          firstPage: firstPage,
          onRetry: () => ref.invalidate(
            securityExceptionsFirstPageProvider(request),
          ),
          cursorOf: (exception) => PageCursor({
            'sortAt': exception.updatedAt,
            'id': exception.id,
          }),
          loadPage: (cursor) => ref.read(
            securityExceptionsPageProvider(
              SecurityCompliancePageRequest(
                query: query,
                page: PageRequest(limit: _pageSize, cursor: cursor),
              ),
            ).future,
          ),
          itemBuilder: (_, exception) => SecurityExceptionCard(
            exception: exception,
            action: PopupMenuButton<SecurityComplianceCommandType>(
              onSelected: (command) =>
                  _runExceptionAction(exception, command, operational),
              itemBuilder: (_) => [
                for (final command
                    in _exceptionActions(exception.status, operational))
                  PopupMenuItem(
                    value: command,
                    child: Text(strings.exceptionCommand(command)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitException(SecurityComplianceStrings strings) async {
    final values = await showSecurityComplianceActionDialog(
      context,
      title: strings.value('submitException'),
      submitLabel: strings.value('submit'),
      cancelLabel: strings.value('cancel'),
      requiredFieldLabel: strings.value('requiredField'),
      fields: [
        SecurityDialogField(keyName: 'title', label: strings.value('title')),
        SecurityDialogField(
          keyName: 'requirementOrControl',
          label: strings.value('requirementOrControl'),
        ),
        SecurityDialogField(
          keyName: 'businessJustification',
          label: strings.value('businessJustification'),
          multiline: true,
        ),
        SecurityDialogField(keyName: 'scope', label: strings.value('scope')),
        SecurityDialogField(
          keyName: 'riskDescription',
          label: strings.value('riskDescription'),
          multiline: true,
        ),
        SecurityDialogField(
          keyName: 'compensatingControl',
          label: strings.value('compensatingControl'),
          multiline: true,
        ),
      ],
    );
    if (values == null || !mounted) return;
    final now = DateTime.now().toUtc();
    final exceptionId = 'exception_${now.microsecondsSinceEpoch}';
    final created = await executeSecurityComplianceCommand(
      ref,
      context,
      type: SecurityComplianceCommandType.createException,
      payload: {
        'exceptionId': exceptionId,
        'title': values['title'],
        'requirementOrControl': values['requirementOrControl'],
        'businessJustification': values['businessJustification'],
        'scope': values['scope'],
        'riskDescription': values['riskDescription'],
        'compensatingControls': [
          {
            'id': 'control_1',
            'description': values['compensatingControl'],
            'effective': false,
            'validationNotes': '',
          },
        ],
        'requestedStartAt': now.toIso8601String(),
        'requestedEndAt': now.add(const Duration(days: 30)).toIso8601String(),
        'reviewAt': now.add(const Duration(days: 15)).toIso8601String(),
        'confidentiality': 'confidential',
      },
    );
    if (!created || !mounted) return;
    final operational =
        ref.read(securityComplianceAccessProvider).valueOrNull?.canOperate ==
            true;
    final revision = await ref.read(
      securityComplianceRevisionProvider(
        SecurityComplianceIdentity(
          type: SecurityComplianceEntityType.exception,
          id: exceptionId,
          scope: operational
              ? SecurityComplianceScope.operational
              : SecurityComplianceScope.selfService,
        ),
      ).future,
    );
    if (!mounted) return;
    await executeSecurityComplianceCommand(
      ref,
      context,
      type: SecurityComplianceCommandType.submitException,
      payload: {
        'exceptionId': exceptionId,
        'expectedRevision': revision,
      },
    );
  }

  List<SecurityComplianceCommandType> _exceptionActions(
    SecurityExceptionStatus status,
    bool operational,
  ) {
    if (!operational) {
      return switch (status) {
        SecurityExceptionStatus.draft => const [
            SecurityComplianceCommandType.submitException,
          ],
        SecurityExceptionStatus.approved ||
        SecurityExceptionStatus.active ||
        SecurityExceptionStatus.expired =>
          const [
            SecurityComplianceCommandType.renewException,
            SecurityComplianceCommandType.closeException,
          ],
        _ => const [],
      };
    }
    return switch (status) {
      SecurityExceptionStatus.draft => const [
          SecurityComplianceCommandType.submitException,
        ],
      SecurityExceptionStatus.submitted ||
      SecurityExceptionStatus.underReview =>
        const [
          SecurityComplianceCommandType.requestExceptionApproval,
        ],
      SecurityExceptionStatus.awaitingApproval => const [
          SecurityComplianceCommandType.decideExceptionApproval,
        ],
      SecurityExceptionStatus.approved => const [
          SecurityComplianceCommandType.activateException,
          SecurityComplianceCommandType.renewException,
          SecurityComplianceCommandType.closeException,
        ],
      SecurityExceptionStatus.active ||
      SecurityExceptionStatus.expired =>
        const [
          SecurityComplianceCommandType.renewException,
          SecurityComplianceCommandType.closeException,
        ],
      _ => const [],
    };
  }

  Future<void> _runExceptionAction(
    SecurityException exception,
    SecurityComplianceCommandType command,
    bool operational,
  ) async {
    final strings = SecurityComplianceStrings.of(context);
    final fields = switch (command) {
      SecurityComplianceCommandType.requestExceptionApproval => [
          SecurityDialogField(
            keyName: 'approverUserId',
            label: strings.value('approverUserId'),
          ),
        ],
      SecurityComplianceCommandType.decideExceptionApproval => [
          SecurityDialogField(
            keyName: 'approvalId',
            label: strings.value('approvalId'),
          ),
          SecurityDialogField(
            keyName: 'decision',
            label: strings.value('decision'),
            options: [
              SecurityDialogOption('approved', strings.value('approve')),
              SecurityDialogOption('rejected', strings.value('reject')),
            ],
          ),
          SecurityDialogField(
            keyName: 'comment',
            label: strings.value('comment'),
            multiline: true,
          ),
        ],
      SecurityComplianceCommandType.renewException => [
          SecurityDialogField(
            keyName: 'businessJustification',
            label: strings.value('businessJustification'),
            multiline: true,
          ),
        ],
      SecurityComplianceCommandType.closeException => [
          SecurityDialogField(
            keyName: 'reason',
            label: strings.value('reason'),
            multiline: true,
          ),
        ],
      _ => const <SecurityDialogField>[],
    };
    Map<String, String> values = const {};
    if (fields.isNotEmpty) {
      final result = await showSecurityComplianceActionDialog(
        context,
        title: strings.exceptionCommand(command),
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
          type: SecurityComplianceEntityType.exception,
          id: exception.id,
          scope: operational
              ? SecurityComplianceScope.operational
              : SecurityComplianceScope.selfService,
        ),
      ).future,
    );
    if (!mounted) return;
    final now = DateTime.now().toUtc();
    final renewalStart =
        exception.requestedEndAt.isAfter(now) ? exception.requestedEndAt : now;
    await executeSecurityComplianceCommand(
      ref,
      context,
      type: command,
      payload: {
        'exceptionId': exception.id,
        'expectedRevision': revision,
        if (command ==
            SecurityComplianceCommandType.requestExceptionApproval) ...{
          'approverUserIds': [values['approverUserId']],
        } else if (command ==
            SecurityComplianceCommandType.decideExceptionApproval) ...{
          'approvalId': values['approvalId'],
          'decision': values['decision']?.toLowerCase(),
          'comment': values['comment'],
        } else if (command == SecurityComplianceCommandType.renewException) ...{
          'businessJustification': values['businessJustification'],
          'requestedStartAt': renewalStart.toIso8601String(),
          'requestedEndAt':
              renewalStart.add(const Duration(days: 30)).toIso8601String(),
          'reviewAt':
              renewalStart.add(const Duration(days: 15)).toIso8601String(),
        } else
          ...values,
      },
    );
  }
}
