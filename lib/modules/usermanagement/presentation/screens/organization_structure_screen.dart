import 'dart:async';

import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/application/organization_page_accumulator.dart';
import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_query.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_unit.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/utils/organization_leadership_action.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/utils/user_management_command_feedback.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/organization_dialogs.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/organization_load_more_button.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/organization_unit_dialogs.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/user_management_access_gate.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/user_management_section_scaffold.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OrganizationStructureScreen extends ConsumerStatefulWidget {
  const OrganizationStructureScreen({super.key});

  @override
  ConsumerState<OrganizationStructureScreen> createState() =>
      _OrganizationStructureScreenState();
}

class _OrganizationStructureScreenState
    extends ConsumerState<OrganizationStructureScreen> {
  static const _pageSize = OrganizationPageRequest.maximumLimit;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _search = '';
  OrganizationUnitType? _type;
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
    final organizations = ref.watch(umOrganizationsProvider);
    return UserManagementAccessGate(
      requirePrivateProfiles: true,
      child: UserManagementSectionScaffold(
        selectedIndex: 1,
        title: l10n.lookup('umStructure'),
        subtitle: l10n.lookup('umStructureDescription'),
        primaryAction: organizations.maybeWhen(
          data: (items) => items.isEmpty
              ? null
              : FilledButton.icon(
                  onPressed: () => _createRoot(
                    context,
                    ref,
                    _resolvedOrganizationId(ref, items),
                  ),
                  icon: const Icon(Icons.add_outlined),
                  label: Text(l10n.lookup('umCreateRootDepartment')),
                ),
          orElse: () => null,
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
            final organizationId = _resolvedOrganizationId(ref, items);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                  child: DropdownButtonFormField<String>(
                    value: organizationId,
                    decoration: InputDecoration(
                      labelText: l10n.lookup('umSelectOrganization'),
                      prefixIcon: const Icon(Icons.corporate_fare_outlined),
                    ),
                    items: items
                        .map((organization) => DropdownMenuItem(
                              value: organization.id,
                              child: Text(organization.name),
                            ))
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(umSelectedOrganizationIdProvider.notifier)
                            .state = value;
                      }
                    },
                  ),
                ),
                _StructureFilters(
                  searchController: _searchController,
                  type: _type,
                  status: _status,
                  onSearchChanged: _onSearchChanged,
                  onTypeChanged: (value) => setState(() => _type = value),
                  onStatusChanged: (value) => setState(() => _status = value),
                ),
                Expanded(
                  child: _OrganizationUnitList(
                    key: ValueKey((organizationId, _search, _type, _status)),
                    organizationId: organizationId,
                    search: _search,
                    type: _type,
                    status: _status,
                    pageSize: _pageSize,
                    canManage: ref
                        .watch(userManagementAccessPolicyProvider)
                        .canManageOrganization,
                  ),
                ),
              ],
            );
          },
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

  String _resolvedOrganizationId(
    WidgetRef ref,
    List<Organization> organizations,
  ) {
    final selected = ref.watch(umEffectiveOrganizationIdProvider);
    return organizations.any((item) => item.id == selected)
        ? selected
        : organizations.first.id;
  }

  Future<void> _createRoot(
    BuildContext context,
    WidgetRef ref,
    String organizationId,
  ) {
    return _createUnit(
      context,
      ref,
      organizationId: organizationId,
      type: OrganizationUnitType.department,
      parentUnitId: null,
    );
  }
}

class _StructureFilters extends StatelessWidget {
  const _StructureFilters({
    required this.searchController,
    required this.type,
    required this.status,
    required this.onSearchChanged,
    required this.onTypeChanged,
    required this.onStatusChanged,
  });

