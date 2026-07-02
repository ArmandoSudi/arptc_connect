import 'dart:developer';
import 'package:arptc_connect/modules/notifications/domain/notification_event.dart';
import 'package:arptc_connect/modules/notifications/domain/notification_target.dart';
import 'package:arptc_connect/utils/firestore_client.dart';
import 'package:arptc_connect/utils/firestore_filter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation.dart';
import '../models/reservation_status.dart';
import '../providers/meeting_hall_access_provider.dart';

class ReservationRepository {
  final String path = 'meeting_hall_reservations';
  static const String _notificationPath = 'notificationEvents';
  static const String _moduleKey = 'meetinghall';
  final FirestoreClient firestoreClient;

  ReservationRepository(this.firestoreClient);

  Stream<List<MeetingHallReservation>> getReservations() {
    try {
      return firestoreClient.streamAll(collection: path).map((results) =>
          results
              .map((item) => MeetingHallReservation.fromJson(
                  {...item.data, 'id': item.id}))
              .toList());
    } catch (err, stckTrace) {
      log("Error streaming reservations: $err");
      log("StackTrace: $stckTrace");
      throw Exception(err);
    }
  }

  Future<MeetingHallReservation> getReservationsByHall(String hallId) async {
    try {
      final result =
          await firestoreClient.fetchById(collection: path, id: hallId);
      return MeetingHallReservation.fromJson(result.data);
    } catch (err, stckTrace) {
      log("Error fetching hall reservations: $err");
      log("StackTrace: $stckTrace");
      throw Exception(err);
    }
  }

