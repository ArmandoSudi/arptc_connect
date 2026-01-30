import 'package:arptc_connect/modules/meeting_hall/models/reservation_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingHallReservation {
  final String id;
  final String hallId;
  final String userId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final ReservationStatus status;
  final DateTime createdAt;

  MeetingHallReservation({
    required this.id,
    required this.hallId,
    required this.userId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.createdAt,
  });

  factory MeetingHallReservation.fromJson(Map<String, dynamic> json) {

    final Timestamp tsStartTime = json['startTime'] as Timestamp;
    final Timestamp tsEndTime = json['endTime'] as Timestamp;
    final Timestamp tsCreatedAt = json['createdAt'] as Timestamp;

    return MeetingHallReservation(
      id: json['id'] as String,
      hallId: json['hallId'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      startTime: tsStartTime.toDate(),
      endTime: tsEndTime.toDate(),
      status: ReservationStatus.fromString(json['status'] as String),
      createdAt: tsCreatedAt.toDate());
  }

  Map<String, dynamic> toJson() {
    return {
      'hallId': hallId,
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      // Note: Timestamp conversion is handled in the repository
    };
  }
}
