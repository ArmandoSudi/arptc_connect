import 'package:cloud_firestore/cloud_firestore.dart';
// json_annotation is supplied by the existing Freezed serialization toolchain.
// ignore: depend_on_referenced_packages
import 'package:json_annotation/json_annotation.dart';

class TimestampSerializer implements JsonConverter<DateTime, Timestamp> {
  const TimestampSerializer();

  @override
  DateTime fromJson(Timestamp timestamp) => timestamp.toDate();

  @override
  Timestamp toJson(DateTime date) => Timestamp.fromDate(date);
}