  Future<List<MeetingHallReservation>> getReservationsByHallAndDate(
      String hallId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final results = await firestoreClient.fetchWhereWithFilters(
        collection: path,
        filters: [
          FirestoreFilter.equals('hallId', hallId),
          FirestoreFilter.range(
            'startTime',
            greaterThanOrEqual: Timestamp.fromDate(startOfDay),
            lessThan: Timestamp.fromDate(endOfDay),
          ),
        ],
      );

      return results
          .map((item) =>
              MeetingHallReservation.fromJson({...item.data, 'id': item.id}))
          .toList();
    } catch (err, stckTrace) {
      log("Error fetching reservations by hall and date: $err");
      log("StackTrace: $stckTrace");
      throw Exception(err);
    }
  }

  Stream<List<MeetingHallReservation>> watchReservationsByHallAndDate(
    String hallId,
    DateTime date,
  ) {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      return firestoreClient.streamWhereWithFilters(
        collection: path,
        filters: [
          FirestoreFilter.equals('hallId', hallId),
          FirestoreFilter.range(
            'startTime',
            greaterThanOrEqual: Timestamp.fromDate(startOfDay),
            lessThan: Timestamp.fromDate(endOfDay),
          ),
        ],
      ).map((results) {
        final reservations = results
            .map((item) =>
                MeetingHallReservation.fromJson({...item.data, 'id': item.id}))
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
        return reservations;
      });
    } catch (err, stckTrace) {
      log("Error streaming reservations by hall and date: $err");
      log("StackTrace: $stckTrace");
      throw Exception(err);
    }
  }

  Future<MeetingHallReservation> getReservationById(String id) async {
    try {
      final result = await firestoreClient.fetchById(collection: path, id: id);
      return MeetingHallReservation.fromJson({...result.data, 'id': result.id});
    } catch (err) {
      throw Exception(err);
    }
  }

  Future<void> addReservation(MeetingHallReservation reservation) async {
    try {
      await _assertNoBlockingConflict(
        hallId: reservation.hallId,
        startTime: reservation.startTime,
        endTime: reservation.endTime,
      );

      final reservationRef = firestoreClient.firestore.collection(path).doc();
      final batch = firestoreClient.firestore.batch();
      batch.set(reservationRef, _reservationCreateData(reservation));

      if (reservation.status == ReservationStatus.onHold) {
        _addReservationRequestNotifications(
          batch: batch,
          reservationId: reservationRef.id,
          reservation: reservation,
        );
      }

      await batch.commit();
    } catch (err) {
      throw Exception(err);
    }
  }

  Future<void> blockRoom(MeetingHallReservation block) async {
    try {
      await _assertNoBlockingConflict(
        hallId: block.hallId,
        startTime: block.startTime,
        endTime: block.endTime,
      );

      await firestoreClient.add(
        collection: path,
        data: _reservationCreateData(block),
      );
    } catch (err) {
      throw Exception(err);
    }
  }

  // Future<void> updateReservation(MeetingHallReservation reservation) async {
  //   try {
  //     await firestoreClient.update(
  //       collection: path,
  //       id: reservation.id,
  //       data: {
  //         ...reservation.toJson(),
  //         'startTime': Timestamp.fromDate(reservation.startTime),
  //         'endTime': Timestamp.fromDate(reservation.endTime),
  //       },
  //     );
  //   } catch (err) {
  //     throw Exception(err);
  //   }
  // }

  Future<void> updateReservationStatus({
    required MeetingHallReservation reservation,
    required ReservationStatus status,
    required MeetingHallUser actor,
    String comment = '',
  }) async {
    try {
      if (status == ReservationStatus.accepted) {
        await _assertNoBlockingConflict(
          hallId: reservation.hallId,
          startTime: reservation.startTime,
          endTime: reservation.endTime,
          excludeReservationId: reservation.id,
        );
      }

      final reservationRef =
          firestoreClient.firestore.collection(path).doc(reservation.id);
      final batch = firestoreClient.firestore.batch();
      final update = <String, dynamic>{
        'status': status.value,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final cleanedComment = comment.trim();
      if (status == ReservationStatus.rejected) {
        update['rejectionReason'] = cleanedComment;
      }
      if (status == ReservationStatus.cancelled) {
        update['cancelReason'] = cleanedComment;
      }

      batch.update(reservationRef, update);
      if (status == ReservationStatus.accepted ||
          status == ReservationStatus.rejected ||
          status == ReservationStatus.cancelled) {
        _addRequesterStatusNotification(
          batch: batch,
          reservation: reservation,
          status: status,
          actor: actor,
          comment: cleanedComment,
        );
      }

      await batch.commit();
    } catch (err) {
      throw Exception(err);
    }
  }

  Future<void> deleteReservation(String id) async {
    try {
      await firestoreClient.delete(
        collection: path,
        id: id,
      );
    } catch (err) {
      throw Exception(err);
    }
  }

  // Future<bool> hasConflictingReservations(String hallId, DateTime startTime, DateTime endTime, {String? excludeReservationId}) async {
  //   try {
  //     final results = await firestoreClient.fetchWhereWithFilters(
  //       collection: path,
  //       filters: [
  //         Filter('hallId', isEqualTo: hallId),
  //         Filter('status', isEqualTo: ReservationStatus.accepted.value),
  //         Filter('startTime', isLessThan: Timestamp.fromDate(endTime)),
  //         Filter('endTime', isGreaterThan: Timestamp.fromDate(startTime)),
  //       ],
  //     );
  //
  //     return results.any((doc) {
  //       if (excludeReservationId != null && doc.id == excludeReservationId) {
  //         return false;
  //       }
  //       return true;
  //     });
  //   } catch (err) {
  //     throw Exception(err);
  //   }
  // }

  Map<String, dynamic> _reservationCreateData(
    MeetingHallReservation reservation,
  ) {
    return {
      'hallId': reservation.hallId,
      'userId': reservation.userId,
      'userName': reservation.userName,
      'userEmail': reservation.userEmail,
      'title': reservation.title,
      'description': reservation.description,
      'rejectionReason': reservation.rejectionReason,
      'cancelReason': reservation.cancelReason,
      'status': reservation.status.value,
      'startTime': Timestamp.fromDate(reservation.startTime),
      'endTime': Timestamp.fromDate(reservation.endTime),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> _assertNoBlockingConflict({
    required String hallId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeReservationId,
  }) async {
    final conflicts = await _findOverlappingBlockingReservations(
      hallId: hallId,
      startTime: startTime,
      endTime: endTime,
      excludeReservationId: excludeReservationId,
    );
    if (conflicts.isNotEmpty) {
      final firstConflict = conflicts.first;
      if (firstConflict.status == ReservationStatus.blocked) {
        throw StateError(
          'Cette salle est bloquée pendant cette période.',
        );
      }
      throw StateError(
        'Cette salle est déjà réservée pendant cette période.',
      );
    }
  }

  Future<List<MeetingHallReservation>> _findOverlappingBlockingReservations({
    required String hallId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeReservationId,
  }) async {
    final results = await firestoreClient.fetchWhereWithFilters(
      collection: path,
      filters: [
        FirestoreFilter.equals('hallId', hallId),
        FirestoreFilter.range(
          'startTime',
          lessThan: Timestamp.fromDate(endTime),
        ),
      ],
    );

    return results
        .map((item) =>
            MeetingHallReservation.fromJson({...item.data, 'id': item.id}))
        .where((reservation) {
      if (excludeReservationId != null &&
          reservation.id == excludeReservationId) {
        return false;
      }
      return reservation.status.blocksAvailability &&
          reservation.endTime.isAfter(startTime);
    }).toList();
  }

  void _addReservationRequestNotifications({
    required WriteBatch batch,
    required String reservationId,
    required MeetingHallReservation reservation,
  }) {
    final route = _hallDetailsRoute(
      reservation,
      reservationId: reservationId,
    );
    batch.set(
      firestoreClient.firestore.collection(_notificationPath).doc(),
      NotificationEvent(
        id: '',
        eventType: 'meeting_hall.reservation_requested',
        moduleKey: _moduleKey,
        title: 'Demande de réservation de salle',
        body:
            '${reservation.userName} a soumis une demande pour "${reservation.title}" le ${_formatDate(reservation.startTime)}.',
        entityType: 'meetingHallReservation',
        entityId: reservationId,
        route: route,
        createdByUserId: reservation.userId,
        createdByName: reservation.userName,
        createdByEmail: reservation.userEmail,
        target: NotificationTarget.moduleRole(
          moduleKey: _moduleKey,
          roles: const ['MANAGER'],
        ),
      ).toFirestore(),
    );
  }

  void _addRequesterStatusNotification({
    required WriteBatch batch,
    required MeetingHallReservation reservation,
    required ReservationStatus status,
    required MeetingHallUser actor,
    required String comment,
  }) {
    final route = _hallDetailsRoute(
      reservation,
      reservationId: reservation.id,
    );
    final statusCopy = _statusNotificationCopy(
      reservation: reservation,
      status: status,
      comment: comment,
    );

    batch.set(
      firestoreClient.firestore.collection(_notificationPath).doc(),
      NotificationEvent(
        id: '',
        eventType: 'meeting_hall.reservation_${status.value.toLowerCase()}',
        moduleKey: _moduleKey,
        title: statusCopy.title,
        body: statusCopy.body,
        entityType: 'meetingHallReservation',
        entityId: reservation.id,
        route: route,
        createdByUserId: actor.id,
        createdByName: actor.displayName,
        createdByEmail: actor.email,
        target: NotificationTarget.users(
          userIds: [reservation.userId],
          userEmails: [reservation.userEmail],
        ),
      ).toFirestore(),
    );
  }

  String _hallDetailsRoute(
    MeetingHallReservation reservation, {
    String? reservationId,
  }) {
    final date = _formatIsoDate(reservation.startTime);
    final safeReservationId = (reservationId ?? reservation.id).trim();
    return Uri(
      path: '/service/meeting-hall/${reservation.hallId}',
      queryParameters: {
        'date': date,
        if (safeReservationId.isNotEmpty) 'reservationId': safeReservationId,
      },
    ).toString();
  }

  String _formatIsoDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  _StatusNotificationCopy _statusNotificationCopy({
    required MeetingHallReservation reservation,
    required ReservationStatus status,
    required String comment,
  }) {
    switch (status) {
      case ReservationStatus.accepted:
        return _StatusNotificationCopy(
          title: 'Réservation approuvée',
          body: 'Votre réservation "${reservation.title}" a été approuvée.',
        );
      case ReservationStatus.rejected:
        final reason = comment.isEmpty ? '' : ' Motif: $comment';
        return _StatusNotificationCopy(
          title: 'Réservation rejetée',
          body:
              'Votre réservation "${reservation.title}" a été rejetée.$reason',
        );
      case ReservationStatus.cancelled:
        final reason = comment.isEmpty ? '' : ' Motif: $comment';
        return _StatusNotificationCopy(
          title: 'Réservation annulée',
          body:
              'Votre réservation "${reservation.title}" a été annulée.$reason',
        );
      case ReservationStatus.onHold:
      case ReservationStatus.blocked:
        return _StatusNotificationCopy(
          title: 'Réservation mise à jour',
          body: 'Votre réservation "${reservation.title}" a été mise à jour.',
        );
    }
  }
}

class _StatusNotificationCopy {
  const _StatusNotificationCopy({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  return ReservationRepository(ref.read(firestoreClientProvider));
});

// Provider for streaming all reservations
final reservationsStreamProvider =
    StreamProvider<List<MeetingHallReservation>>((ref) {
  final repository = ref.watch(reservationRepositoryProvider);
  return repository.getReservations();
});

// Provider for streaming reservations by hall
final hallReservationsProvider =
    FutureProvider.family<MeetingHallReservation, String>((ref, hallId) {
  final repository = ref.watch(reservationRepositoryProvider);
  return repository.getReservationsByHall(hallId);
});

// Provider for streaming reservations by hall and date
final hallDateReservationsProvider = StreamProvider.family<
    List<MeetingHallReservation>,
    ({String hallId, DateTime date})>((ref, params) {
  final repository = ref.watch(reservationRepositoryProvider);
  return repository.watchReservationsByHallAndDate(params.hallId, params.date);
});

final meetingHallReservationActionsProvider =
    Provider<MeetingHallReservationActions>((ref) {
  final repository = ref.watch(reservationRepositoryProvider);
  final role = ref.watch(currentMeetingHallRoleProvider).valueOrNull ??
      MeetingHallRole.none;
  final currentUser = ref.watch(currentMeetingHallUserProvider).valueOrNull;

  return MeetingHallReservationActions(
    createReservation: (reservation) {
      if (!role.canCreateReservation ||
          reservation.status != ReservationStatus.onHold) {
        throw StateError(
          'Only Meeting Hall users and managers can create reservations.',
        );
      }
      return repository.addReservation(reservation);
    },
    blockRoom: (block) {
      if (!role.canManageReservations ||
          block.status != ReservationStatus.blocked) {
        throw StateError(
          'Only Meeting Hall managers can block rooms.',
        );
      }
      return repository.blockRoom(block);
    },
    updateReservationStatus: (reservation, status, comment) {
      if (!role.canManageReservations || currentUser == null) {
        throw StateError(
          'Only Meeting Hall managers can validate reservations.',
        );
      }
      return repository.updateReservationStatus(
        reservation: reservation,
        status: status,
        actor: currentUser,
        comment: comment,
      );
    },
    deleteReservation: (id) {
      if (!role.canManageReservations) {
        throw StateError(
          'Only Meeting Hall managers can delete reservations.',
        );
      }
      return repository.deleteReservation(id);
    },
  );
});

class MeetingHallReservationActions {
  const MeetingHallReservationActions({
    required this.createReservation,
    required this.blockRoom,
    required this.updateReservationStatus,
    required this.deleteReservation,
  });

  final Future<void> Function(MeetingHallReservation reservation)
      createReservation;
  final Future<void> Function(MeetingHallReservation block) blockRoom;
  final Future<void> Function(
    MeetingHallReservation reservation,
    ReservationStatus status,
    String comment,
  ) updateReservationStatus;
  final Future<void> Function(String id) deleteReservation;
}
