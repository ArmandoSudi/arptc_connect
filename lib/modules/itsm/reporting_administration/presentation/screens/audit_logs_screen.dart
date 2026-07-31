import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/pagination.dart';
import '../../application/reporting_administration_providers.dart';
import '../../domain/audit_query.dart';
import '../reporting_administration_strings.dart';
import '../widgets/audit_widgets.dart';
import '../widgets/reporting_async_state.dart';
import '../widgets/reporting_page_shell.dart';

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key, this.onOpenEvent});
  final ValueChanged<GlobalAuditEvent>? onOpenEvent;

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  late AuditQuery query = AuditQuery(
    from: DateTime.now().subtract(const Duration(days: 30)),
    to: DateTime.now(),
  );

  AuditEventsPageRequest get request =>
      AuditEventsPageRequest(query: query, page: PageRequest());

  @override
  Widget build(BuildContext context) {
    final strings = ReportingAdministrationStrings.of(context);
    final activeRequest = request;
    final events = ref.watch(auditEventsPageProvider(activeRequest));
    return ReportingPageShell(
      title: strings.value('audit'),
      subtitle: strings.value('auditDescription'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuditFilterBar(
            initial: query,
            onApply: (next) => setState(() => query = next),
            onExport: (next) async {
              final messenger = ScaffoldMessenger.of(context);
              final controller =
                  await ref.read(auditLogControllerProvider.future);
              await controller.export(next,
                  idempotencyKey:
                      'audit-export-${DateTime.now().microsecondsSinceEpoch}');
              if (mounted) {
                messenger.showSnackBar(SnackBar(
                  content: Text(strings.value('auditExportQueued')),
                ));
              }
            },
          ),
          const SizedBox(height: 16),
          ReportingAsyncState(
            value: events,
            loadingLabel: strings.value('loading'),
            errorLabel: strings.value('error'),
            emptyLabel: strings.value('noEvents'),
            isEmpty: (page) => page.isEmpty,
            onRetry: () =>
                ref.invalidate(auditEventsPageProvider(activeRequest)),
            data: (page) => AuditEventList(
                events: page.items, onSelected: widget.onOpenEvent),
          ),
        ],
      ),
    );
  }
}