  final TextEditingController searchController;
  final OrganizationUnitType? type;
  final OrganizationListStatusFilter status;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<OrganizationUnitType?> onTypeChanged;
  final ValueChanged<OrganizationListStatusFilter> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final fields = <Widget>[
      CommonTextInput(
        label: l10n.lookup('umSearchUnits'),
        controller: searchController,
        prefixIcon: const Icon(Icons.search),
        onChanged: onSearchChanged,
      ),
      DropdownButtonFormField<OrganizationUnitType?>(
        value: type,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: l10n.lookup('umUnitType'),
          prefixIcon: const Icon(Icons.account_tree_outlined),
        ),
        items: [
          DropdownMenuItem<OrganizationUnitType?>(
            value: null,
            child: Text(l10n.lookup('all')),
          ),
          ...OrganizationUnitType.values
              .where((value) => value != OrganizationUnitType.custom)
              .map(
                (value) => DropdownMenuItem<OrganizationUnitType?>(
                  value: value,
                  child: Text(
                    _unitTypeLabel(l10n, value),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
        ],
        onChanged: onTypeChanged,
      ),
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
                  _statusFilterLabel(l10n, value),
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
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 850) {
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
            children: [
              Expanded(flex: 2, child: fields[0]),
              const SizedBox(width: 12),
              Expanded(child: fields[1]),
              const SizedBox(width: 12),
              Expanded(child: fields[2]),
            ],
          );
        },
      ),
    );
  }
}

class _OrganizationUnitList extends ConsumerStatefulWidget {
  const _OrganizationUnitList({
    required this.organizationId,
    required this.search,
    required this.type,
    required this.status,
    required this.pageSize,
    required this.canManage,
    super.key,
  });

  final String organizationId;
  final String search;
  final OrganizationUnitType? type;
  final OrganizationListStatusFilter status;
  final int pageSize;
  final bool canManage;

  @override
  ConsumerState<_OrganizationUnitList> createState() =>
      _OrganizationUnitListState();
}

class _OrganizationUnitListState extends ConsumerState<_OrganizationUnitList> {
  late final OrganizationPageAccumulator<OrganizationUnit> _pages;
  final Set<String> _expandedUnitIds = <String>{};
  bool _loadingMore = false;
  String? _loadError;

  String get organizationId => widget.organizationId;
  bool get canManage => widget.canManage;

