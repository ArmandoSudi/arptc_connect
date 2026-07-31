import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/audit_query.dart';
import '../widgets/reporting_page_shell.dart';
import '../reporting_administration_strings.dart';

class AuditLogDetailScreen extends StatelessWidget {
  const AuditLogDetailScreen({required this.event, super.key});
  final GlobalAuditEvent event;

  @override
  Widget build(BuildContext context) {
    final strings = ReportingAdministrationStrings.of(context);
    return ReportingPageShell(
      title: event.action,
      subtitle: '${event.module} • ${event.entityReference ?? event.entityId}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReportingPanel(
            title: strings.value('event'),
            child: Column(children: [
              _row(
                  strings.value('occurred'),
                  DateFormat.yMMMd()
                      .add_Hms()
                      .format(event.createdAt.toLocal())),
              _row(strings.value('actor'), event.actor.displayName),
              _row(strings.value('entity'),
                  '${event.entityType}/${event.entityId}'),
              _row(strings.value('correlation'), event.correlationId),
              _row(strings.value('confidentiality'),
                  event.confidentiality.value),
              if (event.fromState != null || event.toState != null)
                _row(strings.value('transition'),
                    '${event.fromState ?? '-'} → ${event.toState ?? '-'}'),
            ]),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth >= 760
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;
            return Wrap(spacing: 16, runSpacing: 16, children: [
              SizedBox(
                  width: width,
                  child: ReportingPanel(
                      title: strings.value('before'),
                      child: SelectableText(event.before.toString()))),
              SizedBox(
                  width: width,
                  child: ReportingPanel(
                      title: strings.value('after'),
                      child: SelectableText(event.after.toString()))),
            ]);
          }),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => ListTile(
      title: Text(label),
      trailing: Flexible(child: Text(value, textAlign: TextAlign.end)));
}
