import 'dart:convert';

import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/application/organization_timeline_accumulator.dart';
import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_audit_event.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_query.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/organization_load_more_button.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/user_management_access_gate.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/user_management_section_scaffold.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OrganizationAuditHistoryScreen extends ConsumerStatefulWidget {
  const OrganizationAuditHistoryScreen({
    required this.organizationId,
    super.key,
  });

  final String organizationId;

  @override
  ConsumerState<OrganizationAuditHistoryScreen> createState() =>
      _OrganizationAuditHistoryScreenState();
}

class _OrganizationAuditHistoryScreenState
    extends ConsumerState<OrganizationAuditHistoryScreen> {
  static const _pageSize = 40;
  late final OrganizationTimelineAccumulator<OrganizationAuditEvent> _pages;
  bool _loadingMore = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _pages = OrganizationTimelineAccumulator(idOf: (item) => item.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final query = OrganizationAuditQuery(
      organizationId: widget.organizationId,
      limit: _pageSize,
    );
    final events = ref.watch(umOrganizationAuditEventsProvider(query));
    return UserManagementAccessGate(
      requirePrivateProfiles: true,
      child: UserManagementSectionScaffold(
        selectedIndex: 0,
        title: l10n.lookup('umAuditHistory'),
        subtitle: l10n.lookup('umAuditHistoryDescription'),
        primaryAction: OutlinedButton.icon(
          onPressed: () => context.go('/service/usermanagement/organizations'),
          icon: const Icon(Icons.arrow_back),
          label: Text(l10n.back),
        ),
        primaryActionIsNavigation: true,
        body: events.when(
          loading: () => LoadingStateView(message: l10n.lookup('umLoading')),
          error: (error, _) => ErrorStateView(
            title: l10n.lookup('umCommandFailed'),
            description: error.toString(),
          ),
          data: (firstPage) => _buildEvents(query, firstPage),
        ),
      ),
    );
  }

  Widget _buildEvents(
    OrganizationAuditQuery query,
    List<OrganizationAuditEvent> firstPage,
  ) {
    final l10n = S.of(context);
    _pages.seedCursor(
      firstPage: firstPage,
      pageSize: query.limit,
      timestampOf: (item) => item.createdAt,
    );
    final events = _pages.mergeFirstPage(firstPage);
    if (events.isEmpty) {
      return EmptyStateView(
        icon: Icons.history_outlined,
        title: l10n.lookup('umNoAuditEvents'),
      );
    }
    final footerCount = _pages.hasMore || _loadError != null ? 1 : 0;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
      itemCount: events.length + footerCount,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == events.length) {
          return OrganizationLoadMoreButton(
            loading: _loadingMore,
            error: _loadError,
            onPressed: () => _loadMore(query),
          );
        }
        return _OrganizationAuditEventTile(event: events[index]);
      },
    );
  }

  Future<void> _loadMore(OrganizationAuditQuery query) async {
    final cursor = _pages.nextCursor;
    if (_loadingMore || cursor == null) return;
    setState(() {
      _loadingMore = true;
      _loadError = null;
    });
    try {
      final page = await ref
          .read(userManagementRepositoryProvider)
          .fetchOrganizationAuditEventsPage(
            query: query,
            page: OrganizationTimelinePageRequest(
              limit: query.limit,
              afterTimestamp: cursor.timestamp,
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

class _OrganizationAuditEventTile extends StatelessWidget {
  const _OrganizationAuditEventTile({required this.event});

  final OrganizationAuditEvent event;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final date = MaterialLocalizations.of(context).formatFullDate(
      event.createdAt.toLocal(),
    );
    return ExpansionTile(
      leading: const CircleAvatar(child: Icon(Icons.history_outlined)),
      title: Text(
        _readableEventType(event.eventType),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '$date · ${l10n.lookup('umActor')}: ${event.actorUid}\n'
        '${event.reason.isEmpty ? event.subjectId : event.reason}',
      ),
      childrenPadding: const EdgeInsets.fromLTRB(72, 0, 24, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (event.command.isNotEmpty)
          Text('${event.command} · ${event.commandId}'),
        if (event.before.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l10n.lookup('umBefore'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          SelectableText(_prettyJson(event.before)),
        ],
        if (event.after.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l10n.lookup('umAfter'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          SelectableText(_prettyJson(event.after)),
        ],
      ],
    );
  }
}

String _readableEventType(String value) => value
    .split('_')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0]}${part.substring(1).toLowerCase()}')
    .join(' ');

String _prettyJson(Map<String, dynamic> value) =>
    const JsonEncoder.withIndent('  ').convert(value);
