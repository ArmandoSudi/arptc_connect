import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meeting_hall.dart';
import '../providers/meeting_hall_provider.dart';
import '../../../widgets/common_text_input.dart';

class CreateMeetingHallForm extends ConsumerStatefulWidget {
  const CreateMeetingHallForm({super.key});

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

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    super.dispose();
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
                      'Créer une nouvelle salle',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CommonTextInput(
                  controller: _nameController,
                  label: 'Nom de la salle',
                  hintText: 'Ex: Salle de Réunion 6ème',
                  type: CommonTextInputType.text,
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
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Créer la salle'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newHall = MeetingHall(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        location: _locationController.text,
        capacity: int.parse(_capacityController.text),
        description: _descriptionController.text,
      );

      //TODO Hook up the provider to add the new hall to firestore
      // ref.read(meetingHallsProvider.notifier).addHall(newHall);
      ref.read(meetingHallActionsProvider).createHall(newHall);
      Navigator.pop(context);
    }
  }
}
