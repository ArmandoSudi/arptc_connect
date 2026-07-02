import 'dart:async';
import 'dart:developer';

import 'package:arptc_connect/core/theme.dart';
import 'package:arptc_connect/modules/meeting_hall/models/meeting_hall.dart';
import 'package:arptc_connect/modules/meeting_hall/models/reservation.dart';
import 'package:arptc_connect/modules/meeting_hall/models/reservation_status.dart';
import 'package:arptc_connect/modules/meeting_hall/providers/meeting_hall_access_provider.dart';
import 'package:arptc_connect/modules/meeting_hall/providers/meeting_hall_provider.dart';
import 'package:arptc_connect/modules/meeting_hall/repositories/reservation_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:gap/gap.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import '../widgets/reservation_dialog.dart';

class HallDetailsScreen extends ConsumerStatefulWidget {
  final String hallId;
  final DateTime? initialSelectedDate;
  final String? initialReservationId;

  const HallDetailsScreen({
    super.key,
    required this.hallId,
    this.initialSelectedDate,
    this.initialReservationId,
  });

  @override
  ConsumerState<HallDetailsScreen> createState() => _HallDetailsScreenState();
}

class _HallDetailsScreenState extends ConsumerState<HallDetailsScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;
  String _resolvedReservationId = '';
  String _loadingReservationId = '';

  @override
  void initState() {
    super.initState();
    _applyInitialSelectedDate(widget.initialSelectedDate, notify: false);
    _resolveReservationDate(widget.initialReservationId);
  }

  @override
  void didUpdateWidget(covariant HallDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hallId != widget.hallId ||
        !isSameDay(oldWidget.initialSelectedDate, widget.initialSelectedDate)) {
      _applyInitialSelectedDate(widget.initialSelectedDate);
    }
    if (oldWidget.hallId != widget.hallId ||
        oldWidget.initialReservationId != widget.initialReservationId) {
      _resolveReservationDate(widget.initialReservationId);
    }
  }

  void _resolveReservationDate(String? rawReservationId) {
    final reservationId = rawReservationId?.trim() ?? '';
    if (reservationId.isEmpty ||
        reservationId == _resolvedReservationId ||
        reservationId == _loadingReservationId) {
      return;
    }

    _loadingReservationId = reservationId;
    unawaited(_applyReservationDateFromId(reservationId));
  }

  Future<void> _applyReservationDateFromId(String reservationId) async {
    try {
      final reservation = await ref
          .read(reservationRepositoryProvider)
          .getReservationById(reservationId);
      if (!mounted || _loadingReservationId != reservationId) {
        return;
      }

      final reservationHallId = reservation.hallId.trim();
      if (reservationHallId.isNotEmpty && reservationHallId != widget.hallId) {
        return;
      }

      _resolvedReservationId = reservationId;
      _applyInitialSelectedDate(reservation.startTime);
    } catch (error, stackTrace) {
      log(
        'Unable to resolve meeting hall reservation date.',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (_loadingReservationId == reservationId) {
        _loadingReservationId = '';
      }
    }
  }

  void _applyInitialSelectedDate(
    DateTime? initialSelectedDate, {
    bool notify = true,
  }) {
    if (initialSelectedDate == null ||
        isSameDay(_selectedDay, initialSelectedDate)) {
      return;
    }
    void updateSelectedDate() {
      _selectedDay = initialSelectedDate;
      _focusedDay = initialSelectedDate;
    }

    if (!notify) {
      updateSelectedDate();
      return;
    }

    setState(updateSelectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(currentMeetingHallRoleProvider);
    final role = roleAsync.valueOrNull ?? MeetingHallRole.none;
    final hallAsync = ref.watch(selectedMeetingHallProvider(widget.hallId));
    final reservationsAsync = ref.watch(hallDateReservationsProvider((
      hallId: widget.hallId,
      date: _selectedDay,
    )));

    if (roleAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!role.canRead) {
      return const Scaffold(
        body: Center(
          child: Text('Vous n’avez pas accès au module Salles de réunion.'),
        ),
      );
    }

    return Scaffold(
      // TITLE
      appBar: AppBar(
        title: Text(hallAsync.valueOrNull?.name ?? 'Salle de réunion'),
        actions: [
          if (role.canManageReservations)
            IconButton(
              tooltip: 'Bloquer la salle',
              icon: const Icon(Icons.construction_rounded),
              onPressed: () => _showBlockRoomDialog(context),
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: hallAsync.valueOrNull == null
                ? null
                : () => _showHallInfo(context, hallAsync.valueOrNull!),
          ),
        ],
      ),
      body: Column(
        children: [
          // CALENDRIER
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
                      (reservation) =>
                          reservation.status.isVisibleInAgenda &&
                          isSameDay(reservation.startTime, day),
                    )
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
              canManageReservations: role.canManageReservations,
              onCreateReservation: role.canCreateReservation
                  ? () => _showReservationDialog(context)
                  : null,
            ),
          ),
        ],
      ),
      // floatingActionButton: role.canCreateReservation
      //     ? FloatingActionButton(
      //         onPressed: () => _showReservationDialog(context),
      //         child: const Icon(Icons.add),
      //       )
      //     : null,
    );
  }

  void _showBlockRoomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _BlockRoomDialog(
        hallId: widget.hallId,
        selectedDate: _selectedDay,
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

  void _showHallInfo(BuildContext context, MeetingHall hall) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(hall.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Emplacement: ${hall.location}'),
            const Gap(8),
            Text('Capacité: ${hall.capacity} personnes'),
            const Gap(8),
            Text(hall.description),
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
  final VoidCallback? onCreateReservation;
  final bool canManageReservations;

  const _ReservedAgendaPanel({
    required this.hallId,
    required this.selectedDate,
    required this.canManageReservations,
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
            .where((reservation) => reservation.status.isVisibleInAgenda)
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
                            canManageReservations: canManageReservations,
                            onApprove: () => _confirmReservationStatusChange(
                              context,
                              ref,
                              reservation,
                              ReservationStatus.accepted,
                            ),
                            onReject: () => _confirmReservationStatusChange(
                              context,
                              ref,
                              reservation,
                              ReservationStatus.rejected,
                            ),
                            onCancel: () => _confirmReservationStatusChange(
                              context,
                              ref,
                              reservation,
                              ReservationStatus.cancelled,
                            ),
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

  Future<void> _confirmReservationStatusChange(
    BuildContext context,
    WidgetRef ref,
    MeetingHallReservation reservation,
    ReservationStatus targetStatus,
  ) async {
    final isApproval = targetStatus == ReservationStatus.accepted;
    final isRejection = targetStatus == ReservationStatus.rejected;
    final isCancellation = targetStatus == ReservationStatus.cancelled;
    final comment = await _requestManagerDecision(
      context: context,
      reservation: reservation,
      targetStatus: targetStatus,
    );

    if (comment == null) {
      return;
    }

    try {
      await ref
          .read(meetingHallReservationActionsProvider)
          .updateReservationStatus(reservation, targetStatus, comment);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isApproval
                ? 'Réservation approuvée.'
                : isRejection
                    ? 'Réservation rejetée.'
                    : isCancellation
                        ? 'Réservation annulée.'
                        : 'Réservation mise à jour.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $error')),
      );
    }
  }

  Future<String?> _requestManagerDecision({
    required BuildContext context,
    required MeetingHallReservation reservation,
    required ReservationStatus targetStatus,
  }) async {
    return showDialog<String?>(
      context: context,
      builder: (dialogContext) => _ManagerDecisionDialog(
        reservation: reservation,
        targetStatus: targetStatus,
      ),
    );
  }
}

