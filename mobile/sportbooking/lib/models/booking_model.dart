import 'booking_detail_model.dart';
import 'payment_model.dart';

enum BookingStatus {
  pending(0, 'Chờ thanh toán'),
  paid(1, 'Đã thanh toán'),
  checkedIn(2, 'Đã nhận sân'),
  completed(3, 'Hoàn thành'),
  cancelled(4, 'Đã hủy'),
  expired(5, 'Hết hạn');

  const BookingStatus(this.code, this.label);
  final int code;
  final String label;
  bool get occupiesCourt => this != cancelled && this != expired;
}

class BookingModel {
  BookingModel({
    required this.id,
    required this.userId,
    required this.courtId,
    required List<BookingDetailModel> details,
    required this.status,
    required this.createdAt,
    required this.payment,
  }) : details = List.unmodifiable(details);
  final int id;
  final int userId;
  final int courtId;

  /// Presentation breakdown; the current backend stores StartTime/EndTime.
  final List<BookingDetailModel> details;
  final BookingStatus status;
  final DateTime createdAt;
  final PaymentModel payment;
  String get code => 'DS${id.toString().padLeft(6, '0')}';
  DateTime get startTime => details.first.startTime;
  DateTime get endTime => details.last.endTime;
  int get totalPrice => details.fold(0, (sum, detail) => sum + detail.price);
  Duration get duration => endTime.difference(startTime);
  TimeRange get interval => TimeRange(startTime: startTime, endTime: endTime);
}

class CreateBookingRequest {
  CreateBookingRequest({
    required this.courtId,
    required List<TimeRange> intervals,
    required this.method,
    required this.idempotencyKey,
  }) : intervals = List.unmodifiable(intervals);
  final int courtId;
  final List<TimeRange> intervals;
  final PaymentMethod method;
  final String idempotencyKey;
}
