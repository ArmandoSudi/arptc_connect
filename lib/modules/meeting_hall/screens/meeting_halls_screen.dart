import 'package:arptc_connect/widgets/page_header_simple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/meeting_hall_access_provider.dart';
import '../providers/meeting_hall_provider.dart';
import '../models/meeting_hall.dart';
import 'package:gap/gap.dart';
import '../../../widgets/content_view.dart';
import '../widgets/create_meeting_hall_form.dart';

class MeetingHallsScreen extends ConsumerWidget {
  const MeetingHallsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingHalls = ref.watch(meetingHallsProvider);
    final roleAsync = ref.watch(currentMeetingHallRoleProvider);
    final role = roleAsync.valueOrNull ?? MeetingHallRole.none;

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
      body: ContentView(
        maxWidth: 1440,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeaderSimple(
              title: 'Salles de réunion',
            ),
            const Gap(16),
            meetingHalls.when(
              data: (halls) {
                if (halls.isEmpty) {
                  return const Center(
                    child: Text('Aucune salle de réunion disponible.'),
                  );
                }
                final isPhoneLayout = MediaQuery.sizeOf(context).width < 600;
                return Expanded(
                  child: isPhoneLayout
                      ? _MeetingHallsList(
                          halls: halls,
                          canManage: role.canManageHalls,
                          onEdit: (hall) => _showCreateHallModal(
                            context,
                            existingHall: hall,
                          ),
                          onDelete: (hall) =>
                              _confirmDeleteHall(context, ref, hall),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _getCrossAxisCount(context),
                            childAspectRatio: _getChildAspectRatio(context),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: halls.length,
                          itemBuilder: (context, index) {
                            final hall = halls[index];
                            return _MeetingHallCard(
                              hall: hall,
                              canManage: role.canManageHalls,
                              onEdit: () => _showCreateHallModal(
                                context,
                                existingHall: hall,
                              ),
                              onDelete: () =>
                                  _confirmDeleteHall(context, ref, hall),
                            );
                          },
                        ),
                );
              },
              error: (error, stack) => Center(child: Text('Erreur : $error')),
              loading: () => const Center(child: CircularProgressIndicator()),
            )
          ],
        ),
      ),
      floatingActionButton: role.canManageHalls
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateHallModal(context),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une salle'),
            )
          : null,
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 3;
    if (width > 800) return 2;
    if (width > 600) return 2;
    return 2;
  }

  double _getChildAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 1;
    if (width > 800) return 0.8;
    if (width > 600) return 0.8;
    return 0.8;
  }

  void _showCreateHallModal(
    BuildContext context, {
    MeetingHall? existingHall,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CreateMeetingHallForm(existingHall: existingHall),
    );
  }

  Future<void> _confirmDeleteHall(
    BuildContext context,
    WidgetRef ref,
    MeetingHall hall,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer la salle ?'),
        content: Text(
          'La salle "${hall.name}" sera supprimée. Cette action doit être utilisée uniquement si elle ne doit plus être disponible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(meetingHallActionsProvider).deleteHall(hall.id);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salle supprimée.')),
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
}

class _MeetingHallsList extends StatelessWidget {
  final List<MeetingHall> halls;
  final bool canManage;
  final ValueChanged<MeetingHall> onEdit;
  final ValueChanged<MeetingHall> onDelete;

  const _MeetingHallsList({
    required this.halls,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: halls.length,
      separatorBuilder: (_, __) => const Gap(10),
      itemBuilder: (context, index) {
        final hall = halls[index];
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: const CircleAvatar(
              child: Icon(Icons.meeting_room_outlined),
            ),
            title: Text(
              hall.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('${hall.capacity} personnes'),
            trailing: canManage
                ? _HallActionsMenu(
                    onEdit: () => onEdit(hall),
                    onDelete: () => onDelete(hall),
                  )
                : const Icon(Icons.chevron_right),
            onTap: () => context.go('/service/meeting-hall/${hall.id}'),
          ),
        );
      },
    );
  }
}

class _MeetingHallCard extends StatelessWidget {
  final MeetingHall hall;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MeetingHallCard({
    required this.hall,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          context.go('/service/meeting-hall/${hall.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.meeting_room, size: 48),
                  if (canManage)
                    _HallActionsMenu(
                      onEdit: onEdit,
                      onDelete: onDelete,
                    ),
                ],
              ),
              const Gap(8),
              Text(
                hall.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Gap(16),
              Text(
                hall.description,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Gap(16),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      hall.location,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Gap(8),
              Row(
                children: [
                  const Icon(Icons.people_outline),
                  const Gap(8),
                  Text(
                    '${hall.capacity} personnes',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HallActionsMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HallActionsMenu({
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_HallAction>(
      tooltip: 'Actions',
      onSelected: (action) {
        switch (action) {
          case _HallAction.edit:
            onEdit();
            break;
          case _HallAction.delete:
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _HallAction.edit,
          child: Text('Modifier'),
        ),
        PopupMenuItem(
          value: _HallAction.delete,
          child: Text('Supprimer'),
        ),
      ],
    );
  }
}

enum _HallAction {
  edit,
  delete,
}
