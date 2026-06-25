import 'package:arptc_connect/modules/meeting_hall/models/reservation_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingHallReservation {
  final String id;
  final String hallId;
  final String userId;
  final String userName;
  final String userEmail;
  final String title;
  final String description;
  final String rejectionReason;
  final String cancelReason;
  final DateTime startTime;
  final DateTime endTime;
  final ReservationStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MeetingHallReservation({
    required this.id,
    required this.hallId,
    required this.userId,
    this.userName = '',
    this.userEmail = '',
    required this.title,
    required this.description,
    this.rejectionReason = '',
    this.cancelReason = '',
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory MeetingHallReservation.fromJson(Map<String, dynamic> json) {
    return MeetingHallReservation(
      id: json['id']?.toString() ?? '',
      hallId: json['hallId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      userEmail: json['userEmail']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      rejectionReason: json['rejectionReason']?.toString() ?? '',
      cancelReason: json['cancelReason']?.toString() ?? '',
      startTime: _dateFromJson(json['startTime']),
      endTime: _dateFromJson(json['endTime']),
      status: ReservationStatus.fromString(json['status']?.toString() ?? ''),
      createdAt: _dateFromJson(json['createdAt']),
      updatedAt: _optionalDateFromJson(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hallId': hallId,
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'title': title,
      'description': description,
      'rejectionReason': rejectionReason,
      'cancelReason': cancelReason,
      'status': status.value,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}

DateTime _dateFromJson(dynamic value) {
  return _optionalDateFromJson(value) ?? DateTime.now();
}

DateTime? _optionalDateFromJson(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
