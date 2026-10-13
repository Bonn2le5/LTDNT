/// Domain instants are UTC; calendar inputs and labels use Vietnam (UTC+7).
class AppClock {
  const AppClock();
  DateTime utcNow() => DateTime.now().toUtc();
  DateTime today() => dateOnly(vietnamTime(utcNow()));

  static DateTime vietnamTime(DateTime instant) {
    final shifted = instant.toUtc().add(const Duration(hours: 7));
    return DateTime(
      shifted.year,
      shifted.month,
      shifted.day,
      shifted.hour,
      shifted.minute,
      shifted.second,
    );
  }

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
  static DateTime addDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);
  static DateTime instant(DateTime date, int minuteOfDay) => DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).add(Duration(minutes: minuteOfDay)).subtract(const Duration(hours: 7));
}
