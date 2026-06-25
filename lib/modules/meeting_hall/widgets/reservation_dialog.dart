import 'package:arptc_connect/modules/meeting_hall/repositories/reservation_repository.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reservation.dart';
import '../models/reservation_status.dart';
import '../providers/meeting_hall_access_provider.dart';

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
  bool _isSubmitting = false;

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
    final userAsync = ref.watch(currentMeetingHallUserProvider);
    final currentUser = userAsync.valueOrNull;
    final canCreate = currentUser?.role.canCreateReservation ?? false;

    return AlertDialog(
      title: const Text('Nouvelle réservation'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!canCreate) ...[
                const Text(
                  'Votre rôle actuel ne permet pas de créer une réservation.',
                ),
                const SizedBox(height: 16),
              ],
              CommonTextInput(
                label: 'Titre',
                type: CommonTextInputType.text,
                controller: _titleController,
                enabled: canCreate && !_isSubmitting,
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
                enabled: canCreate && !_isSubmitting,
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
                      enabled: canCreate && !_isSubmitting,
                      onTap: canCreate && !_isSubmitting
                          ? () => _selectTime(context, true)
                          : null,
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Heure de fin'),
                      subtitle: Text(_endTime.format(context)),
                      enabled: canCreate && !_isSubmitting,
                      onTap: canCreate && !_isSubmitting
                          ? () => _selectTime(context, false)
                          : null,
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
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: canCreate && !_isSubmitting && currentUser != null
              ? () => _submitReservation(currentUser)
              : null,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Soumettre'),
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
            hour: (picked.hour + 1).clamp(0, 23),
            minute: picked.minute,
          );
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _submitReservation(MeetingHallUser currentUser) async {
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

      if (!endDateTime.isAfter(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('L’heure de fin doit être après l’heure de début.'),
          ),
        );
        return;
      }

      final reservation = MeetingHallReservation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        hallId: widget.hallId,
        userId: currentUser.id,
        userName: currentUser.displayName,
        userEmail: currentUser.email,
        title: _titleController.text,
        description: _descriptionController.text,
        startTime: startDateTime,
        endTime: endDateTime,
        status: ReservationStatus.onHold,
        createdAt: DateTime.now(),
      );

      setState(() {
        _isSubmitting = true;
      });

      try {
        await ref
            .read(meetingHallReservationActionsProvider)
            .createReservation(reservation);
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation soumise pour validation.'),
          ),
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
}
