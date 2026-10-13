import 'package:intl/intl.dart';

import 'app_clock.dart';

class AppFormat {
  static String money(int amount) =>
      '${NumberFormat('#,##0', 'vi').format(amount)} ₫';
  static String date(DateTime calendarDate) =>
      DateFormat('dd/MM/yyyy', 'vi').format(calendarDate);
  static String instantDate(DateTime utc) => date(AppClock.vietnamTime(utc));
  static String time(DateTime utc) =>
      DateFormat('HH:mm', 'vi').format(AppClock.vietnamTime(utc));
  static String dateTime(DateTime utc) => '${instantDate(utc)} · ${time(utc)}';
  static String minutes(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
  static String duration(Duration value) {
    final minutes = value.inMinutes;
    if (minutes % 60 == 0) return '${minutes ~/ 60} giờ';
    return '${minutes ~/ 60} giờ ${minutes % 60} phút';
  }
}