  @override
  void initState() {
    super.initState();
    _pages = OrganizationPageAccumulator(idOf: (item) => item.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final query = OrganizationUnitListQuery(
      organizationId: organizationId,
      status: widget.status,
      limit: widget.pageSize,
    );
    final units = ref.watch(umFilteredOrganizationUnitsProvider(query));
    return units.when(
      loading: () => LoadingStateView(message: l10n.lookup('umLoading')),
      error: (error, _) => ErrorStateView(
        title: l10n.lookup('umCommandFailed'),
        description: error.toString(),
      ),
      data: (items) {
        if (items.isEmpty) {
          return EmptyStateView(
            icon: Icons.account_tree_outlined,
            title: l10n.lookup('umNoUnits'),
          );
        }
        _pages.seedCursor(
          firstPage: items,
          pageSize: widget.pageSize,
          sortValueOf: (item) => item.nameLower,
        );
        final allUnits = _pages.mergeFirstPage(items);
        final visibleUnits = _buildVisibleUnits(allUnits);
        final footerCount = _pages.hasMore || _loadError != null ? 1 : 0;
        if (visibleUnits.isEmpty) {
          return Column(
            children: [
              Expanded(
                child: EmptyStateView(
                  icon: Icons.account_tree_outlined,
                  title: l10n.lookup('umNoUnits'),
                ),
              ),
              if (footerCount == 1)
                OrganizationLoadMoreButton(
                  loading: _loadingMore,
                  error: _loadError,
                  onPressed: () => _loadMore(query),
                ),
            ],
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
          itemCount: visibleUnits.length + footerCount,
          separatorBuilder: (_, index) => index < visibleUnits.length - 1
              ? const Divider(height: 1)
              : const SizedBox.shrink(),
          itemBuilder: (context, index) {
            if (index == visibleUnits.length) {
              return OrganizationLoadMoreButton(
                loading: _loadingMore,
                error: _loadError,
                onPressed: () => _loadMore(query),
              );
            }
            return _buildUnitRow(context, ref, visibleUnits[index]);
          },
        );
      },
    );
  }

  List<OrganizationUnit> _buildVisibleUnits(List<OrganizationUnit> units) {
    final byParent = <String, List<OrganizationUnit>>{};
    final byId = <String, OrganizationUnit>{};
    for (final unit in units) {
      byId[unit.id] = unit;
      final parentId = unit.parentUnitId?.trim() ?? '';
      byParent.putIfAbsent(parentId, () => []).add(unit);
    }
    for (final children in byParent.values) {
      children.sort(_compareUnitsByName);
    }

    final normalizedSearch = widget.search.trim().toLowerCase();
    final filtering = normalizedSearch.isNotEmpty || widget.type != null;
    final includedIds = <String>{};
    if (filtering) {
      for (final unit in units) {
        final matchesSearch = normalizedSearch.isEmpty ||
            unit.nameLower.contains(normalizedSearch);
        final matchesType = widget.type == null || unit.type == widget.type;
        if (!matchesSearch || !matchesType) continue;
        includedIds.add(unit.id);
        includedIds.addAll(unit.ancestorUnitIds);
        var parentId = unit.parentUnitId;
        while (parentId != null && parentId.trim().isNotEmpty) {
          includedIds.add(parentId);
          parentId = byId[parentId]?.parentUnitId;
        }
      }
    }

    final visible = <OrganizationUnit>[];
    void appendBranch(OrganizationUnit unit) {
      if (filtering && !includedIds.contains(unit.id)) return;
      visible.add(unit);
      final expanded = filtering || _expandedUnitIds.contains(unit.id);
      if (!expanded) return;
      for (final child in byParent[unit.id] ?? const <OrganizationUnit>[]) {
        appendBranch(child);
      }
    }

    final roots = units
        .where((unit) => unit.type == OrganizationUnitType.department)
        .toList(growable: false)
      ..sort(_compareUnitsByName);
    for (final department in roots) {
      appendBranch(department);
    }
    return visible;
  }

  Widget _buildUnitRow(
    BuildContext context,
    WidgetRef ref,
    OrganizationUnit unit,
  ) {
    final l10n = S.of(context);
    final expandable = unit.type == OrganizationUnitType.department ||
        unit.type == OrganizationUnitType.service;
    final expanded = _expandedUnitIds.contains(unit.id);
    final filtering = widget.search.trim().isNotEmpty || widget.type != null;
    final indent = (unit.depth * 28).clamp(0, 84).toDouble();
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: ListTile(
        minTileHeight: 56,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        onTap: () => context.go(
          '/service/usermanagement/structure/${unit.id}'
          '?organizationId=${Uri.encodeQueryComponent(organizationId)}',
        ),
        leading: SizedBox(
          width: 72,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (expandable)
                IconButton(
                  key: Key('expand-unit-${unit.id}'),
                  tooltip: expanded
                      ? l10n.lookup('umCollapseUnit')
                      : l10n.lookup('umExpandUnit'),
                  onPressed: filtering
                      ? null
                      : () => setState(() {
                            if (expanded) {
                              _expandedUnitIds.remove(unit.id);
                            } else {
                              _expandedUnitIds.add(unit.id);
                            }
                          }),
                  icon: Icon(
                    expanded || filtering
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                  ),
                )
              else
                const SizedBox(width: 48),
              Icon(_unitIcon(unit.type), size: 21),
            ],
          ),
        ),
        title: Text(
          unit.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: unit.type == OrganizationUnitType.department
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
        trailing: canManage
            ? PopupMenuButton<String>(
                onSelected: (value) => _handleAction(
                  context,
                  ref,
                  value,
                  unit,
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'child',
                    child: Text(l10n.lookup('umCreateChildUnit')),
                  ),
                  PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                  if (unit.type != OrganizationUnitType.department)
                    PopupMenuItem(
                      value: 'move',
                      child: Text(l10n.lookup('umMoveUnit')),
                    ),
                  if ((unit.headAssignmentId ?? '').trim().isEmpty ||
                      (unit.actingHeadAssignmentId ?? '').trim().isEmpty)
                    PopupMenuItem(
                      value: 'head',
                      child: Text(l10n.lookup('umAssignHead')),
                    ),
                  PopupMenuItem(value: 'archive', child: Text(l10n.archive)),
                ],
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }

  Future<void> _loadMore(OrganizationUnitListQuery query) async {
    final cursor = _pages.nextCursor;
    if (_loadingMore || cursor == null) return;
    setState(() {
      _loadingMore = true;
      _loadError = null;
    });
    try {
      final page = await ref
          .read(userManagementRepositoryProvider)
          .fetchOrganizationUnitsPage(
            query: query,
            page: OrganizationPageRequest(
              limit: widget.pageSize,
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

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    OrganizationUnit unit,
  ) async {
    switch (action) {
      case 'child':
        final childTypes =
            const OrganizationHierarchyPolicy().allowedChildTypes(unit.type);
        if (childTypes.isEmpty) {
          _message(context, S.of(context).lookup('umNoAvailableChildren'));
          return;
        }
        await _createUnit(
          context,
          ref,
          organizationId: organizationId,
          type: childTypes.first,
          parentUnitId: unit.id,
        );
        return;
      case 'edit':
        await _editUnit(context, ref, unit);
        return;
      case 'move':
        await _moveUnit(context, ref, unit);
        return;
      case 'head':
        await _assignHead(context, ref, unit);
        return;
      case 'archive':
        await _archiveUnit(context, ref, unit);
        return;
    }
  }

  Future<void> _editUnit(
    BuildContext context,
    WidgetRef ref,
    OrganizationUnit unit,
  ) async {
    final l10n = S.of(context);
    final result = await showOrganizationUnitFormDialog(
      context,
      type: unit.type,
      unit: unit,
      onSubmit: (form) => ref
          .read(umOrganizationCommandControllerProvider.notifier)
          .runOrThrow<void>(
            action: 'updateOrganizationUnit',
            command: () => ref
                .read(userManagementRepositoryProvider)
                .updateOrganizationUnit(_updatedUnit(unit, form)),
          ),
      submissionErrorBuilder: (error) =>
          userManagementCommandErrorMessage(l10n, error),
      onSubmissionError: (error, stackTrace) =>
          reportUserManagementCommandError(
        context,
        operation: 'updateOrganizationUnit',
        error: error,
        stackTrace: stackTrace,
      ),
    );
    if (result == null || !context.mounted) return;
    _message(context, l10n.lookup('umUnitUpdated'));
  }

  Future<void> _assignHead(
    BuildContext context,
    WidgetRef ref,
    OrganizationUnit unit,
  ) =>
      assignOrganizationUnitLeadership(context, ref, unit: unit);

  Future<void> _moveUnit(
    BuildContext context,
    WidgetRef ref,
    OrganizationUnit unit,
  ) async {
    final units = await ref.read(
      umCompleteOrganizationHierarchyProvider(organizationId).future,
    );
    if (!context.mounted) return;
    final requiredParentType =
        const OrganizationHierarchyPolicy().requiredParentType(unit.type);
    final eligibleParents = units
        .where(
          (candidate) =>
              candidate.isActive &&
              candidate.id != unit.id &&
              candidate.id != unit.parentUnitId &&
              !candidate.ancestorUnitIds.contains(unit.id) &&
              (requiredParentType == null ||
                  candidate.type == requiredParentType),
        )
        .toList(growable: false);
    if (eligibleParents.isEmpty) {
      _message(context, S.of(context).lookup('umNoEligibleParentUnits'));
      return;
    }
    final result = await showOrganizationUnitMoveDialog(
      context,
      unit: unit,
      eligibleParents: eligibleParents,
    );
    if (result == null || !context.mounted) return;
    final success = await _run(
      context,
      ref,
      'moveOrganizationUnit',
      () => ref.read(userManagementRepositoryProvider).moveOrganizationUnit(
            organizationId: organizationId,
            unitId: unit.id,
            parentUnitId: result.parentUnitId,
            reason: result.reason,
          ),
    );
    if (success && context.mounted) {
      _message(context, S.of(context).lookup('umUnitMoved'));
    }
  }

  Future<void> _archiveUnit(
    BuildContext context,
    WidgetRef ref,
    OrganizationUnit unit,
  ) async {
    final l10n = S.of(context);
    final reason = await showOrganizationReasonDialog(
      context,
      title: l10n.lookup('umArchiveUnit'),
      description: l10n.lookup('umArchiveUnitDescription'),
      reasonLabel: l10n.lookup('umArchiveReason'),
      confirmLabel: l10n.archive,
      destructive: true,
    );
    if (reason == null || !context.mounted) return;
    final success = await _run(
        context,
        ref,
        'archiveOrganizationUnit',
        () =>
            ref.read(userManagementRepositoryProvider).archiveOrganizationUnit(
                  organizationId: organizationId,
                  unitId: unit.id,
                  reason: reason,
                ));
    if (success && context.mounted) {
      _message(context, l10n.lookup('umUnitArchived'));
    }
  }
}

int _compareUnitsByName(OrganizationUnit left, OrganizationUnit right) {
  final byName = left.nameLower.compareTo(right.nameLower);
  return byName != 0 ? byName : left.id.compareTo(right.id);
}

Future<void> _createUnit(
  BuildContext context,
  WidgetRef ref, {
  required String organizationId,
  required OrganizationUnitType type,
  required String? parentUnitId,
}) async {
  final l10n = S.of(context);
  final result = await showOrganizationUnitFormDialog(
    context,
    type: type,
    onSubmit: (form) async {
      final unitId = await ref
          .read(umOrganizationCommandControllerProvider.notifier)
          .runOrThrow<String>(
            action: 'createOrganizationUnit',
            command: () => ref
                .read(userManagementRepositoryProvider)
                .createOrganizationUnit(
                  organizationId: organizationId,
                  type: type,
                  code: form.code,
                  name: form.name,
                  description: form.description,
                  parentUnitId: parentUnitId,
                ),
          );
      if (unitId.trim().isEmpty) {
        throw const OrganizationCommandException(
          code: 'internal',
          message: 'The server returned an invalid organization unit response.',
        );
      }
    },
    submissionErrorBuilder: (error) =>
        userManagementCommandErrorMessage(l10n, error),
    onSubmissionError: (error, stackTrace) => reportUserManagementCommandError(
      context,
      operation: 'createOrganizationUnit',
      error: error,
      stackTrace: stackTrace,
    ),
  );
  if (result != null && context.mounted) {
    _message(context, l10n.lookup('umUnitCreated'));
  }
}

Future<bool> _run(
  BuildContext context,
  WidgetRef ref,
  String action,
  Future<void> Function() command,
) async {
  try {
    await ref
        .read(umOrganizationCommandControllerProvider.notifier)
        .runOrThrow<void>(action: action, command: command);
    return true;
  } catch (error, stackTrace) {
    if (!context.mounted) {
      logUserManagementCommandError(
        operation: action,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
    reportUserManagementCommandError(
      context,
      operation: action,
      error: error,
      stackTrace: stackTrace,
    );
    return false;
  }
}

OrganizationUnit _updatedUnit(
  OrganizationUnit unit,
  OrganizationUnitFormResult result,
) {
  return OrganizationUnit(
    id: unit.id,
    organizationId: unit.organizationId,
    type: unit.type,
    code: result.code,
    name: result.name,
    description: result.description,
    parentUnitId: unit.parentUnitId,
    parentUnitType: unit.parentUnitType,
    ancestorUnitIds: unit.ancestorUnitIds,
    pathUnitIds: unit.pathUnitIds,
    pathNames: unit.pathNames,
    depth: unit.depth,
    scopeKeys: unit.scopeKeys,
    status: result.status,
    headUserId: unit.headUserId,
    headAssignmentId: unit.headAssignmentId,
    actingHeadUserId: unit.actingHeadUserId,
    actingHeadAssignmentId: unit.actingHeadAssignmentId,
    actingHeadEndsAt: unit.actingHeadEndsAt,
  );
}

void _message(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String _unitTypeLabel(S l10n, OrganizationUnitType type) => switch (type) {
      OrganizationUnitType.department => l10n.lookup('umDepartment'),
      OrganizationUnitType.service => l10n.lookup('umService'),
      OrganizationUnitType.bureau => l10n.lookup('umBureau'),
      OrganizationUnitType.custom => l10n.lookup('umUnitType'),
    };

String _statusFilterLabel(S l10n, OrganizationListStatusFilter value) =>
    l10n.lookup(
      switch (value) {
        OrganizationListStatusFilter.current => 'umCurrentRecords',
        OrganizationListStatusFilter.active => 'umActive',
        OrganizationListStatusFilter.inactive => 'umInactive',
        OrganizationListStatusFilter.archived => 'umArchived',
        OrganizationListStatusFilter.all => 'all',
      },
    );

IconData _unitIcon(OrganizationUnitType type) => switch (type) {
      OrganizationUnitType.department => Icons.apartment_outlined,
      OrganizationUnitType.service => Icons.hub_outlined,
      OrganizationUnitType.bureau => Icons.meeting_room_outlined,
      OrganizationUnitType.custom => Icons.account_tree_outlined,
    };
