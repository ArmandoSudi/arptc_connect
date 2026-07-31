import 'package:arptc_connect/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/changes_domain.dart';
import '../change_presentation_strings.dart';
import 'change_page_shell.dart';
import 'change_request_views.dart';

enum ChangeCalendarDisplay { month, week, agenda }

class ChangeCalendarView extends StatelessWidget {
  const ChangeCalendarView({
    required this.entries,
    required this.display,
    required this.startsAt,
    required this.endsAt,
    required this.onSelected,
    super.key,
  });

  final List<ChangeCalendarEntry> entries;
  final ChangeCalendarDisplay display;
  final DateTime startsAt;
  final DateTime endsAt;
  final ValueChanged<ChangeCalendarEntry> onSelected;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return ChangeSurfaceCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36),
          child: Text(
            S.of(context).changeEmptyDescription,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (display == ChangeCalendarDisplay.agenda) {
      return _Agenda(entries: entries, onSelected: onSelected);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return _Agenda(entries: entries, onSelected: onSelected);
        }
        final days = List<DateTime>.generate(
          endsAt.difference(startsAt).inDays,
          (index) => startsAt.add(Duration(days: index)),
        );
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio:
                display == ChangeCalendarDisplay.month ? 0.86 : 0.72,
          ),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final day = days[index];
            final dayEntries = entries
                .where((entry) => _sameDay(entry.window.startsAt, day))
                .toList(growable: false);
            return _DayCell(
              day: day,
              entries: dayEntries,
              onSelected: onSelected,
            );
          },
        );
      },
    );
  }
}

class _Agenda extends StatelessWidget {
  const _Agenda({required this.entries, required this.onSelected});

  final List<ChangeCalendarEntry> entries;
  final ValueChanged<ChangeCalendarEntry> onSelected;

  @override
  Widget build(BuildContext context) {
    final sorted = [...entries]..sort(
        (left, right) => left.window.startsAt.compareTo(right.window.startsAt));
    return ChangeSurfaceCard(
      child: Column(
        children: [
          for (final entry in sorted)
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => onSelected(entry),
              leading: SizedBox(
                width: 64,
                child: Text(
                  DateFormat.MMMd().add_Hm().format(entry.window.startsAt),
                  textAlign: TextAlign.center,
                ),
              ),
              title: Text(entry.title),
              subtitle: Text(
                '${entry.changeNumber} • '
                '${S.of(context).changeRiskLabel(entry.risk)}',
              ),
              trailing: Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (entry.hasConflict)
                    Tooltip(
                      message: S.of(context).changeConflict,
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ChangeStatusBadge(status: entry.status),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.entries,
    required this.onSelected,
  });

  final DateTime day;
  final List<ChangeCalendarEntry> entries;
  final ValueChanged<ChangeCalendarEntry> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              DateFormat.E().add_d().format(day),
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Expanded(
              child: ListView(
                children: [
                  for (final entry in entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => onSelected(entry),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: entry.hasConflict
                                ? theme.colorScheme.errorContainer
                                : theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${DateFormat.Hm().format(entry.window.startsAt)} '
                            '${entry.title}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;
