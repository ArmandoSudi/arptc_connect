import 'dart:async';

import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/application/organization_page_accumulator.dart';
import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_architecture_audit.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_query.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/utils/user_management_command_feedback.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/organization_audit_dialog.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/organization_dialogs.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/organization_load_more_button.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/user_management_access_gate.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/user_management_section_scaffold.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OrganizationsScreen extends ConsumerStatefulWidget {
  const OrganizationsScreen({super.key});

  @override
  ConsumerState<OrganizationsScreen> createState() =>
      _OrganizationsScreenState();
}

class _OrganizationsScreenState extends ConsumerState<OrganizationsScreen> {
  static const _pageSize = 40;

  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _search = '';
  OrganizationListStatusFilter _status = OrganizationListStatusFilter.current;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final query = OrganizationListQuery(
      search: _search,
      status: _status,
      limit: _pageSize,
    );
    final organizations = ref.watch(umFilteredOrganizationsProvider(query));
    final policy = ref.watch(userManagementAccessPolicyProvider);
    return UserManagementAccessGate(
      requirePrivateProfiles: true,
      child: UserManagementSectionScaffold(
        selectedIndex: 0,
        title: l10n.lookup('umOrganizations'),
        subtitle: l10n.lookup('umOrganizationsDescription'),
        primaryAction: FilledButton.icon(
          onPressed: () => _create(context),
          icon: const Icon(Icons.add_business_outlined),
          label: Text(l10n.lookup('umCreateOrganization')),
        ),
        body: Column(
          children: [
            _OrganizationFilters(
              searchController: _searchController,
              status: _status,
              onSearchChanged: _onSearchChanged,
              onStatusChanged: (value) => setState(() => _status = value),
            ),
            Expanded(
              child: organizations.when(
                loading: () =>
                    LoadingStateView(message: l10n.lookup('umLoading')),
                error: (error, _) => ErrorStateView(
                  title: l10n.lookup('umCommandFailed'),
                  description: error.toString(),
                ),
                data: (items) => items.isEmpty
                    ? EmptyStateView(
                        icon: Icons.corporate_fare_outlined,
                        title: l10n.lookup('umNoOrganizations'),
                      )
                    : _PaginatedOrganizationList(
                        key: ValueKey(query),
                        query: query,
                        firstPage: items,
                        canManage: policy.canManageOrganization,
                        canReadAudit: policy.canReadAudit,
                        onOpen: (organization) {
                          ref
                              .read(
                                umSelectedOrganizationIdProvider.notifier,
                              )
                              .state = organization.id;
                          context.go(
                            '/service/usermanagement/organizations/'
                            '${organization.id}',
                          );
                        },
                        onEdit: (organization) => _edit(context, organization),
                        onArchive: (organization) =>
                            _archive(context, organization),
                        onAudit: (organization) =>
                            _audit(context, organization),
                        onAuditHistory: (organization) => context.go(
                          '/service/usermanagement/organizations/'
                          '${organization.id}/audit',
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _search = value);
    });
  }

  Future<void> _create(BuildContext context) async {
    final l10n = S.of(context);
    final result = await showOrganizationFormDialog(
      context,
      onSubmit: (form) async {
        final id = await ref
            .read(umOrganizationCommandControllerProvider.notifier)
            .runOrThrow<String>(
              action: 'createOrganization',
              command: () =>
                  ref.read(userManagementRepositoryProvider).createOrganization(
                        code: form.code,
                        name: form.name,
                        description: form.description,
                      ),
            );
        if (id.trim().isEmpty) {
          throw const OrganizationCommandException(
            code: 'internal',
            message: 'The server returned an invalid organization response.',
          );
        }
      },
      submissionErrorBuilder: (error) =>
          userManagementCommandErrorMessage(l10n, error),
      onSubmissionError: (error, stackTrace) =>
          reportUserManagementCommandError(
        context,
        operation: 'createOrganization',
        error: error,
        stackTrace: stackTrace,
      ),
    );
    if (result == null || !context.mounted) return;
    _message(context, l10n.lookup('umOrganizationCreated'));
  }

  Future<void> _edit(
    BuildContext context,
    Organization organization,
  ) async {
    final l10n = S.of(context);
    final result = await showOrganizationFormDialog(
      context,
      organization: organization,
      onSubmit: (form) => ref
          .read(umOrganizationCommandControllerProvider.notifier)
          .runOrThrow<void>(
            action: 'updateOrganization',
            command: () =>
                ref.read(userManagementRepositoryProvider).updateOrganization(
                      Organization(
                        id: organization.id,
                        code: form.code,
                        name: form.name,
                        description: form.description,
                        status: form.status,
                        schemaVersion: organization.schemaVersion,
                        createdAt: organization.createdAt,
                        createdBy: organization.createdBy,
                        updatedAt: organization.updatedAt,
                        updatedBy: organization.updatedBy,
                      ),
                    ),
          ),
      submissionErrorBuilder: (error) =>
          userManagementCommandErrorMessage(l10n, error),
      onSubmissionError: (error, stackTrace) =>
          reportUserManagementCommandError(
        context,
        operation: 'updateOrganization',
        error: error,
        stackTrace: stackTrace,
      ),
    );
    if (result == null || !context.mounted) return;
    _message(context, l10n.lookup('umOrganizationUpdated'));
  }

  Future<void> _archive(
    BuildContext context,
    Organization organization,
  ) async {
    final l10n = S.of(context);
    final reason = await showOrganizationReasonDialog(
      context,
      title: l10n.lookup('umArchiveOrganization'),
      description: l10n.lookup('umArchiveOrganizationDescription'),
      reasonLabel: l10n.lookup('umArchiveReason'),
      confirmLabel: l10n.archive,
      destructive: true,
    );
    if (reason == null || !context.mounted) return;
    final saved = await ref
        .read(umOrganizationCommandControllerProvider.notifier)
        .runVoid(
          action: 'archiveOrganization',
          command: () =>
              ref.read(userManagementRepositoryProvider).archiveOrganization(
                    organizationId: organization.id,
                    reason: reason,
                  ),
        );
    if (!context.mounted) return;
    saved
        ? _message(context, l10n.lookup('umOrganizationArchived'))
        : _showCommandError(context, ref);
  }

  Future<void> _audit(
    BuildContext context,
    Organization organization,
  ) async {
    final report = await ref
        .read(umOrganizationCommandControllerProvider.notifier)
        .run<OrganizationArchitectureAuditReport>(
          action: 'auditOrganizationArchitecture',
          command: () => ref
              .read(userManagementRepositoryProvider)
              .auditOrganizationArchitecture(
                organizationId: organization.id,
              ),
        );
    if (report == null || !context.mounted) {
      if (context.mounted) _showCommandError(context, ref);
      return;
    }
    final action = await showOrganizationAuditReportDialog(
      context,
      report: report,
    );
    if (action != OrganizationAuditDialogAction.repair || !context.mounted) {
      return;
    }
    final l10n = S.of(context);
    final reason = await showOrganizationReasonDialog(
      context,
      title: l10n.lookup('umRepairProjections'),
      description: l10n.lookup('umRepairProjectionsDescription'),
      reasonLabel: l10n.lookup('umRepairReason'),
      confirmLabel: l10n.lookup('umRepairProjections'),
    );
    if (reason == null || !context.mounted) return;
    final repaired = await ref
        .read(umOrganizationCommandControllerProvider.notifier)
        .run<OrganizationArchitectureAuditReport>(
          action: 'repairOrganizationArchitecture',
          command: () => ref
              .read(userManagementRepositoryProvider)
              .auditOrganizationArchitecture(
                organizationId: organization.id,
                repair: true,
                reason: reason,
              ),
        );
    if (repaired == null || !context.mounted) {
      if (context.mounted) _showCommandError(context, ref);
      return;
    }
    await showOrganizationAuditReportDialog(context, report: repaired);
  }
}

class _OrganizationFilters extends StatelessWidget {
  const _OrganizationFilters({
    required this.searchController,
    required this.status,
    required this.onSearchChanged,
    required this.onStatusChanged,
  });

  final TextEditingController searchController;
  final OrganizationListStatusFilter status;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<OrganizationListStatusFilter> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final search = CommonTextInput(
            label: l10n.lookup('umSearchOrganizations'),
            controller: searchController,
            prefixIcon: const Icon(Icons.search),
            onChanged: onSearchChanged,
          );
          final statusField =
              DropdownButtonFormField<OrganizationListStatusFilter>(
            value: status,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.lookup('umStatusFilter'),
              prefixIcon: const Icon(Icons.filter_alt_outlined),
            ),
            items: OrganizationListStatusFilter.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(
                      _organizationStatusFilterLabel(l10n, value),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) onStatusChanged(value);
            },
          );
          if (constraints.maxWidth < 720) {
            return Column(
              children: [
                search,
                const SizedBox(height: 12),
                statusField,
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 2, child: search),
              const SizedBox(width: 16),
              Expanded(child: statusField),
            ],
          );
        },
      ),
    );
  }
}

