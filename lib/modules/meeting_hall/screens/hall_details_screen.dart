import 'dart:developer';

import 'package:arptc_connect/core/theme.dart';
import 'package:arptc_connect/modules/meeting_hall/models/reservation.dart';
import 'package:arptc_connect/modules/meeting_hall/models/reservation_status.dart';
import 'package:arptc_connect/modules/meeting_hall/repositories/reservation_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:gap/gap.dart';
import '../widgets/reservation_dialog.dart';

class HallDetailsScreen extends ConsumerStatefulWidget {
  final String hallId;

  const HallDetailsScreen({super.key, required this.hallId});

  @override
  ConsumerState<HallDetailsScreen> createState() => _HallDetailsScreenState();
}

class _HallDetailsScreenState extends ConsumerState<HallDetailsScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;

  @override
  Widget build(BuildContext context) {
    final reservationsAsync = ref.watch(hallDateReservationsProvider((
      hallId: widget.hallId,
      date: _selectedDay,
    )));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hall Name"),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showHallInfo(context),
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 30)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: (day) {
              return reservationsAsync.when(
                data: (reservations) => reservations
                    .where(
                        (reservation) => isSameDay(reservation.startTime, day))
                    .toList(),
                loading: () => [],
                error: (_, __) => [],
              );
            },
            calendarStyle: const CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(),
          const Gap(8),
          Expanded(
            child: _ReservedAgendaPanel(
              hallId: widget.hallId,
              selectedDate: _selectedDay,
              onCreateReservation: () => _showReservationDialog(context),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showReservationDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showReservationDialog(
    BuildContext context,
  ) {
    showDialog(
      context: context,
      builder: (context) => ReservationDialog(
        hallId: widget.hallId,
        selectedDate: _selectedDay,
      ),
    );
  }

  void _showHallInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("widget.hall.name"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Emplacement: widget.hall.location '),
            Gap(8),
            Text('Capacité: widget.hall.capacity personnes'),
            Gap(8),
            Text("widget.hall.description"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class _ReservedAgendaPanel extends ConsumerWidget {
  final String hallId;
  final DateTime selectedDate;
  final VoidCallback onCreateReservation;

  const _ReservedAgendaPanel({
    required this.hallId,
    required this.selectedDate,
    required this.onCreateReservation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(hallDateReservationsProvider((
      hallId: hallId,
      date: selectedDate,
    )));

    return reservationsAsync.when(
      data: (reservations) {
        final reservedSlots = reservations
            .where((reservation) =>
                reservation.status != ReservationStatus.rejected)
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReservedAgendaHeader(
                selectedDate: selectedDate,
                reservationCount: reservedSlots.length,
                onCreateReservation: onCreateReservation,
              ),
              const Gap(14),
              Expanded(
                child: reservedSlots.isEmpty
                    ? _ReservedAgendaEmptyState(
                        onCreateReservation: onCreateReservation,
                      )
                    : ListView.separated(
                        itemCount: reservedSlots.length,
                        itemBuilder: (context, index) {
                          final reservation = reservedSlots[index];
                          return _ReservedAgendaItem(
                            reservation: reservation,
                            isLast: index == reservedSlots.length - 1,
                          );
                        },
                        separatorBuilder: (context, index) => const Gap(12),
                      ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        log('Error loading reservations: $error');
        return Center(
          child: Text('Error loading reservations: $error'),
        );
      },
    );
  }
}

class _ReservedAgendaHeader extends StatelessWidget {
  final DateTime selectedDate;
  final int reservationCount;
  final VoidCallback onCreateReservation;

  const _ReservedAgendaHeader({
    required this.selectedDate,
    required this.reservationCount,
    required this.onCreateReservation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 620;
        final titleGroup = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Réservations du jour',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const Gap(4),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _AgendaMetaChip(
                  icon: Icons.event_note_outlined,
                  label: 'Jour sélectionné: ${_formatDate(selectedDate)}',
                ),
                _AgendaMetaChip(
                  icon: Icons.meeting_room_outlined,
                  label:
                      '$reservationCount réservation${reservationCount > 1 ? 's' : ''}',
                ),
              ],
            ),
          ],
        );

        final action = FilledButton.icon(
          onPressed: onCreateReservation,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Réserver un créneau'),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleGroup,
              const Gap(12),
              action,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleGroup),
            action,
          ],
        );
      },
    );
  }
}

