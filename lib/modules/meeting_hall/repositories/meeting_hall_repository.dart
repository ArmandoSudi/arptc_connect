import 'dart:developer';
import 'package:arptc_connect/utils/firestore_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meeting_hall.dart';

class MeetingHallRepository {
  final String path = 'meeting_halls';
  final FirestoreClient firestoreClient;

  MeetingHallRepository(this.firestoreClient);

  Stream<List<MeetingHall>> getMeetingHalls() {
    try {
      return firestoreClient.streamAll(collection: path).map((results) =>
        results.map((item) => MeetingHall.fromJson({...item.data, 'id': item.id})).toList()
      );
    } catch (err, stckTrace) {
      log("Error streaming meeting halls: $err");
      log("StackTrace: $stckTrace");
      throw Exception(err);
    }
  }

  Future<MeetingHall> getMeetingHallById(String id) async {
    try {
      final result = await firestoreClient.fetchById(collection: path, id: id);
      return MeetingHall.fromJson({...result.data, 'id': result.id});
    } catch (err) {
      throw (Exception(err));
    }
  }

  Future<void> addMeetingHall(MeetingHall hall) async {
    try {
      await firestoreClient.add(
        collection: path,
        data: hall.toJson(),
      );
    } catch (err) {
      throw (Exception(err));
    }
  }

  Future<void> updateMeetingHall(MeetingHall hall) async {
    try {
      await firestoreClient.update(
        collection: path,
        data: hall.toJson(),
      );
    } catch (err) {
      throw (Exception(err));
    }
  }

  Future<void> deleteMeetingHall(String id) async {
    try {
      await firestoreClient.delete(
        collection: path,
        id: id,
      );
    } catch (err) {
      throw (Exception(err));
    }
  }
}

final meetingHallRepositoryProvider = Provider<MeetingHallRepository>((ref) {
  return MeetingHallRepository(ref.read(firestoreClientProvider));
});

// Provider to return a single meeting hall
final meetingHallProvider = FutureProvider.family<MeetingHall, String>((ref, id) async {
  final repository = ref.watch(meetingHallRepositoryProvider);
  return await repository.getMeetingHallById(id);
});
