import 'package:arptc_connect/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';

import '../../application/changes_application.dart';
import '../../data/change_repository.dart';
import '../../domain/changes_domain.dart';
import '../../../shared/application/itsm_providers.dart';
import '../../../shared/domain/itsm_common.dart';
import '../change_presentation_strings.dart';
import '../widgets/change_async_view.dart';
import '../widgets/change_calendar_view.dart';
import '../widgets/change_page_shell.dart';

class ChangeCalendarScreen extends ConsumerStatefulWidget {
  const ChangeCalendarScreen({
    required this.onSelected,
    super.key,
    this.onBack,
  });

  final ValueChanged<ChangeCalendarEntry> onSelected;
  final VoidCallback? onBack;

  @override
  ConsumerState<ChangeCalendarScreen> createState() =>
      _ChangeCalendarScreenState();
}

class _ChangeCalendarScreenState extends ConsumerState<ChangeCalendarScreen> {
  ChangeCalendarDisplay _display = ChangeCalendarDisplay.month;
  DateTime _anchor = DateTime.now();
  ChangeType? _type;
  ChangeStatus? _status;
  bool _conflictsOnly = false;
  final _serviceFilter = TextEditingController();
  final _ciFilter = TextEditingController();

  @override
  void dispose() {
    _serviceFilter.dispose();
    _ciFilter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final session = ref.watch(itsmSessionProvider).valueOrNull;
    final scope = switch (session?.role) {
      ItsmRole.manager => ChangeCalendarScope.operational,
      ItsmRole.admin => ChangeCalendarScope.executive,
      _ => ChangeCalendarScope.ownAndPublished,
    };
    final window = _window();
    final query = ChangeCalendarQuery(
      scope: scope,
      startsAt: window.$1,
      endsAt: window.$2,
      type: _type,
      status: _status,
      hasConflict: _conflictsOnly ? true : null,
      serviceId: _serviceFilter.text.trim().isEmpty
          ? null
          : _serviceFilter.text.trim(),
      configurationItemId:
          _ciFilter.text.trim().isEmpty ? null : _ciFilter.text.trim(),
    );
    final entries = ref.watch(changeCalendarProvider(query));
    return ChangePageShell(
      title: l10n.changeCalendarTitle,
      subtitle: l10n.changeCalendarSubtitle,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChangeSurfaceCard(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IconButton(
                  tooltip: l10n.calendarPrevious,
                  onPressed: () => _move(-1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text(
                  _periodLabel(window),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  tooltip: l10n.calendarNext,
                  onPressed: () => _move(1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
                SegmentedButton<ChangeCalendarDisplay>(
                  segments: [
                    ButtonSegment(
                      value: ChangeCalendarDisplay.month,
                      label: Text(l10n.calendarMonth),
                    ),
                    ButtonSegment(
                      value: ChangeCalendarDisplay.week,
                      label: Text(l10n.calendarWeek),
                    ),
                    ButtonSegment(
                      value: ChangeCalendarDisplay.agenda,
                      label: Text(l10n.calendarAgenda),
                    ),
                  ],
                  selected: {_display},
                  onSelectionChanged: (value) =>
                      setState(() => _display = value.first),
                ),
                DropdownButton<ChangeType?>(
                  value: _type,
                  hint: Text(l10n.changeType),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.changeType),
                    ),
                    for (final type in ChangeType.values)
                      DropdownMenuItem(
                        value: type,
                        child: Text(l10n.changeTypeLabel(type)),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _type = value;
                    if (value != null) {
                      _status = null;
                      _conflictsOnly = false;
                      _serviceFilter.clear();
                      _ciFilter.clear();
                    }
                  }),
                ),
                DropdownButton<ChangeStatus?>(
                  value: _status,
                  hint: Text(l10n.changeSelectStatus),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.allStatuses),
                    ),
                    for (final status in ChangeStatus.values)
                      DropdownMenuItem(
                        value: status,
                        child: Text(l10n.changeStatusLabel(status)),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _status = value;
                    if (value != null) {
                      _type = null;
                      _conflictsOnly = false;
                      _serviceFilter.clear();
                      _ciFilter.clear();
                    }
                  }),
                ),
                SizedBox(
                  width: 220,
                  child: CommonTextInput(
                    label: '',
                    controller: _serviceFilter,
                    hintText: l10n.changeServiceFilter,
                    onChanged: (value) {
                      if (value.trim().isNotEmpty) {
                        _ciFilter.clear();
                        _type = null;
                        _status = null;
                        _conflictsOnly = false;
                      }
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: CommonTextInput(
                    label: '',
                    controller: _ciFilter,
                    hintText: l10n.changeCiFilter,
                    onChanged: (value) {
                      if (value.trim().isNotEmpty) {
                        _serviceFilter.clear();
                        _type = null;
                        _status = null;
                        _conflictsOnly = false;
                      }
                      setState(() {});
                    },
                  ),
                ),
                if (session?.role == ItsmRole.admin)
                  Chip(label: Text(l10n.changeReadOnly)),
                FilterChip(
                  label: Text(l10n.changeConflictsOnly),
                  selected: _conflictsOnly,
                  onSelected: (value) => setState(() {
                    _conflictsOnly = value;
                    if (value) {
                      _type = null;
                      _status = null;
                      _serviceFilter.clear();
                      _ciFilter.clear();
                    }
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ChangeAsyncView<List<ChangeCalendarEntry>>(
            value: entries,
            loadingLabel: l10n.loading,
            retryLabel: l10n.retry,
            onRetry: () => ref.invalidate(changeCalendarProvider(query)),
            data: (items) => ChangeCalendarView(
              entries: items,
              display: _display,
              startsAt: window.$1,
              endsAt: window.$2,
              onSelected: widget.onSelected,
            ),
          ),
        ],
      ),
    );
  }

  (DateTime, DateTime) _window() {
    final local = DateTime(_anchor.year, _anchor.month, _anchor.day);
    if (_display == ChangeCalendarDisplay.week) {
      final start = local.subtract(Duration(days: local.weekday - 1));
      return (start.toUtc(), start.add(const Duration(days: 7)).toUtc());
    }
    final start = DateTime(local.year, local.month);
    final end = DateTime(local.year, local.month + 1);
    return (start.toUtc(), end.toUtc());
  }

  void _move(int amount) {
    setState(() {
      _anchor = _display == ChangeCalendarDisplay.week
          ? _anchor.add(Duration(days: amount * 7))
          : DateTime(_anchor.year, _anchor.month + amount, 1);
    });
  }

  String _periodLabel((DateTime, DateTime) window) =>
      '${DateFormat.yMMMd().format(window.$1.toLocal())} - '
      '${DateFormat.yMMMd().format(window.$2.toLocal().subtract(const Duration(days: 1)))}';
}
