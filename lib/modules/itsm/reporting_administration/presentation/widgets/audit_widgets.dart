import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/audit_query.dart';
import '../reporting_administration_strings.dart';
import 'reporting_page_shell.dart';

class AuditFilterBar extends StatefulWidget {
  const AuditFilterBar(
      {required this.initial, required this.onApply, super.key, this.onExport});
  final AuditQuery initial;
  final ValueChanged<AuditQuery> onApply;
  final ValueChanged<AuditQuery>? onExport;

  @override
  State<AuditFilterBar> createState() => _AuditFilterBarState();
}

class _AuditFilterBarState extends State<AuditFilterBar> {
  late DateTime _from = widget.initial.from;
  late DateTime _to = widget.initial.to;
  late AuditEqualityDimension? _dimension = widget.initial.dimension;
  late final TextEditingController _value =
      TextEditingController(text: widget.initial.value);

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  AuditQuery get _query => AuditQuery(
        from: _from,
        to: _to,
        dimension: _value.text.trim().isEmpty ? null : _dimension,
        value: _value.text.trim().isEmpty ? null : _value.text.trim(),
      );

  @override
  Widget build(BuildContext context) {
    final strings = ReportingAdministrationStrings.of(context);
    return ReportingPanel(
      title: strings.value('auditFilters'),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: () => _pick(true),
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(
                '${strings.value('from')} ${DateFormat.yMd().format(_from)}'),
          ),
          OutlinedButton.icon(
            onPressed: () => _pick(false),
            icon: const Icon(Icons.event_outlined),
            label:
                Text('${strings.value('to')} ${DateFormat.yMd().format(_to)}'),
          ),
          SizedBox(
            width: 190,
            child: DropdownButtonFormField<AuditEqualityDimension?>(
              value: _dimension,
              decoration:
                  InputDecoration(labelText: strings.value('dimension')),
              items: [
                DropdownMenuItem(
                    value: null, child: Text(strings.value('none'))),
                ...AuditEqualityDimension.values.map((value) =>
                    DropdownMenuItem(value: value, child: Text(value.name))),
              ],
              onChanged: (value) => setState(() {
                _dimension = value;
                if (value == null) _value.clear();
              }),
            ),
          ),
          SizedBox(
            width: 220,
            child: TextField(
                controller: _value,
                enabled: _dimension != null,
                decoration: InputDecoration(labelText: strings.value('value'))),
          ),
          FilledButton.icon(
              onPressed: () => widget.onApply(_query),
              icon: const Icon(Icons.filter_alt_outlined),
              label: Text(strings.value('apply'))),
          if (widget.onExport != null)
            OutlinedButton.icon(
                onPressed: () => widget.onExport!(_query),
                icon: const Icon(Icons.download_outlined),
                label: Text(strings.value('export'))),
        ],
      ),
    );
  }

  Future<void> _pick(bool from) async {
    final initial = from ? _from : _to;
    final value = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (value == null || !mounted) return;
    setState(() {
      if (from) {
        _from = value;
      } else {
        _to = DateTime(value.year, value.month, value.day, 23, 59, 59);
      }
    });
  }
}

class AuditEventList extends StatelessWidget {
  const AuditEventList({required this.events, super.key, this.onSelected});
  final List<GlobalAuditEvent> events;
  final ValueChanged<GlobalAuditEvent>? onSelected;

  @override
  Widget build(BuildContext context) => ReportingPanel(
        child: events.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(28),
                child: Center(
                  child: Text(
                    ReportingAdministrationStrings.of(context)
                        .value('noEvents'),
                  ),
                ))
            : Column(
                children: events
                    .map((event) => ListTile(
                          onTap: onSelected == null
                              ? null
                              : () => onSelected!(event),
                          leading: Icon(event.isRestricted
                              ? Icons.lock_outline
                              : Icons.history_rounded),
                          title: Text(event.action),
                          subtitle: Text(
                              '${event.entityReference ?? event.entityId} • ${event.actor.displayName}'),
                          trailing: Text(DateFormat.yMd()
                              .add_Hm()
                              .format(event.createdAt.toLocal())),
                        ))
                    .toList(growable: false),
              ),
      );
}
