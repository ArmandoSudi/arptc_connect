import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/meeting_hall_repository.dart';
import '../models/meeting_hall.dart';
import 'meeting_hall_access_provider.dart';

// Provider for streaming all meeting halls
final meetingHallsProvider = StreamProvider<List<MeetingHall>>((ref) {
  final repository = ref.watch(meetingHallRepositoryProvider);
  return repository.getMeetingHalls();
});

// Provider for managing meeting hall operations
final meetingHallActionsProvider = Provider((ref) {
  final repository = ref.watch(meetingHallRepositoryProvider);
  final role = ref.watch(currentMeetingHallRoleProvider).valueOrNull ??
      MeetingHallRole.none;

  return MeetingHallActions(
    createHall: (hall) {
      _assertCanManageHalls(role);
      return repository.addMeetingHall(hall);
    },
    updateHall: (hall) {
      _assertCanManageHalls(role);
      return repository.updateMeetingHall(hall);
    },
    deleteHall: (id) {
      _assertCanManageHalls(role);
      return repository.deleteMeetingHall(id);
    },
    getHallById: (id) => repository.getMeetingHallById(id),
  );
});

// Class to hold all meeting hall actions
class MeetingHallActions {
  final Future<void> Function(MeetingHall hall) createHall;
  final Future<void> Function(MeetingHall hall) updateHall;
  final Future<void> Function(String id) deleteHall;
  final Future<MeetingHall?> Function(String id) getHallById;

  const MeetingHallActions({
    required this.createHall,
    required this.updateHall,
    required this.deleteHall,
    required this.getHallById,
  });
}

// Provider for a specific meeting hall
final selectedMeetingHallProvider =
    StreamProvider.family<MeetingHall?, String>((ref, id) {
  final repository = ref.watch(meetingHallRepositoryProvider);
  return repository.watchMeetingHallById(id);
});

void _assertCanManageHalls(MeetingHallRole role) {
  if (!role.canManageHalls) {
    throw StateError('Only Meeting Hall managers can manage rooms.');
  }
}
