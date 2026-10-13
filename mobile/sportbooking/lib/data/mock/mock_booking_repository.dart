import '../../core/utils/app_clock.dart';
import '../../core/utils/app_exception.dart';
import '../../models/booking_detail_model.dart';
import '../../models/booking_model.dart';
import '../../models/payment_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/booking_repository.dart';
import '../../repositories/court_repository.dart';
import '../../repositories/pricing_repository.dart';

class MockBookingRepository extends BookingRepository {
  MockBookingRepository({
    required this.auth,
    required this.courts,
    required this.pricing,
    this.clock = const AppClock(),
    this.delay = const Duration(milliseconds: 450),
  }) {
    _seed();
  }
  final AuthRepository auth;
  final CourtRepository courts;
  final PricingRepository pricing;
  final AppClock clock;
  final Duration delay;
  final List<BookingModel> _bookings = [];
  final Map<String, Future<BookingModel>> _inFlight = {};
  final Map<String, BookingModel> _completed = {};
  final Map<String, String> _fingerprints = {};
  int _nextId = 1;

  List<BookingSlot> _slots(int courtId, DateTime date) {
    final court = courts.courtById(courtId);
    final details = pricing.pricesForDay(
      court,
      date,
      courts.branchPresentation(court.branchId),
    );
    final now = clock.utcNow();
    return details
        .map((detail) {
          final occupied = _bookings.any(
            (booking) =>
                booking.courtId == courtId &&
                booking.status.occupiesCourt &&
                booking.interval.overlaps(detail),
          );
          return BookingSlot(
            startTime: detail.startTime,
            endTime: detail.endTime,
            price: detail.price,
            availability: !detail.startTime.isAfter(now)
                ? SlotAvailability.elapsed
                : occupied
                ? SlotAvailability.booked
                : SlotAvailability.available,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<BookingSlot>> slotsForDay(int courtId, DateTime date) async {
    await Future<void>.delayed(delay);
    return _slots(courtId, date);
  }

  @override
  List<BookingModel> bookingsForCurrentUser() {
    final id = auth.currentUser?.id;
    final result = _bookings.where((booking) => booking.userId == id).toList();
    result.sort((a, b) {
      final order = b.createdAt.compareTo(a.createdAt);
      return order == 0 ? b.id.compareTo(a.id) : order;
    });
    return List.unmodifiable(result);
  }

  @override
  BookingModel bookingById(int id) => bookingsForCurrentUser().firstWhere(
    (booking) => booking.id == id,
    orElse: () =>
        throw const AppException('Không tìm thấy đơn của tài khoản này.'),
  );

  @override
  Future<BookingModel> create(CreateBookingRequest request) {
    final user = auth.currentUser;
    if (user == null) {
      return Future.error(const AppException('Vui lòng đăng nhập để đặt sân.'));
    }
    if (request.idempotencyKey.trim().isEmpty) {
      return Future.error(const AppException('Yêu cầu đặt sân không hợp lệ.'));
    }
    final key = '${user.id}:${request.idempotencyKey}';
    final fingerprint =
        '${request.courtId}|${request.method.name}|${request.intervals.map((range) => '${range.startTime.toUtc().toIso8601String()}/${range.endTime.toUtc().toIso8601String()}').join(',')}';
    if (_fingerprints.containsKey(key) && _fingerprints[key] != fingerprint) {
      return Future.error(
        const AppException(
          'Mã yêu cầu đã được dùng cho thông tin đặt sân khác.',
        ),
      );
    }
    if (_completed.containsKey(key)) return Future.value(_completed[key]);
    if (_inFlight.containsKey(key)) return _inFlight[key]!;
    _fingerprints[key] = fingerprint;
    final future = _create(request, user.id, auth.sessionVersion, key);
    _inFlight[key] = future;
    return future;
  }

  Future<BookingModel> _create(
    CreateBookingRequest request,
    int userId,
    int sessionVersion,
    String key,
  ) async {
    try {
      await Future<void>.delayed(delay);
      if (auth.currentUser?.id != userId ||
          auth.sessionVersion != sessionVersion) {
        throw const AppException(
          'Phiên đăng nhập đã thay đổi. Vui lòng đăng nhập lại.',
        );
      }
      if (!courts.courtPresentation(request.courtId).isActive) {
        throw const AppException('Sân đang bảo trì. Vui lòng chọn sân khác.');
      }
      if (request.intervals.isEmpty) {
        throw const AppException('Vui lòng chọn ít nhất một khung giờ.');
      }
      final ranges = request.intervals.toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      final day = AppClock.dateOnly(
        AppClock.vietnamTime(ranges.first.startTime),
      );
      if (day.isBefore(clock.today())) {
        throw const AppException('Không thể đặt sân vào ngày đã qua.');
      }
      if (day.isAfter(AppClock.addDays(clock.today(), 365))) {
        throw const AppException('Chỉ có thể đặt sân trong 365 ngày tới.');
      }
      final currentSlots = _slots(request.courtId, day);
      final details = <BookingDetailModel>[];
      for (var i = 0; i < ranges.length; i++) {
        final range = ranges[i];
        if (i > 0 && !ranges[i - 1].endTime.isAtSameMomentAs(range.startTime)) {
          throw const AppException(
            'Các khung giờ phải liên tiếp và không trùng nhau.',
          );
        }
        final matches = currentSlots.where((slot) => slot.sameInterval(range));
        if (matches.isEmpty) {
          throw const AppException(
            'Khung giờ nằm ngoài giờ mở cửa hoặc không hợp lệ.',
          );
        }
        final slot = matches.first;
        if (!slot.isAvailable) {
          throw const AppException(
            'Khung giờ đã qua hoặc vừa được đặt. Vui lòng chọn lại.',
          );
        }
        // Reprice from the repository; never trust prices provided by a widget.
        details.add(
          BookingDetailModel(
            startTime: slot.startTime,
            endTime: slot.endTime,
            price: slot.price,
          ),
        );
      }
      // No await between final validation and insertion: atomic in this isolate.
      final id = _nextId++;
      final online = request.method.isOnline;
      final now = clock.utcNow();
      final booking = BookingModel(
        id: id,
        userId: userId,
        courtId: request.courtId,
        details: details,
        status: online ? BookingStatus.paid : BookingStatus.pending,
        createdAt: now,
        payment: PaymentModel(
          id: id,
          bookingId: id,
          amount: details.fold(0, (sum, detail) => sum + detail.price),
          method: request.method,
          status: online ? PaymentStatus.success : PaymentStatus.pending,
          paidAt: online ? now : null,
          transactionRef: online ? 'MO-PHONG-$id' : null,
        ),
      );
      _bookings.add(booking);
      _completed[key] = booking;
      notifyListeners();
      return booking;
    } finally {
      _inFlight.remove(key);
      if (!_completed.containsKey(key)) _fingerprints.remove(key);
    }
  }

  void _addSeed(
    int userId,
    int courtId,
    DateTime day,
    int hour,
    BookingStatus status,
    int ageDays,
  ) {
    final court = courts.courtById(courtId);
    final prices = pricing.pricesForDay(
      court,
      day,
      courts.branchPresentation(court.branchId),
    );
    final details = prices
        .where((detail) => AppClock.vietnamTime(detail.startTime).hour == hour)
        .toList();
    final id = _nextId++;
    final online = status != BookingStatus.pending;
    final paymentStatus = status == BookingStatus.cancelled
        ? PaymentStatus.cancelled
        : status == BookingStatus.expired
        ? PaymentStatus.failed
        : online
        ? PaymentStatus.success
        : PaymentStatus.pending;
    final created = clock.utcNow().subtract(Duration(days: ageDays));
    _bookings.add(
      BookingModel(
        id: id,
        userId: userId,
        courtId: courtId,
        details: details,
        status: status,
        createdAt: created,
        payment: PaymentModel(
          id: id,
          bookingId: id,
          amount: details.first.price,
          method: online ? PaymentMethod.vietqr : PaymentMethod.atCourt,
          status: paymentStatus,
          paidAt: paymentStatus == PaymentStatus.success ? created : null,
          transactionRef: paymentStatus == PaymentStatus.success
              ? 'MO-PHONG-$id'
              : null,
        ),
      ),
    );
  }

  void _seed() {
    final today = clock.today();
    _addSeed(1, 1, AppClock.addDays(today, 1), 17, BookingStatus.pending, 0);
    _addSeed(1, 2, AppClock.addDays(today, 2), 18, BookingStatus.paid, 1);
    _addSeed(1, 3, AppClock.addDays(today, -3), 17, BookingStatus.completed, 5);
    _addSeed(1, 4, AppClock.addDays(today, 3), 18, BookingStatus.cancelled, 6);
    _addSeed(1, 5, AppClock.addDays(today, 4), 17, BookingStatus.expired, 7);
    // Other accounts' sample reservations occupy courts, but never appear in
    // the signed-in user's history. All availability reads this same collection.
    for (var day = 0; day < 14; day++) {
      for (var court = 1; court <= 12; court++) {
        _addSeed(
          0,
          court,
          AppClock.addDays(today, day),
          19,
          BookingStatus.paid,
          2,
        );
        if (court.isEven) {
          _addSeed(
            0,
            court,
            AppClock.addDays(today, day),
            12,
            BookingStatus.paid,
            3,
          );
        }
      }
    }
  }
}
