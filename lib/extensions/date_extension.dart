import 'package:intl/intl.dart';

const String dateFormatter = 'd/M/y';

extension DateHelper on DateTime {
  String get formatedDate {
    final formatter = DateFormat(dateFormatter);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final aDate = DateTime(year, month, day);

    return formatter.format(this);

    // if (aDate == today) {
    //   return 'Today';
    // } else if (aDate == yesterday) {
    //   return 'Yesterday';
    // } else {
    //   return formatter.format(this);
    // }
  }

  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  int getDifferenceInDaysWithNow() {
    final now = DateTime.now();
    return now.difference(this).inDays;
  }
}