class _AgendaMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AgendaMetaChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.55),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const Gap(6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservedAgendaItem extends StatelessWidget {
  final MeetingHallReservation reservation;
  final bool isLast;

  const _ReservedAgendaItem({
    required this.reservation,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final statusStyle =
        _ReservationStatusStyle.from(context, reservation.status);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 92,
            child: Column(
              children: [
                _AgendaTimeChip(
                  startTime: reservation.startTime,
                  endTime: reservation.endTime,
                  color: statusStyle.accent,
                  foregroundColor: statusStyle.onAccent,
                ),
                const Gap(8),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: statusStyle.accent.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Gap(12),
          Expanded(
            child: _ReservedReservationCard(
              reservation: reservation,
              statusStyle: statusStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaTimeChip extends StatelessWidget {
  final DateTime startTime;
  final DateTime endTime;
  final Color color;
  final Color foregroundColor;

  const _AgendaTimeChip({
    required this.startTime,
    required this.endTime,
    required this.color,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.22),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _formatTime(startTime),
            style: theme.textTheme.labelLarge?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Gap(2),
          Text(
            _formatTime(endTime),
            style: theme.textTheme.labelSmall?.copyWith(
              color: foregroundColor.withOpacity(0.82),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservedReservationCard extends StatelessWidget {
  final MeetingHallReservation reservation;
  final _ReservationStatusStyle statusStyle;

  const _ReservedReservationCard({
    required this.reservation,
    required this.statusStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.corporateTheme;
    final duration = reservation.endTime.difference(reservation.startTime);
    final hasDescription = reservation.description.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: statusStyle.background,
        borderRadius: BorderRadius.circular(tokens.panelRadius),
        border: Border.all(color: statusStyle.borderColor),
        boxShadow: [
          BoxShadow(
            color: tokens.cardShadow,
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusStyle.accent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              statusStyle.icon,
              color: statusStyle.accent,
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        reservation.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Gap(10),
                    _ReservationStatusPill(statusStyle: statusStyle),
                  ],
                ),
                if (hasDescription) ...[
                  const Gap(8),
                  Text(
                    reservation.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
                const Gap(14),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _ReservationInfoChip(
                      icon: Icons.schedule_outlined,
                      label:
                          '${_formatTime(reservation.startTime)} - ${_formatTime(reservation.endTime)}',
                    ),
                    _ReservationInfoChip(
                      icon: Icons.timelapse_outlined,
                      label: _formatDuration(duration),
                    ),
                    if (reservation.userId.trim().isNotEmpty)
                      _ReservationInfoChip(
                        icon: Icons.person_outline,
                        label: reservation.userId,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservationStatusPill extends StatelessWidget {
  final _ReservationStatusStyle statusStyle;

  const _ReservationStatusPill({
    required this.statusStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusStyle.accent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: statusStyle.accent.withOpacity(0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusStyle.icon,
            size: 14,
            color: statusStyle.accent,
          ),
          const Gap(6),
          Text(
            statusStyle.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: statusStyle.accent,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservationInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ReservationInfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const Gap(6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservedAgendaEmptyState extends StatelessWidget {
  final VoidCallback onCreateReservation;

  const _ReservedAgendaEmptyState({
    required this.onCreateReservation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.corporateTheme;

    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 620),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow.withOpacity(0.72),
          borderRadius: BorderRadius.circular(tokens.panelRadius),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: tokens.successContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.event_available_rounded,
                color: tokens.onSuccessContainer,
                size: 34,
              ),
            ),
            const Gap(16),
            Text(
              'Aucune réservation pour cette date',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const Gap(8),
            Text(
              'Cette salle n’a pas encore de réservation enregistrée pour le jour sélectionné.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(18),
            FilledButton.icon(
              onPressed: onCreateReservation,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Réserver un créneau'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReservationStatusStyle {
  final String label;
  final IconData icon;
  final Color accent;
  final Color onAccent;
  final Color background;
  final Color borderColor;

  const _ReservationStatusStyle({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onAccent,
    required this.background,
    required this.borderColor,
  });

  factory _ReservationStatusStyle.from(
    BuildContext context,
    ReservationStatus status,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.corporateTheme;
    final isDark = theme.brightness == Brightness.dark;

    switch (status) {
      case ReservationStatus.accepted:
        return _ReservationStatusStyle(
          label: 'Réservé',
          icon: Icons.event_busy_rounded,
          accent: tokens.warning,
          onAccent: tokens.onWarning,
          background: Color.lerp(
            scheme.surfaceContainerLow,
            tokens.warning,
            isDark ? 0.18 : 0.10,
          )!,
          borderColor: tokens.warning.withOpacity(isDark ? 0.42 : 0.28),
        );
      case ReservationStatus.onHold:
        return _ReservationStatusStyle(
          label: 'En attente',
          icon: Icons.pending_actions_rounded,
          accent: scheme.primary,
          onAccent: scheme.onPrimary,
          background: Color.lerp(
            scheme.surfaceContainerLow,
            scheme.primary,
            isDark ? 0.16 : 0.08,
          )!,
          borderColor: scheme.primary.withOpacity(isDark ? 0.38 : 0.22),
        );
      case ReservationStatus.rejected:
        return _ReservationStatusStyle(
          label: 'Refusé',
          icon: Icons.block_rounded,
          accent: scheme.error,
          onAccent: scheme.onError,
          background: Color.lerp(
            scheme.surfaceContainerLow,
            scheme.error,
            isDark ? 0.16 : 0.08,
          )!,
          borderColor: scheme.error.withOpacity(isDark ? 0.36 : 0.22),
        );
    }
  }
}

String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours <= 0) {
    return '$minutes min';
  }
  if (minutes == 0) {
    return '${hours}h';
  }
  return '${hours}h ${minutes}min';
}