class _PaginatedOrganizationList extends ConsumerStatefulWidget {
  const _PaginatedOrganizationList({
    required this.query,
    required this.firstPage,
    required this.canManage,
    required this.canReadAudit,
    required this.onOpen,
    required this.onEdit,
    required this.onArchive,
    required this.onAudit,
    required this.onAuditHistory,
    super.key,
  });

  final OrganizationListQuery query;
  final List<Organization> firstPage;
  final bool canManage;
  final bool canReadAudit;
  final ValueChanged<Organization> onOpen;
  final ValueChanged<Organization> onEdit;
  final ValueChanged<Organization> onArchive;
  final ValueChanged<Organization> onAudit;
  final ValueChanged<Organization> onAuditHistory;

  @override
  ConsumerState<_PaginatedOrganizationList> createState() =>
      _PaginatedOrganizationListState();
}

class _PaginatedOrganizationListState
    extends ConsumerState<_PaginatedOrganizationList> {
  late final OrganizationPageAccumulator<Organization> _pages;
  bool _loadingMore = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _pages = OrganizationPageAccumulator(idOf: (item) => item.id);
  }

  @override
  Widget build(BuildContext context) {
    _pages.seedCursor(
      firstPage: widget.firstPage,
      pageSize: widget.query.limit,
      sortValueOf: (item) => item.nameLower,
    );
    final organizations = _pages.mergeFirstPage(widget.firstPage);
    final footerCount = _pages.hasMore || _loadError != null ? 1 : 0;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
      itemCount: organizations.length + footerCount,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == organizations.length) {
          return OrganizationLoadMoreButton(
            loading: _loadingMore,
            error: _loadError,
            onPressed: _loadMore,
          );
        }
        final organization = organizations[index];
        return ListTile(
          onTap: () => widget.onOpen(organization),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          leading: CircleAvatar(
            child: Text(
              organization.code.characters.take(2).toString(),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          title: Text(
            organization.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            [organization.code, organization.description]
                .where((value) => value.isNotEmpty)
                .join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _OrganizationStatusChip(status: organization.status),
              if (widget.canManage || widget.canReadAudit)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'history') {
                      widget.onAuditHistory(organization);
                    }
                    if (value == 'audit') widget.onAudit(organization);
                    if (value == 'edit') widget.onEdit(organization);
                    if (value == 'archive') widget.onArchive(organization);
                  },
                  itemBuilder: (context) => [
                    if (widget.canReadAudit)
                      PopupMenuItem(
                        value: 'history',
                        child: Text(
                          S.of(context).lookup('umAuditHistory'),
                        ),
                      ),
                    if (widget.canManage)
                      PopupMenuItem(
                        value: 'audit',
                        child: Text(
                          S.of(context).lookup('umArchitectureAudit'),
                        ),
                      ),
                    if (widget.canManage)
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(S.of(context).edit),
                      ),
                    if (widget.canManage)
                      PopupMenuItem(
                        value: 'archive',
                        child: Text(S.of(context).archive),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadMore() async {
    final cursor = _pages.nextCursor;
    if (_loadingMore || cursor == null) return;
    setState(() {
      _loadingMore = true;
      _loadError = null;
    });
    try {
      final page = await ref
          .read(userManagementRepositoryProvider)
          .fetchOrganizationsPage(
            query: widget.query,
            page: OrganizationPageRequest(
              limit: widget.query.limit,
              search: widget.query.search,
              afterNameLower: cursor.nameLower,
              afterId: cursor.id,
            ),
          );
      if (mounted) setState(() => _pages.append(page));
    } catch (error) {
      if (mounted) setState(() => _loadError = error.toString());
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }
}

class _OrganizationStatusChip extends StatelessWidget {
  const _OrganizationStatusChip({required this.status});

  final OrganizationStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final colors = Theme.of(context).colorScheme;
    final active = status == OrganizationStatus.active;
    return Chip(
      avatar: Icon(
        active ? Icons.check_circle_outline : Icons.pause_circle_outline,
        size: 16,
      ),
      label: Text(
        l10n.lookup(
          switch (status) {
            OrganizationStatus.active => 'umActive',
            OrganizationStatus.inactive => 'umInactive',
            OrganizationStatus.archived => 'umArchived',
          },
        ),
      ),
      backgroundColor:
          active ? colors.primaryContainer : colors.surfaceContainerHighest,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

String _organizationStatusFilterLabel(
  S l10n,
  OrganizationListStatusFilter value,
) {
  return l10n.lookup(
    switch (value) {
      OrganizationListStatusFilter.current => 'umCurrentRecords',
      OrganizationListStatusFilter.active => 'umActive',
      OrganizationListStatusFilter.inactive => 'umInactive',
      OrganizationListStatusFilter.archived => 'umArchived',
      OrganizationListStatusFilter.all => 'all',
    },
  );
}

void _showCommandError(BuildContext context, WidgetRef ref) {
  final message =
      ref.read(umOrganizationCommandControllerProvider).errorMessage ??
          S.of(context).lookup('umCommandFailed');
  _message(context, message);
}

void _message(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
