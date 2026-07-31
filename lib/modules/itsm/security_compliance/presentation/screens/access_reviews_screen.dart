import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/pagination.dart';
import '../../../shared/application/itsm_providers.dart';
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

class AccessReviewsScreen extends ConsumerStatefulWidget {
  const AccessReviewsScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  ConsumerState<AccessReviewsScreen> createState() =>
      _AccessReviewsScreenState();
}

class _AccessReviewsScreenState extends ConsumerState<AccessReviewsScreen> {
  static const _pageSize = PageRequest.defaultLimit;
  bool _showCampaigns = true;

  @override
  Widget build(BuildContext context) {
    final strings = SecurityComplianceStrings.of(context);
    final access = ref.watch(securityComplianceAccessProvider);
    return SecurityComplianceShell(
      title: strings.value('accessReviewsTitle'),
      subtitle: strings.value('accessReviewsSubtitle'),
      onBack: widget.onBack,
      actions: [
        FilledButton.tonalIcon(
          onPressed: access.valueOrNull?.canOperate == true
              ? () => _completeRevocationTask(strings)
              : null,
          icon: const Icon(Icons.task_alt_rounded),
          label: Text(strings.value('completeRevocationTask')),
        ),
        FilledButton.icon(
          onPressed: access.valueOrNull?.canOperate == true
              ? () => _createCampaign(strings)
              : null,
          icon: const Icon(Icons.add_rounded),
          label: Text(strings.value('newCampaign')),
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
          return value.canOperate
              ? _buildOperational(strings)
              : _buildSelfService(strings);
        },
      ),
    );
  }

