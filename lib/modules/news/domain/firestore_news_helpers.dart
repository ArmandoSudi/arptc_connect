import 'package:cloud_firestore/cloud_firestore.dart';

String stringFromFirestore(Map<String, dynamic> data, String key) {
  return data[key]?.toString().trim() ?? '';
}

DateTime? dateTimeFromFirestore(dynamic value) {
  if (value == null) {
    return null;
  }
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

Object? dateTimeToFirestore(DateTime? value) {
  if (value == null) {
    return null;
  }
  return Timestamp.fromDate(value);
}
