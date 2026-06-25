import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meeting_hall.dart';
import '../providers/meeting_hall_provider.dart';
import '../../../widgets/common_text_input.dart';

class CreateMeetingHallForm extends ConsumerStatefulWidget {
  const CreateMeetingHallForm({
    super.key,
    this.existingHall,
  });

  final MeetingHall? existingHall;

  @override
  ConsumerState<CreateMeetingHallForm> createState() =>
      _CreateMeetingHallFormState();
}

class _CreateMeetingHallFormState extends ConsumerState<CreateMeetingHallForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final hall = widget.existingHall;
    if (hall == null) {
      return;
    }
    _nameController.text = hall.name;
    _locationController.text = hall.location;
    _capacityController.text = hall.capacity.toString();
    _descriptionController.text = hall.description;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Card(
        margin: const EdgeInsets.all(0),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      widget.existingHall == null
                          ? 'Créer une nouvelle salle'
                          : 'Modifier la salle',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed:
                          _isSubmitting ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CommonTextInput(
                  controller: _nameController,
                  label: 'Nom de la salle',
                  hintText: 'Ex: Salle de Réunion 6ème',
                  type: CommonTextInputType.text,
                  enabled: !_isSubmitting,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un nom';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CommonTextInput(
                  controller: _locationController,
                  label: 'Emplacement',
                  hintText: 'Ex: 6ème étage',
                  type: CommonTextInputType.text,
                  enabled: !_isSubmitting,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer l\'emplacement';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CommonTextInput(
                  controller: _capacityController,
                  label: 'Capacité',
                  hintText: 'Nombre de personnes',
                  type: CommonTextInputType.number,
                  enabled: !_isSubmitting,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer la capacité';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Veuillez entrer un nombre valide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CommonTextInput(
                  controller: _descriptionController,
                  label: 'Description',
                  hintText: 'Description de la salle',
                  // maxLines: 3,
                  type: CommonTextInputType.text,
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  child: _isSubmitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.existingHall == null
                              ? 'Créer la salle'
                              : 'Enregistrer les modifications',
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final existingHall = widget.existingHall;
      final hall = existingHall == null
          ? MeetingHall(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: _nameController.text.trim(),
              location: _locationController.text.trim(),
              capacity: int.parse(_capacityController.text),
              description: _descriptionController.text.trim(),
            )
          : existingHall.copyWith(
              name: _nameController.text.trim(),
              location: _locationController.text.trim(),
              capacity: int.parse(_capacityController.text),
              description: _descriptionController.text.trim(),
            );

      setState(() {
        _isSubmitting = true;
      });

      try {
        if (existingHall == null) {
          await ref.read(meetingHallActionsProvider).createHall(hall);
        } else {
          await ref.read(meetingHallActionsProvider).updateHall(hall);
        }
        if (!mounted) {
          return;
        }
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existingHall == null ? 'Salle créée.' : 'Salle mise à jour.',
            ),
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