  Widget _buildOperational(SecurityComplianceStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(strings.value('campaigns')),
              selected: _showCampaigns,
              onSelected: (_) => setState(() => _showCampaigns = true),
            ),
            ChoiceChip(
              label: Text(strings.value('reviewItems')),
              selected: !_showCampaigns,
              onSelected: (_) => setState(() => _showCampaigns = false),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_showCampaigns) _campaigns() else _items(operational: true),
      ],
    );
  }

  Widget _buildSelfService(SecurityComplianceStrings strings) {
    final corrections = ref.watch(
      accessCorrectionRequestsProvider(_pageSize),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ref
                .watch(securityComplianceAccessProvider)
                .valueOrNull
                ?.canUseSelfService ==
            true)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(strings.value('selfServiceOnlyNotice')),
          ),
        _items(operational: false),
        const SizedBox(height: 24),
        Text(
          strings.value('correctionRequests'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        corrections.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => Text(strings.value('unableToLoad')),
          data: (items) => items.isEmpty
              ? Text(strings.value('noDataDescription'))
              : Column(
                  children: [
                    for (final item in items)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(strings.correctionType(item.type)),
                        subtitle: Text(item.reason),
                        trailing: Text(strings.correctionStatus(item.status)),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _campaigns() {
    final strings = SecurityComplianceStrings.of(context);
    const query = SecurityComplianceQuery(
      scope: SecurityComplianceScope.operational,
    );
    const request = SecurityComplianceFirstPageRequest(
      query: query,
      limit: _pageSize,
    );
    final firstPage = ref.watch(
      accessReviewCampaignsFirstPageProvider(request),
    );
    return SecurityCompliancePagedList<AccessReviewCampaign>(
      firstPage: firstPage,
      onRetry: () => ref.invalidate(
        accessReviewCampaignsFirstPageProvider(request),
      ),
      cursorOf: (campaign) => PageCursor({
        'sortAt': campaign.updatedAt,
        'id': campaign.id,
      }),
      loadPage: (cursor) => ref.read(
        accessReviewCampaignsPageProvider(
          SecurityCompliancePageRequest(
            query: query,
            page: PageRequest(limit: _pageSize, cursor: cursor),
          ),
        ).future,
      ),
      itemBuilder: (_, campaign) => AccessReviewCampaignCard(
        campaign: campaign,
        action: PopupMenuButton<SecurityComplianceCommandType>(
          onSelected: (command) => _runCampaignAction(campaign, command),
          itemBuilder: (_) => [
            if (campaign.status == AccessReviewCampaignStatus.draft)
              PopupMenuItem(
                value: SecurityComplianceCommandType.activateReviewCampaign,
                child: Text(strings.value('activateCampaign')),
              ),
            if (campaign.status == AccessReviewCampaignStatus.draft ||
                campaign.status == AccessReviewCampaignStatus.active)
              PopupMenuItem(
                value: SecurityComplianceCommandType.createReviewItem,
                child: Text(strings.value('createReviewItem')),
              ),
            if (campaign.status == AccessReviewCampaignStatus.active)
              PopupMenuItem(
                value: SecurityComplianceCommandType.completeReviewCampaign,
                child: Text(strings.value('completeCampaign')),
              ),
          ],
        ),
      ),
    );
  }

  Widget _items({required bool operational}) {
    final query = SecurityComplianceQuery(
      scope: operational
          ? SecurityComplianceScope.operational
          : SecurityComplianceScope.selfService,
    );
    final request = SecurityComplianceFirstPageRequest(
      query: query,
      limit: _pageSize,
    );
    final firstPage = ref.watch(accessReviewItemsFirstPageProvider(request));
    return SecurityCompliancePagedList<AccessReviewItem>(
      firstPage: firstPage,
      onRetry: () => ref.invalidate(
        accessReviewItemsFirstPageProvider(request),
      ),
      cursorOf: (item) => PageCursor({
        'sortAt': item.updatedAt,
        'id': item.id,
      }),
      loadPage: (cursor) => ref.read(
        accessReviewItemsPageProvider(
          SecurityCompliancePageRequest(
            query: query,
            page: PageRequest(limit: _pageSize, cursor: cursor),
          ),
        ).future,
      ),
      itemBuilder: (_, item) => AccessReviewItemCard(
        item: item,
        action: item.decision != AccessReviewDecision.pending
            ? null
            : PopupMenuButton<AccessReviewDecision>(
                onSelected: (decision) => operational
                    ? _decideItem(item, decision)
                    : _requestCorrection(item, decision),
                itemBuilder: (_) => [
                  if (operational)
                    PopupMenuItem(
                      value: AccessReviewDecision.retain,
                      child: Text(
                        SecurityComplianceStrings.of(context).value('retain'),
                      ),
                    ),
                  PopupMenuItem(
                    value: AccessReviewDecision.revoke,
                    child: Text(
                      SecurityComplianceStrings.of(context).value('revoke'),
                    ),
                  ),
                  PopupMenuItem(
                    value: AccessReviewDecision.modify,
                    child: Text(
                      SecurityComplianceStrings.of(context).value('modify'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _runCampaignAction(
    AccessReviewCampaign campaign,
    SecurityComplianceCommandType command,
  ) async {
    final strings = SecurityComplianceStrings.of(context);
    Map<String, String> values = const {};
    if (command == SecurityComplianceCommandType.createReviewItem) {
      final result = await showSecurityComplianceActionDialog(
        context,
        title: strings.value('createReviewItem'),
        submitLabel: strings.value('save'),
        cancelLabel: strings.value('cancel'),
        requiredFieldLabel: strings.value('requiredField'),
        fields: [
          SecurityDialogField(
            keyName: 'subjectUserId',
            label: strings.value('subjectUserId'),
          ),
          SecurityDialogField(
            keyName: 'currentAccess',
            label: strings.value('currentAccess'),
            multiline: true,
          ),
          SecurityDialogField(
            keyName: 'currentRole',
            label: strings.value('currentRole'),
          ),
          SecurityDialogField(
            keyName: 'departmentId',
            label: strings.value('departmentId'),
          ),
          SecurityDialogField(
            keyName: 'departmentName',
            label: strings.value('department'),
          ),
          SecurityDialogField(
            keyName: 'reviewerUserId',
            label: strings.value('reviewerUserId'),
          ),
        ],
      );
      if (result == null || !mounted) return;
      values = result;
    }
    final revision = command == SecurityComplianceCommandType.createReviewItem
        ? null
        : await ref.read(
            securityComplianceRevisionProvider(
              SecurityComplianceIdentity(
                type: SecurityComplianceEntityType.campaign,
                id: campaign.id,
                scope: SecurityComplianceScope.operational,
              ),
            ).future,
          );
    if (!mounted) return;
    await executeSecurityComplianceCommand(
      ref,
      context,
      type: command,
      payload: command == SecurityComplianceCommandType.createReviewItem
          ? {
              'campaignId': campaign.id,
              ...values,
              'dueAt': campaign.dueAt.toIso8601String(),
            }
          : {
              'campaignId': campaign.id,
              'expectedRevision': revision,
            },
    );
  }

  Future<void> _createCampaign(SecurityComplianceStrings strings) async {
    final values = await showSecurityComplianceActionDialog(
      context,
      title: strings.value('newCampaign'),
      submitLabel: strings.value('save'),
      cancelLabel: strings.value('cancel'),
      requiredFieldLabel: strings.value('requiredField'),
      fields: [
        SecurityDialogField(
          keyName: 'title',
          label: strings.value('campaignTitle'),
        ),
        SecurityDialogField(
          keyName: 'scope',
          label: strings.value('scope'),
        ),
        SecurityDialogField(
          keyName: 'systemId',
          label: strings.value('systemId'),
        ),
        SecurityDialogField(
          keyName: 'systemName',
          label: strings.value('systemName'),
        ),
      ],
    );
    if (values == null || !mounted) return;
    final session = await ref.read(itsmSessionProvider.future);
    if (session == null || !mounted) return;
    final now = DateTime.now().toUtc();
    await executeSecurityComplianceCommand(
      ref,
      context,
      type: SecurityComplianceCommandType.createReviewCampaign,
      payload: {
        ...values,
        'ownerUserId': session.userId,
        'startsAt': now.toIso8601String(),
        'dueAt': now.add(const Duration(days: 30)).toIso8601String(),
        'allowSelfServiceCorrection': true,
        'reviewerUserIds': [session.userId],
        'departmentIds': const <String>[],
      },
    );
  }

  Future<void> _decideItem(
    AccessReviewItem item,
    AccessReviewDecision decision,
  ) async {
    final strings = SecurityComplianceStrings.of(context);
    final values = await showSecurityComplianceActionDialog(
      context,
      title: strings.value('decide'),
      submitLabel: strings.value('save'),
      cancelLabel: strings.value('cancel'),
      requiredFieldLabel: strings.value('requiredField'),
      fields: [
        SecurityDialogField(
          keyName: 'justification',
          label: strings.value('reason'),
          multiline: true,
        ),
        if (decision == AccessReviewDecision.revoke ||
            decision == AccessReviewDecision.modify)
          SecurityDialogField(
            keyName: 'assignedToUserId',
            label: strings.value('assignedToUserId'),
          ),
        if (decision == AccessReviewDecision.modify)
          SecurityDialogField(
            keyName: 'targetAccess',
            label: strings.value('targetAccess'),
            multiline: true,
          ),
      ],
    );
    if (values == null || !mounted) return;
    final revision = await ref.read(
      securityComplianceRevisionProvider(
        SecurityComplianceIdentity(
          type: SecurityComplianceEntityType.reviewItem,
          id: item.id,
          scope: SecurityComplianceScope.operational,
        ),
      ).future,
    );
    if (!mounted) return;
    await executeSecurityComplianceCommand(
      ref,
      context,
      type: SecurityComplianceCommandType.decideReviewItem,
      payload: {
        'itemId': item.id,
        'expectedRevision': revision,
        'decision': decision.name,
        if (decision == AccessReviewDecision.revoke ||
            decision == AccessReviewDecision.modify)
          'taskDueAt': DateTime.now()
              .toUtc()
              .add(const Duration(days: 7))
              .toIso8601String(),
        ...values,
      },
    );
  }

  Future<void> _completeRevocationTask(
    SecurityComplianceStrings strings,
  ) async {
    final values = await showSecurityComplianceActionDialog(
      context,
      title: strings.value('completeRevocationTask'),
      submitLabel: strings.value('save'),
      cancelLabel: strings.value('cancel'),
      requiredFieldLabel: strings.value('requiredField'),
      fields: [
        SecurityDialogField(
          keyName: 'taskId',
          label: strings.value('taskId'),
        ),
        SecurityDialogField(
          keyName: 'completionEvidenceId',
          label: strings.value('completionEvidenceId'),
        ),
        SecurityDialogField(
          keyName: 'comment',
          label: strings.value('comment'),
          multiline: true,
        ),
      ],
    );
    if (values == null || !mounted) return;
    await executeSecurityComplianceCommand(
      ref,
      context,
      type: SecurityComplianceCommandType.completeRevocationTask,
      payload: {
        ...values,
        'expectedRevision': 0,
      },
    );
  }

  Future<void> _requestCorrection(
    AccessReviewItem item,
    AccessReviewDecision decision,
  ) async {
    final strings = SecurityComplianceStrings.of(context);
    final type = decision == AccessReviewDecision.revoke
        ? AccessCorrectionRequestType.revocation
        : AccessCorrectionRequestType.correction;
    final values = await showSecurityComplianceActionDialog(
      context,
      title: strings.correctionType(type),
      submitLabel: strings.value('submit'),
      cancelLabel: strings.value('cancel'),
      requiredFieldLabel: strings.value('requiredField'),
      fields: [
        SecurityDialogField(
          keyName: 'reason',
          label: strings.value('reason'),
          multiline: true,
        ),
      ],
    );
    if (values == null || !mounted) return;
    await executeSecurityComplianceCommand(
      ref,
      context,
      type: SecurityComplianceCommandType.requestAccessCorrection,
      payload: {
        'itemId': item.id,
        'type': type.name,
        ...values,
      },
    );
  }
}
