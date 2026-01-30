import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reservation_provider.dart';
import '../models/reservation_status.dart';

class _DailyScheduleView extends ConsumerWidget {
  final String hallId;
  final DateTime selectedDate;

  const _DailyScheduleView({
    required this.hallId,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservations = ref
        .watch(reservationsProvider.notifier)
        .getReservationsByDate(hallId, selectedDate);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 24, // 24 hours
      itemBuilder: (context, hour) {
        final timeSlotReservations = reservations.where((res) =>
            res.startTime.hour <= hour && res.endTime.hour > hour).toList();

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: timeSlotReservations.isEmpty
              ? Colors.green.shade50
              : _getStatusColor(timeSlotReservations.first.status),
          child: ListTile(
            title: Text('${hour.toString().padLeft(2, '0')}:00'),
            subtitle: timeSlotReservations.isEmpty
                ? const Text('Available')
                : Text(
                    timeSlotReservations.first.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        );
      },
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
}
