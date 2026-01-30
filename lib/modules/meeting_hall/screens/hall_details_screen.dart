import 'dart:developer';

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
        title: Text("Hall Name"),
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
                    .where((reservation) => isSameDay(reservation.startTime, day))
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Créneaux horaires',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  'Jour sélectionné: ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const Gap(8),
          Expanded(
            child: _TimeSlotList(
              hallId: widget.hallId,
              selectedDate: _selectedDay,
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

  void _showReservationDialog(BuildContext context, ) {
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
        title: Text("widget.hall.name"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Emplacement: widget.hall.location '),
            const Gap(8),
            Text('Capacité: widget.hall.capacity personnes'),
            const Gap(8),
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

class _TimeSlotList extends ConsumerWidget {
  final String hallId;
  final DateTime selectedDate;

  const _TimeSlotList({
    required this.hallId,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(hallDateReservationsProvider((
      hallId: hallId,
      date: selectedDate,
    )));

    return Scaffold(
      body: reservationsAsync.when(
        data: (reservations) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 10, // 24 hours
            itemBuilder: (context, hour) {

              hour += 8; // Adjust to start from 8 AM
              if (hour >= 24) {
                return const SizedBox.shrink(); // Skip hours after 8 PM
              }

              final timeSlotReservations = reservations.where((res) =>
                  res.startTime.hour <= hour && res.endTime.hour > hour).toList();

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: timeSlotReservations.isEmpty
                    ? Colors.green.shade50 // Available
                    : _getStatusColor(timeSlotReservations.first.status),
                child: ListTile(
                  leading: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  title: timeSlotReservations.isEmpty
                      ? const Text('Disponible')
                      : Text(
                          timeSlotReservations.first.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                  subtitle: timeSlotReservations.isEmpty
                      ? null
                      : Text(
                          timeSlotReservations.first.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  trailing: timeSlotReservations.isEmpty
                      ? const Icon(Icons.check_circle_outline, color: Colors.green)
                      : _getStatusIcon(timeSlotReservations.first.status),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          log('Error loading reservations: $error');
          return Center(
            child: Text('Error loading reservations: $error'),
          );
        },
      ),
    );
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.onHold:
        return Colors.orange.shade100;
      case ReservationStatus.accepted:
        return Colors.red.shade100;
      case ReservationStatus.rejected:
        return Colors.grey.shade100;
    }
  }

  Widget _getStatusIcon(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.onHold:
        return const Icon(Icons.pending, color: Colors.orange);
      case ReservationStatus.accepted:
        return const Icon(Icons.event_busy, color: Colors.red);
      case ReservationStatus.rejected:
        return const Icon(Icons.cancel_outlined, color: Colors.grey);
    }
  }
}
