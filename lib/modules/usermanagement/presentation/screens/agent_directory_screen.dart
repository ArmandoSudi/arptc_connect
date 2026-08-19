import 'dart:async';

import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/application/organization_page_accumulator.dart';
import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/domain/agent_directory_entry.dart';
import 'package:arptc_connect/modules/usermanagement/domain/modules.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_query.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_unit.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_agent.dart';
import 'package:arptc_connect/modules/usermanagement/domain/unplaced_agent_summary.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/utils/user_management_command_feedback.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/organization_agent_dialogs.dart';
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

class AgentDirectoryScreen extends ConsumerStatefulWidget {
  const AgentDirectoryScreen({super.key});

  @override
  ConsumerState<AgentDirectoryScreen> createState() =>
      _AgentDirectoryScreenState();
}

class _AgentDirectoryScreenState extends ConsumerState<AgentDirectoryScreen> {
  static const _pageSize = 40;
  final _search = TextEditingController();
  Timer? _debounce;
  String _searchValue = '';
  String _scopeUnitId = '';
  AgentDirectoryStatusFilter _status = AgentDirectoryStatusFilter.active;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final organizations = ref.watch(umOrganizationsProvider);
    final unplacedAgents = ref.watch(umUnplacedAgentsProvider);
    return UserManagementAccessGate(
      child: UserManagementSectionScaffold(
        selectedIndex: 2,
        title: l10n.lookup('umAgents'),
        subtitle: l10n.lookup('umAgentsDescription'),
        primaryAction: FilledButton.icon(
          onPressed: organizations.maybeWhen(
            data: (items) => items.isEmpty
                ? null
                : () => _createAgent(
                      context,
                      _resolvedOrganizationId(items),
                    ),
            orElse: () => null,
          ),
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: Text(l10n.lookup('umCreateAgent')),
        ),
        body: organizations.when(
          loading: () => LoadingStateView(message: l10n.lookup('umLoading')),
          error: (error, _) => ErrorStateView(
            title: l10n.lookup('umCommandFailed'),
            description: error.toString(),
          ),
          data: (items) {
            if (items.isEmpty) {
              return EmptyStateView(
                icon: Icons.corporate_fare_outlined,
                title: l10n.lookup('umNoOrganizations'),
              );
            }
            final organizationId = _resolvedOrganizationId(items);
            final canReadPrivateProfiles = ref
                .watch(userManagementAccessPolicyProvider)
                .canReadPrivateProfiles;
            final units = ref
                    .watch(umOrganizationUnitsProvider(organizationId))
                    .valueOrNull ??
                const <OrganizationUnit>[];
            final scopeUnitId = units.any((unit) => unit.id == _scopeUnitId)
                ? _scopeUnitId
                : '';
            final status = canReadPrivateProfiles
                ? _status
                : AgentDirectoryStatusFilter.active;
            return Column(
              children: [
                _AgentDirectoryFilters(
                  organizations: items,
                  organizationId: organizationId,
                  units: units,
                  scopeUnitId: scopeUnitId,
                  status: status,
                  canFilterInactive: canReadPrivateProfiles,
                  searchController: _search,
                  onOrganizationChanged: (value) {
                    ref.read(umSelectedOrganizationIdProvider.notifier).state =
                        value;
                    setState(() => _scopeUnitId = '');
                  },
                  onUnitChanged: (value) =>
                      setState(() => _scopeUnitId = value),
                  onStatusChanged: (value) => setState(() => _status = value),
                  onSearchChanged: _onSearchChanged,
                ),
                unplacedAgents.maybeWhen(
                  data: (page) => page.items.isEmpty && !page.hasMore
                      ? const SizedBox.shrink()
                      : _UnplacedAgentsBanner(
                          organizationId: organizationId,
                          firstPage: page,
                          onAssign: (agents) => _assignExistingAgent(
                            context,
                            organizationId,
                            agents,
                          ),
                          onMigrate: (agents) => _migrateLegacyAgent(
                            context,
                            agents,
                          ),
                        ),
                  orElse: () => const SizedBox.shrink(),
                ),
                Expanded(
                  child: _DirectoryList(
                    key: ValueKey((
                      organizationId,
                      _searchValue,
                      scopeUnitId,
                      status,
                    )),
                    organizationId: organizationId,
                    search: _searchValue,
                    scopeUnitId: scopeUnitId,
                    status: status,
                    pageSize: _pageSize,
                    canOpenDetails: canReadPrivateProfiles,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _resolvedOrganizationId(List<Organization> organizations) {
    final selected = ref.watch(umEffectiveOrganizationIdProvider);
    return organizations.any((item) => item.id == selected)
        ? selected
        : organizations.first.id;
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _searchValue = value);
    });
  }

  Future<void> _createAgent(
    BuildContext context,
    String organizationId,
  ) async {
    final units = await ref
        .read(umCompleteOrganizationHierarchyProvider(organizationId).future);
    if (!context.mounted) return;
    if (units.isEmpty) {
      _message(context, S.of(context).lookup('umNoUnits'));
      return;
    }
    final l10n = S.of(context);
    String? createdUid;
    final result = await showCreateOrganizationAgentDialog(
      context,
      units: units,
      onSubmit: (form) async {
        final unit = units.firstWhere((item) => item.id == form.unitId);
        final agent = UserManagementAgent(
          id: '',
          firstName: form.firstName,
          name: form.name,
          postName: form.postName,
          matricule: form.matricule,
          sex: form.sex,
          email: form.email,
          emailLower: form.email.toLowerCase(),
          jobTitle: form.jobTitle,
          department: '',
          departmentId: '',
          service: '',
          serviceId: '',
          bureau: '',
          bureauId: '',
          organizationId: organizationId,
          primaryOrganizationUnitId: unit.id,
          primaryOrganizationUnitName: unit.name,
          primaryOrganizationUnitType: unit.type.value,
          organizationAncestorUnitIds: unit.ancestorUnitIds,
          organizationPathUnitIds: unit.pathUnitIds,
          organizationPathNames: unit.pathNames,
          scopeKeys: unit.scopeKeys,
          isActive: true,
          modulePermissions: Modules.defaultUserPermissions(),
        );
        final uid = await ref
            .read(umOrganizationCommandControllerProvider.notifier)
            .runOrThrow<String>(
              action: 'createAgentAccount',
              command: () =>
                  ref.read(userManagementRepositoryProvider).createAgentAccount(
                        agent,
                        assignmentStartsAt: form.startsAt,
                        assignmentReason: form.reason,
                        assignAsHead: form.assignAsHead,
                      ),
            );
        if (uid.trim().isEmpty) {
          throw const AgentProvisioningException(
            code: 'internal',
            message: 'The server returned an invalid agent response.',
          );
        }
        createdUid = uid;
      },
      submissionErrorBuilder: (error) =>
          userManagementCommandErrorMessage(l10n, error),
      onSubmissionError: (error, stackTrace) =>
          reportUserManagementCommandError(
        context,
        operation: 'createAgentAccount',
        error: error,
        stackTrace: stackTrace,
      ),
    );
    if (result == null || !context.mounted) return;
    final uid = createdUid;
    if (uid == null || uid.isEmpty) return;
    _message(context, l10n.lookup('umAgentCreated'));
    context.go('/service/usermanagement/agents/$uid');
  }

  Future<void> _assignExistingAgent(
    BuildContext context,
    String organizationId,
    List<UnplacedAgentSummary> agents,
  ) async {
    final units = await ref
        .read(umCompleteOrganizationHierarchyProvider(organizationId).future);
    if (!context.mounted) return;
    if (units.isEmpty) {
      _message(context, S.of(context).lookup('umNoUnits'));
      return;
    }
    final result = await showAssignExistingOrganizationAgentDialog(
      context,
      agents: agents,
      units: units,
    );
    if (result == null || !context.mounted) return;
    final success = await ref
        .read(umOrganizationCommandControllerProvider.notifier)
        .runVoid(
          action: 'assignAgentOrganization',
          command: () => ref
              .read(userManagementRepositoryProvider)
              .assignAgentOrganization(
                agentId: result.agentId,
                organizationId: organizationId,
                unitId: result.unitId,
                startsAt: result.startsAt,
                reason: result.reason,
                transfer: false,
              ),
        );
    if (!context.mounted) return;
    final error =
        ref.read(umOrganizationCommandControllerProvider).errorMessage;
    _message(
      context,
      error ??
          (success
              ? S.of(context).lookup('umExistingAgentAssigned')
              : S.of(context).lookup('umCommandFailed')),
    );
    if (success) ref.invalidate(umUnplacedAgentsProvider);
  }

  Future<void> _migrateLegacyAgent(
    BuildContext context,
    List<UnplacedAgentSummary> agents,
  ) async {
    final selected = await showMigrateLegacyAgentDialog(
      context,
      agents: agents,
    );
    if (selected == null || !context.mounted) return;
    final result = await ref
        .read(umOrganizationCommandControllerProvider.notifier)
        .run<AgentAccountMigrationResult>(
          action: 'migrateLegacyAgentAccount',
          command: () => ref
              .read(userManagementRepositoryProvider)
              .migrateLegacyAgentAccount(selected.id),
        );
    if (!context.mounted) return;
    final error =
        ref.read(umOrganizationCommandControllerProvider).errorMessage;
    _message(
      context,
      error ??
          (result?.requiresOrganizationAssignment == true
              ? S.of(context).lookup('umLegacyAgentMigrated')
              : S.of(context).lookup('umCommandFailed')),
    );
    if (result != null) ref.invalidate(umUnplacedAgentsProvider);
  }
}

class _UnplacedAgentsBanner extends ConsumerStatefulWidget {
  const _UnplacedAgentsBanner({
    required this.organizationId,
    required this.firstPage,
    required this.onAssign,
    required this.onMigrate,
  });

  final String organizationId;
  final UnplacedAgentPage firstPage;
  final Future<void> Function(List<UnplacedAgentSummary> agents) onAssign;
  final Future<void> Function(List<UnplacedAgentSummary> agents) onMigrate;

  @override
  ConsumerState<_UnplacedAgentsBanner> createState() =>
      _UnplacedAgentsBannerState();
}

class _UnplacedAgentsBannerState extends ConsumerState<_UnplacedAgentsBanner> {
  final _additional = <UnplacedAgentSummary>[];
  String? _nextCursor;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nextCursor = widget.firstPage.nextCursor;
  }

  @override
  void didUpdateWidget(covariant _UnplacedAgentsBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organizationId != widget.organizationId ||
        oldWidget.firstPage.nextCursor != widget.firstPage.nextCursor) {
      _additional.clear();
      _nextCursor = widget.firstPage.nextCursor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final agents = <String, UnplacedAgentSummary>{
      for (final agent in widget.firstPage.items) agent.id: agent,
      for (final agent in _additional) agent.id: agent,
    }.values.toList(growable: false);
    final canonicalAgents = agents
        .where((agent) => agent.hasCanonicalIdentity)
        .toList(growable: false);
    final legacyAgents = agents
        .where((agent) => !agent.hasCanonicalIdentity)
        .toList(growable: false);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Card(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        child: ListTile(
          leading: const Icon(Icons.person_pin_outlined),
          title: Text(
            '${l10n.lookup('umAssignExistingAgent')} '
            '(${agents.length}${_nextCursor == null ? '' : '+'})',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(l10n.lookup('umUnplacedAgentsAvailable')),
          trailing: Wrap(
            spacing: 8,
            children: [
              if (_nextCursor != null)
                TextButton(
                  onPressed: _loading ? null : _loadMore,
                  child: _loading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.lookup('umLoadMore')),
                ),
              if (legacyAgents.isNotEmpty)
                IconButton.filledTonal(
                  onPressed: () => widget.onMigrate(legacyAgents),
                  tooltip: l10n.lookup('umMigrateLegacyAgent'),
                  icon: const Icon(Icons.manage_accounts_outlined),
                ),
              IconButton.filledTonal(
                onPressed: canonicalAgents.isEmpty
                    ? null
                    : () => widget.onAssign(canonicalAgents),
                tooltip: l10n.lookup('umAssignExistingAgent'),
                icon: const Icon(Icons.person_add_alt),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (_loading || cursor == null) return;
    setState(() => _loading = true);
    try {
      final page = await ref
          .read(userManagementRepositoryProvider)
          .fetchUnplacedAgentsPage(afterId: cursor);
      if (!mounted) return;
      setState(() {
        _additional.addAll(page.items);
        _nextCursor = page.nextCursor;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _AgentDirectoryFilters extends StatelessWidget {
  const _AgentDirectoryFilters({
    required this.organizations,
    required this.organizationId,
    required this.units,
    required this.scopeUnitId,
    required this.status,
    required this.canFilterInactive,
    required this.searchController,
    required this.onOrganizationChanged,
    required this.onUnitChanged,
    required this.onStatusChanged,
    required this.onSearchChanged,
  });

  final List<Organization> organizations;
  final String organizationId;
  final List<OrganizationUnit> units;
  final String scopeUnitId;
  final AgentDirectoryStatusFilter status;
  final bool canFilterInactive;
  final TextEditingController searchController;
  final ValueChanged<String> onOrganizationChanged;
  final ValueChanged<String> onUnitChanged;
  final ValueChanged<AgentDirectoryStatusFilter> onStatusChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final fields = <Widget>[
      DropdownButtonFormField<String>(
        value: organizationId,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: l10n.lookup('umSelectOrganization'),
          prefixIcon: const Icon(Icons.corporate_fare_outlined),
        ),
        items: organizations
            .map(
              (organization) => DropdownMenuItem(
                value: organization.id,
                child: Text(
                  organization.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(growable: false),
        onChanged: (value) {
          if (value != null) onOrganizationChanged(value);
        },
      ),
      DropdownButtonFormField<String>(
        value: scopeUnitId,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: l10n.lookup('umOrganizationUnit'),
          prefixIcon: const Icon(Icons.account_tree_outlined),
        ),
        items: [
          DropdownMenuItem(
            value: '',
            child: Text(l10n.lookup('umAllUnits')),
          ),
          ...units.map(
            (unit) => DropdownMenuItem(
              value: unit.id,
              child: Text(
                unit.breadcrumb,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        onChanged: (value) => onUnitChanged(value ?? ''),
      ),
      CommonTextInput(
        label: l10n.lookup('umSearchAgents'),
        controller: searchController,
        prefixIcon: const Icon(Icons.search),
        onChanged: onSearchChanged,
      ),
      if (canFilterInactive)
        DropdownButtonFormField<AgentDirectoryStatusFilter>(
          value: status,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.lookup('umStatusFilter'),
            prefixIcon: const Icon(Icons.filter_alt_outlined),
          ),
          items: AgentDirectoryStatusFilter.values
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(
                    _agentStatusLabel(l10n, value),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) onStatusChanged(value);
          },
        ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return Column(
              children: [
                for (var index = 0; index < fields.length; index++) ...[
                  fields[index],
                  if (index != fields.length - 1) const SizedBox(height: 12),
                ],
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var index = 0; index < fields.length; index++) ...[
                Expanded(child: fields[index]),
                if (index != fields.length - 1) const SizedBox(width: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DirectoryList extends ConsumerStatefulWidget {
  const _DirectoryList({
    required this.organizationId,
    required this.search,
    required this.scopeUnitId,
    required this.status,
    required this.pageSize,
    required this.canOpenDetails,
    super.key,
  });

  final String organizationId;
  final String search;
  final String scopeUnitId;
  final AgentDirectoryStatusFilter status;
  final int pageSize;
  final bool canOpenDetails;

  @override
  ConsumerState<_DirectoryList> createState() => _DirectoryListState();
}

class _DirectoryListState extends ConsumerState<_DirectoryList> {
  late final OrganizationPageAccumulator<AgentDirectoryEntry> _pages;
  bool _loadingMore = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _pages = OrganizationPageAccumulator(idOf: (item) => item.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final query = AgentDirectoryListQuery(
      organizationId: widget.organizationId,
      search: widget.search,
      scopeUnitId: widget.scopeUnitId,
      status: widget.status,
      limit: widget.pageSize,
    );
    final directory = ref.watch(umFilteredAgentDirectoryProvider(query));
    return directory.when(
      loading: () => LoadingStateView(message: l10n.lookup('umLoading')),
      error: (error, _) => ErrorStateView(
        title: l10n.lookup('umCommandFailed'),
        description: error.toString(),
      ),
      data: (firstPage) {
        if (firstPage.isEmpty && !_pages.hasMore) {
          return EmptyStateView(
            icon: Icons.person_search_outlined,
            title: l10n.lookup('umNoAgents'),
          );
        }
        _pages.seedCursor(
          firstPage: firstPage,
          pageSize: widget.pageSize,
          sortValueOf: (item) => item.displayNameLower,
        );
        final agents = _pages.mergeFirstPage(firstPage);
        if (agents.isEmpty) {
          return EmptyStateView(
            icon: Icons.person_search_outlined,
            title: l10n.lookup('umNoAgents'),
          );
        }
        final footerCount = _pages.hasMore || _loadError != null ? 1 : 0;
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
          itemCount: agents.length + footerCount,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index == agents.length) {
              return OrganizationLoadMoreButton(
                loading: _loadingMore,
                error: _loadError,
                onPressed: () => _loadMore(query),
              );
            }
            final agent = agents[index];
            return _AgentDirectoryTile(
              agent: agent,
              onTap: widget.canOpenDetails
                  ? () => context.go(
                        '/service/usermanagement/agents/${agent.id}',
                      )
                  : null,
            );
          },
        );
      },
    );
  }

  Future<void> _loadMore(AgentDirectoryListQuery query) async {
    final cursor = _pages.nextCursor;
    if (_loadingMore || cursor == null) return;
    setState(() {
      _loadingMore = true;
      _loadError = null;
    });
    try {
      final page = await ref
          .read(userManagementRepositoryProvider)
          .fetchAgentDirectoryPage(
            query: query,
            page: OrganizationPageRequest(
              limit: widget.pageSize,
              search: widget.search,
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

class _AgentDirectoryTile extends StatelessWidget {
  const _AgentDirectoryTile({required this.agent, required this.onTap});

  final AgentDirectoryEntry agent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = agent.profilePictureUrl?.isNotEmpty == true;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(
          backgroundImage:
              hasImage ? NetworkImage(agent.profilePictureUrl!) : null,
          child: hasImage ? null : Text(_initials(agent.displayName)),
        ),
        title: Text(
          agent.displayName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [agent.jobTitle, agent.organizationBreadcrumb]
              .where((value) => value.isNotEmpty)
              .join('\n'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      ),
    );
  }
}

String _initials(String name) => name
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part[0].toUpperCase())
    .join();

String _agentStatusLabel(S l10n, AgentDirectoryStatusFilter value) =>
    l10n.lookup(
      switch (value) {
        AgentDirectoryStatusFilter.active => 'umActive',
        AgentDirectoryStatusFilter.inactive => 'umInactive',
        AgentDirectoryStatusFilter.all => 'all',
      },
    );

void _message(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
