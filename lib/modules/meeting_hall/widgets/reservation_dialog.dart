import 'package:arptc_connect/modules/meeting_hall/repositories/reservation_repository.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reservation.dart';
import '../models/reservation_status.dart';

class ReservationDialog extends ConsumerStatefulWidget {
  final String hallId;
  final DateTime selectedDate;

  const ReservationDialog({
    super.key,
    required this.hallId,
    required this.selectedDate,
  });

  @override
  ConsumerState<ReservationDialog> createState() => _ReservationDialogState();
}

class _ReservationDialogState extends ConsumerState<ReservationDialog> {
  final _formKey = GlobalKey<FormState>();
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _startTime = TimeOfDay.now();
    _endTime = TimeOfDay(hour: _startTime.hour + 1, minute: _startTime.minute);
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvelle réservation'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CommonTextInput(
                label: 'Titre',
                type: CommonTextInputType.text,
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Entrez le titre de la réunion',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un titre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CommonTextInput(
                label: 'Description',
                type: CommonTextInputType.text,
                isMultiline: true,
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Entrez la description de la réunion',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Heure de début'),
                      subtitle: Text(_startTime.format(context)),
                      onTap: () => _selectTime(context, true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Heure de fin'),
                      subtitle: Text(_endTime.format(context)),
                      onTap: () => _selectTime(context, false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _submitReservation,
          child: const Text('Soumettre'),
        ),
      ],
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          // Automatically set end time to 1 hour after start time
          _endTime = TimeOfDay(
            hour: picked.hour + 1,
            minute: picked.minute,
          );
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _submitReservation() {
    if (_formKey.currentState!.validate()) {
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

      final reservation = MeetingHallReservation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        hallId: widget.hallId,
        userId: 'current_user_id', // This should come from auth service
        title: _titleController.text,
        description: _descriptionController.text,
        startTime: startDateTime,
        endTime: endDateTime,
        status: ReservationStatus.onHold,
        createdAt: DateTime.now(),
      );

      ref.read(reservationRepositoryProvider).addReservation(reservation);
      Navigator.of(context).pop();
    }
  }
}