class _ManagerDecisionDialog extends StatefulWidget {
  const _ManagerDecisionDialog({
    required this.reservation,
    required this.targetStatus,
  });

  final MeetingHallReservation reservation;
  final ReservationStatus targetStatus;

  @override
  State<_ManagerDecisionDialog> createState() => _ManagerDecisionDialogState();
}

class _ManagerDecisionDialogState extends State<_ManagerDecisionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  bool get _isApproval => widget.targetStatus == ReservationStatus.accepted;
  bool get _isRejection => widget.targetStatus == ReservationStatus.rejected;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_message),
              if (!_isApproval) ...[
                const Gap(16),
                CommonTextInput(
                  controller: _commentController,
                  label: _isRejection ? 'Motif du rejet' : 'Motif',
                  isMultiline: true,
                  hintText: _isRejection
                      ? 'Expliquez pourquoi la demande est rejetée'
                      : 'Motif de l’annulation',
                  validator: _isRejection
                      ? (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez renseigner le motif du rejet';
                          }
                          return null;
                        }
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            if (!_isApproval && !(_formKey.currentState?.validate() ?? false)) {
              return;
            }
            Navigator.of(context).pop(_commentController.text.trim());
          },
          child: Text(_actionLabel),
        ),
      ],
    );
  }

  String get _title {
    if (_isApproval) {
      return 'Approuver la réservation ?';
    }
    if (_isRejection) {
      return 'Rejeter la réservation ?';
    }
    if (widget.reservation.status == ReservationStatus.blocked) {
      return 'Annuler le blocage ?';
    }
    return 'Annuler la réservation ?';
  }

  String get _message {
    if (_isApproval) {
      return 'La réservation "${widget.reservation.title}" sera marquée comme réservée.';
    }
    if (_isRejection) {
      return 'La réservation "${widget.reservation.title}" sera rejetée et retirée de l’agenda des réservations.';
    }
    return 'Cette période sera libérée dans l’agenda.';
  }

  String get _actionLabel {
    if (_isApproval) {
      return 'Approuver';
    }
    if (_isRejection) {
      return 'Rejeter';
    }
    return 'Confirmer';
  }
}

