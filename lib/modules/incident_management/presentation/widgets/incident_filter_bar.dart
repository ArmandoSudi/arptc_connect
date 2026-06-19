import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_enums.dart';
import 'package:arptc_connect/modules/incident_management/presentation/incident_localizations.dart';
import 'package:flutter/material.dart';

class IncidentFilterBar extends StatefulWidget {
  const IncidentFilterBar({
    required this.query,
    required this.onQueryChanged,
    required this.status,
    required this.onStatusChanged,
    super.key,
  });

  final String query;
  final ValueChanged<String> onQueryChanged;
  final String status;
  final ValueChanged<String> onStatusChanged;

  @override
  State<IncidentFilterBar> createState() => _IncidentFilterBarState();
}

class _IncidentFilterBarState extends State<IncidentFilterBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant IncidentFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.text = widget.query;
      _controller.selection =
          TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 620;
        final search = TextField(
          controller: _controller,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            labelText: l10n.searchIncidents,
            border: const OutlineInputBorder(),
          ),
          onChanged: widget.onQueryChanged,
        );
        final statusField = DropdownButtonFormField<String>(
          value: widget.status,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.tune),
            labelText: l10n.status,
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(value: '', child: Text(l10n.allStatuses)),
            ...IncidentStatus.values.map(
              (status) => DropdownMenuItem(
                value: status.value,
                child: Text(localizedIncidentStatusLabel(l10n, status)),
              ),
            ),
          ],
          onChanged: (value) => widget.onStatusChanged(value ?? ''),
        );

        if (stacked) {
          return Column(
            children: [
              search,
              const SizedBox(height: 10),
              statusField,
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 3, child: search),
            const SizedBox(width: 12),
            Expanded(child: statusField),
          ],
        );
      },
    );
  }
}

List<T> filterIncidentTickets<T>({
  required List<T> tickets,
  required String query,
  required String status,
  required String Function(T ticket) searchText,
  required String Function(T ticket) statusValue,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  return tickets.where((ticket) {
    final statusMatches = status.isEmpty || statusValue(ticket) == status;
    if (!statusMatches) {
      return false;
    }
    if (normalizedQuery.isEmpty) {
      return true;
    }
    return searchText(ticket).toLowerCase().contains(normalizedQuery);
  }).toList();
}
