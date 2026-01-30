import 'dart:developer';
import 'package:arptc_connect/utils/firestore_client.dart';
import 'package:arptc_connect/utils/firestore_filter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation.dart';
import '../models/reservation_status.dart';

class ReservationRepository {
  final String path = 'meeting_hall_reservations';
  final FirestoreClient firestoreClient;

  ReservationRepository(this.firestoreClient);

  Stream<List<MeetingHallReservation>> getReservations() {
    try {
      return firestoreClient.streamAll(collection: path).map((results) =>
        results.map((item) => MeetingHallReservation.fromJson({...item.data, 'id': item.id})).toList()
      );
    } catch (err, stckTrace) {
      log("Error streaming reservations: $err");
      log("StackTrace: $stckTrace");
      throw Exception(err);
    }
  }

  Future<MeetingHallReservation> getReservationsByHall(String hallId) async {
    try {
      final result = await firestoreClient.fetchById(collection: path, id: hallId);
      return MeetingHallReservation.fromJson(result.data);
    } catch (err, stckTrace) {
      log("Error fetching hall reservations: $err");
      log("StackTrace: $stckTrace");
      throw Exception(err);
    }
  }

  Future<List<MeetingHallReservation>> getReservationsByHallAndDate(String hallId, DateTime date) async {
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
          .map((item) => MeetingHallReservation.fromJson({...item.data, 'id': item.id}))
          .toList();
    } catch (err, stckTrace) {
      log("Error fetching reservations by hall and date: $err");
      log("StackTrace: $stckTrace");
      throw Exception(err);
    }
  }

  // Stream<List<MeetingHallReservation>> getReservationsByDate(String hallId, DateTime date) {
  //   try {
  //     final startOfDay = DateTime(date.year, date.month, date.day);
  //     final endOfDay = startOfDay.add(const Duration(days: 1));
  //
  //     return firestoreClient.streamWhereWithFilters(
  //       collection: path,
  //       filters: [
  //         Filter('hallId', isEqualTo: hallId),
  //         Filter('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay)),
  //         Filter('startTime', isLessThan: Timestamp.fromDate(endOfDay)),
  //       ],
  //     ).map((results) =>
  //       results.map((item) => MeetingHallReservation.fromJson({...item.data, 'id': item.id})).toList()
  //     );
  //   } catch (err, stckTrace) {
  //     log("Error streaming date reservations: $err");
  //     log("StackTrace: $stckTrace");
  //     throw Exception(err);
  //   }
  // }

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
      await firestoreClient.add(
        collection: path,
        data: {
          ...reservation.toJson(),
          'startTime': Timestamp.fromDate(reservation.startTime),
          'endTime': Timestamp.fromDate(reservation.endTime),
          'createdAt': Timestamp.fromDate(DateTime.now()),
        },
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

  Future<void> updateReservationStatus(String id, ReservationStatus status) async {
    try {
      await firestoreClient.update(
        collection: path,
        data: {'status': status.value},
      );
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
}

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  return ReservationRepository(ref.read(firestoreClientProvider));
});


// Provider for streaming all reservations
final reservationsStreamProvider = StreamProvider<List<MeetingHallReservation>>((ref) {
  final repository = ref.watch(reservationRepositoryProvider);
  return repository.getReservations();
});

// Provider for streaming reservations by hall
final hallReservationsProvider = FutureProvider.family<MeetingHallReservation, String>((ref, hallId) {
  final repository = ref.watch(reservationRepositoryProvider);
  return repository.getReservationsByHall(hallId);
});

// Provider for getting reservations by hall and date
final hallDateReservationsProvider = FutureProvider.family<List<MeetingHallReservation>, ({String hallId, DateTime date})>((ref, params) {
  final repository = ref.watch(reservationRepositoryProvider);
  return repository.getReservationsByHallAndDate(params.hallId, params.date);
});
