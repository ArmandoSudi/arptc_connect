import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/meeting_hall_provider.dart';
import '../models/meeting_hall.dart';
import 'package:gap/gap.dart';
import '../../../widgets/content_view.dart';
import '../../../widgets/page_header.dart';
import '../widgets/create_meeting_hall_form.dart';
import 'hall_details_screen.dart';

class MeetingHallsScreen extends ConsumerWidget {
  const MeetingHallsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final meetingHalls = ref.watch(meetingHallsProvider);

    return Scaffold(
      body: ContentView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => context.pop(),
                ),
                const PageHeader(
                  title: 'Salles de réunion',
                  description: 'Gérez vos réservations de salles',
                ),
              ],
            ),
            const Gap(16),
            meetingHalls.when(
              data: (halls) {
                if (halls.isEmpty) {
                  return const Center(
                    child: Text('Aucune salle de réunion disponible.'),
                  );
                }
                return Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 4/3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: halls.length,
                    itemBuilder: (context, index) {
                      final hall = halls[index];
                      return _MeetingHallCard(hall: hall);
                    },
                  ),
                );
              },
              error: (error, stack) => Center(child: Text('Erreur : $error')),
              loading: () => const Center(child: CircularProgressIndicator()),
            )
            // Expanded(
            //   child: GridView.builder(
            //     padding: const EdgeInsets.all(16),
            //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            //       crossAxisCount: 3,
            //       childAspectRatio: 4/3,
            //       crossAxisSpacing: 16,
            //       mainAxisSpacing: 16,
            //     ),
            //     itemCount: meetingHalls.length,
            //     itemBuilder: (context, index) {
            //       final hall = meetingHalls[index];
            //       return _MeetingHallCard(hall: hall);
            //     },
            //   ),
            // ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateHallModal(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateHallModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CreateMeetingHallForm(),
    );
  }
}

class _MeetingHallCard extends StatelessWidget {
  final MeetingHall hall;

  const _MeetingHallCard({required this.hall});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => HallDetailsScreen(hall: hall),
          //   ),
          // );
          context.go('/service/meeting-hall/${hall.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.meeting_room, size: 32),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      hall.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const Gap(16),
              Text(
                'Emplacement: ${hall.location}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Gap(8),
              Text(
                'Capacité: ${hall.capacity} personnes',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Gap(8),
              Text(
                hall.description,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