class _ReservedAgendaHeader extends StatelessWidget {
  final DateTime selectedDate;
  final int reservationCount;
  final VoidCallback? onCreateReservation;

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

        final action = onCreateReservation == null
            ? null
            : FilledButton.icon(
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
              if (action != null) ...[
                const Gap(12),
                action,
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleGroup),
            if (action != null) action,
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
  final bool canManageReservations;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onCancel;

  const _ReservedAgendaItem({
    required this.reservation,
    required this.isLast,
    required this.canManageReservations,
    required this.onApprove,
    required this.onReject,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final statusStyle =
        _ReservationStatusStyle.from(context, reservation.status);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 560;
        final card = _ReservedReservationCard(
          reservation: reservation,
          statusStyle: statusStyle,
          canManageReservations: canManageReservations,
          onApprove: onApprove,
          onReject: onReject,
          onCancel: onCancel,
        );

        // FOR MOBILE PHONE, WE ARE HIDING THE TIMELINE FOR BETTER UX
        if (isCompact) {
          return card;
        }

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

                    // THE LINE BETWEEN THE AGENDA TIME CHIP AND THE CARD, THE LAST CARD DOENST NEED IT
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
              Expanded(child: card),
            ],
          ),
        );
      },
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
  final bool canManageReservations;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onCancel;

  const _ReservedReservationCard({
    required this.reservation,
    required this.statusStyle,
    required this.canManageReservations,
    required this.onApprove,
    required this.onReject,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.corporateTheme;
    final duration = reservation.endTime.difference(reservation.startTime);
    final requesterLabel = reservation.userName.trim().isNotEmpty
        ? reservation.userName.trim()
        : reservation.userEmail.trim().isNotEmpty
            ? reservation.userEmail.trim()
            : reservation.userId.trim();
    final showManagerActions =
        canManageReservations && reservation.status == ReservationStatus.onHold;
    final showCancelAction = canManageReservations &&
        (reservation.status == ReservationStatus.accepted ||
            reservation.status == ReservationStatus.blocked);

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
          // Container(
          //   width: 44,
          //   height: 44,
          //   decoration: BoxDecoration(
          //     color: statusStyle.accent.withOpacity(0.14),
          //     borderRadius: BorderRadius.circular(14),
          //   ),
          //   child: Icon(
          //     statusStyle.icon,
          //     color: statusStyle.accent,
          //   ),
          // ),
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
                    if (requesterLabel.isNotEmpty)
                      _ReservationInfoChip(
                        icon: Icons.person_outline,
                        label: requesterLabel,
                      ),
                  ],
                ),
                if (showManagerActions) ...[
                  const Gap(16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Approuver'),
                      ),
                      OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Rejeter'),
                      ),
                    ],
                  ),
                ],
                if (showCancelAction) ...[
                  const Gap(16),
                  OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.event_busy_rounded),
                    label: Text(
                      reservation.status == ReservationStatus.blocked
                          ? 'Annuler le blocage'
                          : 'Annuler la réservation',
                    ),
                  ),
                ],
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
  final VoidCallback? onCreateReservation;

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
            if (onCreateReservation != null) ...[
              const Gap(18),
              FilledButton.icon(
                onPressed: onCreateReservation,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Réserver un créneau'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BlockRoomDialog extends ConsumerStatefulWidget {
  const _BlockRoomDialog({
    required this.hallId,
    required this.selectedDate,
  });

  final String hallId;
  final DateTime selectedDate;

  @override
  ConsumerState<_BlockRoomDialog> createState() => _BlockRoomDialogState();
}

class _BlockRoomDialogState extends ConsumerState<_BlockRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _startTime = TimeOfDay.now();
    _endTime = TimeOfDay(
      hour: (_startTime.hour + 1).clamp(0, 23),
      minute: _startTime.minute,
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentMeetingHallUserProvider).valueOrNull;

    return AlertDialog(
      title: const Text('Bloquer la salle'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CommonTextInput(
              controller: _reasonController,
              label: 'Motif du blocage',
              hintText: 'Maintenance, nettoyage, évènement interne...',
              isMultiline: true,
              enabled: !_isSubmitting,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez indiquer le motif du blocage';
                }
                return null;
              },
            ),
            const Gap(16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Début'),
                    subtitle: Text(_startTime.format(context)),
                    enabled: !_isSubmitting,
                    onTap: _isSubmitting
                        ? null
                        : () => _selectTime(context, isStartTime: true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Fin'),
                    subtitle: Text(_endTime.format(context)),
                    enabled: !_isSubmitting,
                    onTap: _isSubmitting
                        ? null
                        : () => _selectTime(context, isStartTime: false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: _isSubmitting || currentUser == null
              ? null
              : () => _submit(currentUser),
          icon: _isSubmitting
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.construction_rounded),
          label: const Text('Bloquer'),
        ),
      ],
    );
  }

  Future<void> _selectTime(
    BuildContext context, {
    required bool isStartTime,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (isStartTime) {
        _startTime = picked;
        _endTime = TimeOfDay(
          hour: (picked.hour + 1).clamp(0, 23),
          minute: picked.minute,
        );
      } else {
        _endTime = picked;
      }
    });
  }

  Future<void> _submit(MeetingHallUser currentUser) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final startDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (!endDateTime.isAfter(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('L’heure de fin doit être après l’heure de début.'),
        ),
      );
      return;
    }

    final reason = _reasonController.text.trim();
    final block = MeetingHallReservation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      hallId: widget.hallId,
      userId: currentUser.id,
      userName: currentUser.displayName,
      userEmail: currentUser.email,
      title: 'Salle bloquée',
      description: reason,
      startTime: startDateTime,
      endTime: endDateTime,
      status: ReservationStatus.blocked,
      createdAt: DateTime.now(),
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(meetingHallReservationActionsProvider).blockRoom(block);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salle bloquée pour cette période.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
      case ReservationStatus.cancelled:
        return _ReservationStatusStyle(
          label: 'Annulé',
          icon: Icons.event_busy_rounded,
          accent: scheme.outline,
          onAccent: scheme.onSurface,
          background: scheme.surfaceContainerLow,
          borderColor: scheme.outlineVariant,
        );
      case ReservationStatus.blocked:
        return _ReservationStatusStyle(
          label: 'Bloqué',
          icon: Icons.construction_rounded,
          accent: scheme.error,
          onAccent: scheme.onError,
          background: Color.lerp(
            scheme.surfaceContainerLow,
            scheme.error,
            isDark ? 0.18 : 0.10,
          )!,
          borderColor: scheme.error.withOpacity(isDark ? 0.42 : 0.28),
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
