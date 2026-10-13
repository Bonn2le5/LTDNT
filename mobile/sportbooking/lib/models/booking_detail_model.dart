enum SlotAvailability { available, booked, elapsed }

/// UTC half-open interval [startTime, endTime): adjacent slots never overlap.
class TimeRange {
  const TimeRange({required this.startTime, required this.endTime});
  final DateTime startTime;
  final DateTime endTime;
  Duration get duration => endTime.difference(startTime);
  bool overlaps(TimeRange other) =>
      startTime.isBefore(other.endTime) && endTime.isAfter(other.startTime);
  bool sameInterval(TimeRange other) =>
      startTime.isAtSameMomentAs(other.startTime) &&
      endTime.isAtSameMomentAs(other.endTime);
}

class BookingDetailModel extends TimeRange {
  const BookingDetailModel({
    required super.startTime,
    required super.endTime,
    required this.price,
  });
  final int price;
}

class BookingSlot extends BookingDetailModel {
  const BookingSlot({
    required super.startTime,
    required super.endTime,
    required super.price,
    this.availability = SlotAvailability.available,
  });
  final SlotAvailability availability;
  String get key => startTime.toUtc().toIso8601String();
  bool get isAvailable => availability == SlotAvailability.available;
}
