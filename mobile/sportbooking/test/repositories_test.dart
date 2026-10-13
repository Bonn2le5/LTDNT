import 'package:flutter_test/flutter_test.dart';
import 'package:sportbooking/app/app_dependencies.dart';
import 'package:sportbooking/core/utils/app_clock.dart';
import 'package:sportbooking/core/utils/app_exception.dart';
import 'package:sportbooking/core/utils/formatters.dart';
import 'package:sportbooking/core/utils/validators.dart';
import 'package:sportbooking/features/booking/booking_selection.dart';
import 'package:sportbooking/models/booking_detail_model.dart';
import 'package:sportbooking/models/booking_model.dart';
import 'package:sportbooking/models/court_type_model.dart';
import 'package:sportbooking/models/payment_model.dart';

import 'support/test_dependencies.dart';

void main() {
  late AppDependencies dependencies;
  late TestClock clock;
  setUp(() {
    clock = TestClock();
    dependencies = testDependencies(clock: clock);
  });
  tearDown(() => dependencies.dispose());

  Future<void> login() => dependencies.auth.signIn('demo@gmail.com', '123456');
  Future<List<BookingSlot>> tomorrow([int courtId = 1]) => dependencies.bookings
      .slotsForDay(courtId, AppClock.addDays(clock.today(), 1));
  CreateBookingRequest request(
    List<TimeRange> intervals, {
    String key = 'request',
    PaymentMethod method = PaymentMethod.atCourt,
    int courtId = 1,
  }) => CreateBookingRequest(
    courtId: courtId,
    intervals: intervals,
    method: method,
    idempotencyKey: key,
  );

  test('Vietnam calendar converts to UTC independently of device timezone', () {
    expect(clock.today(), DateTime(2026, 10, 13));
    expect(
      AppClock.instant(clock.today(), 9 * 60),
      DateTime.utc(2026, 10, 13, 2),
    );
    expect(
      AppClock.vietnamTime(DateTime.utc(2026, 10, 12, 18)),
      DateTime(2026, 10, 13, 1),
    );
    expect(AppFormat.money(120000), '120.000 ₫');
  });

  test('email and Vietnamese phone validation', () {
    expect(Validators.email('invalid@'), isNotNull);
    expect(Validators.phone('0123456789'), isNotNull);
    expect(Validators.phone('+84 901 234 567'), isNull);
    expect(Validators.password('12345'), isNotNull);
    expect(Validators.password('      '), isNotNull);
  });

  test('demo login, wrong password and signout', () async {
    await expectLater(
      dependencies.auth.signIn('demo@gmail.com', 'wrong'),
      throwsA(isA<AppException>()),
    );
    expect(dependencies.auth.currentUser, isNull);
    final user = await dependencies.auth.signIn('DEMO@gmail.com', '123456');
    expect(user.id, 1);
    dependencies.auth.signOut();
    expect(dependencies.auth.currentUser, isNull);
    await dependencies.auth.signIn('+84 901 234 567', '123456');
    expect(dependencies.auth.currentUser!.id, 1);
  });

  test(
    'registration remains usable and rejects duplicate emails and phones',
    () async {
      await dependencies.auth.register(
        fullName: '  Trần Hà  ',
        email: 'HA@example.com',
        phone: '0987654321',
        password: 'abcdef',
      );
      await expectLater(
        dependencies.auth.register(
          fullName: 'Hà',
          email: 'ha@example.com',
          phone: '0977654321',
          password: 'abcdef',
        ),
        throwsA(isA<AppException>()),
      );
      await expectLater(
        dependencies.auth.register(
          fullName: 'Hà',
          email: 'DEMO@gmail.com',
          phone: '0977654321',
          password: 'abcdef',
        ),
        throwsA(isA<AppException>()),
      );
      await expectLater(
        dependencies.auth.register(
          fullName: 'Hà',
          email: 'another@example.com',
          phone: '+84987654321',
          password: 'abcdef',
        ),
        throwsA(isA<AppException>()),
      );
      final user = await dependencies.auth.signIn('ha@example.com', 'abcdef');
      expect(user.fullName, 'Trần Hà');
      expect(dependencies.bookings.bookingsForCurrentUser(), isEmpty);
      await expectLater(
        Future.sync(() => dependencies.bookings.bookingById(1)),
        throwsA(isA<AppException>()),
      );
    },
  );

  test('catalog contains 12 courts, five sports and three branches', () async {
    final courts = await dependencies.courts.getCourts();
    expect(courts.length, 12);
    expect(courts.map((court) => court.type).toSet(), CourtType.values.toSet());
    expect(courts.map((court) => court.branchId).toSet().length, 3);
    for (final court in courts) {
      expect(
        dependencies.courts.branchById(court.branchId).address,
        isNotEmpty,
      );
      expect(dependencies.courts.courtById(court.id), same(court));
    }
  });

  test('pricing differs at peak hours and weekends', () {
    final court = dependencies.courts.courtById(1);
    final hours = dependencies.courts.branchPresentation(court.branchId);
    final weekday = dependencies.pricing.pricesForDay(
      court,
      DateTime(2026, 10, 14),
      hours,
    );
    expect(weekday.first.price, 250000);
    expect(
      weekday
          .firstWhere((slot) => AppClock.vietnamTime(slot.startTime).hour == 18)
          .price,
      300000,
    );
    final weekend = dependencies.pricing.pricesForDay(
      court,
      DateTime(2026, 10, 17),
      hours,
    );
    expect(weekend.first.price, 275000);
    expect(
      weekend
          .firstWhere((slot) => AppClock.vietnamTime(slot.startTime).hour == 18)
          .price,
      325000,
    );
  });

  test(
    'slots obey opening hours and disable elapsed and occupied intervals',
    () async {
      final slots = await dependencies.bookings.slotsForDay(1, clock.today());
      expect(AppClock.vietnamTime(slots.first.startTime).hour, 6);
      expect(AppClock.vietnamTime(slots.last.endTime).hour, 23);
      expect(slots.first.availability, SlotAvailability.elapsed);
      expect(
        slots
            .firstWhere(
              (slot) => AppClock.vietnamTime(slot.startTime).hour == 9,
            )
            .isAvailable,
        isFalse,
      );
      expect(
        slots
            .firstWhere(
              (slot) => AppClock.vietnamTime(slot.startTime).hour == 19,
            )
            .availability,
        SlotAvailability.booked,
      );
    },
  );

  test('selection rejects gaps and removing interior slots', () async {
    final slots = await tomorrow();
    final selection = BookingSelection();
    selection.toggle(slots[0]);
    selection.toggle(slots[1]);
    selection.toggle(slots[2]);
    expect(selection.total, 750000);
    expect(selection.duration.inHours, 3);
    expect(() => selection.toggle(slots[4]), throwsA(isA<AppException>()));
    expect(() => selection.toggle(slots[1]), throwsA(isA<AppException>()));
    selection.toggle(slots[0]);
    expect(selection.slots.length, 2);
    expect(selection.total, 500000);
  });

  test(
    'demo history is scoped to current user with all five sample orders',
    () async {
      expect(dependencies.bookings.bookingsForCurrentUser(), isEmpty);
      await login();
      final bookings = dependencies.bookings.bookingsForCurrentUser();
      expect(bookings.length, 5);
      expect(bookings.every((booking) => booking.userId == 1), isTrue);
      expect(bookings.first.status, BookingStatus.pending);
      dependencies.auth.signOut();
      expect(dependencies.bookings.bookingsForCurrentUser(), isEmpty);
    },
  );

  test('cancelled and expired sample orders release their intervals', () async {
    await login();
    for (final booking in dependencies.bookings.bookingsForCurrentUser().where(
      (booking) => !booking.status.occupiesCourt,
    )) {
      final date = AppClock.dateOnly(AppClock.vietnamTime(booking.startTime));
      final slots = await dependencies.bookings.slotsForDay(
        booking.courtId,
        date,
      );
      expect(
        slots
            .firstWhere((slot) => slot.sameInterval(booking.interval))
            .isAvailable,
        isTrue,
      );
    }
  });

  for (final method in PaymentMethod.values) {
    test(
      'create ${method.name}: payment status, pricing, history and availability',
      () async {
        await login();
        final slots = await tomorrow();
        var notifications = 0;
        dependencies.bookings.addListener(() => notifications++);
        final booking = await dependencies.bookings.create(
          request(slots.take(2).toList(), method: method),
        );
        expect(booking.details.length, 2);
        expect(booking.totalPrice, 500000);
        expect(
          booking.status,
          method.isOnline ? BookingStatus.paid : BookingStatus.pending,
        );
        expect(
          booking.payment.status,
          method.isOnline ? PaymentStatus.success : PaymentStatus.pending,
        );
        expect(
          booking.payment.transactionRef,
          method.isOnline ? startsWith('MO-PHONG-') : isNull,
        );
        expect(
          dependencies.bookings.bookingsForCurrentUser().first.id,
          booking.id,
        );
        expect(notifications, 1);
        expect((await tomorrow()).first.availability, SlotAvailability.booked);
        // The next adjacent hour is still bookable ([start, end) semantics).
        await dependencies.bookings.create(
          request([slots[2]], key: 'adjacent'),
        );
      },
    );
  }

  test('idempotency covers concurrent and repeated confirmation', () async {
    await login();
    final slots = await tomorrow();
    final payload = request([slots.first]);
    final one = dependencies.bookings.create(payload);
    final two = dependencies.bookings.create(payload);
    expect(identical(one, two), isTrue);
    final result = await Future.wait([one, two]);
    expect(result.first.id, result.last.id);
    expect((await dependencies.bookings.create(payload)).id, result.first.id);
    expect(dependencies.bookings.bookingsForCurrentUser().length, 6);
    await expectLater(
      dependencies.bookings.create(
        request([slots.first], method: PaymentMethod.vietqr),
      ),
      throwsA(isA<AppException>()),
    );
  });

  test('two separate requests cannot reserve the same interval', () async {
    await login();
    final slot = (await tomorrow()).first;
    final first = dependencies.bookings.create(request([slot], key: 'one'));
    final second = dependencies.bookings.create(request([slot], key: 'two'));
    final secondCheck = expectLater(second, throwsA(isA<AppException>()));
    await first;
    await secondCheck;
    expect(dependencies.bookings.bookingsForCurrentUser().length, 6);
  });

  test(
    'final validation rejects elapsed slots, gaps, repeats and outside hours',
    () async {
      await login();
      final slots = await tomorrow();
      for (final ranges in <List<TimeRange>>[
        [],
        [slots[0], slots[2]],
        [slots[0], slots[0]],
        [
          TimeRange(
            startTime: AppClock.instant(
              AppClock.addDays(clock.today(), 1),
              23 * 60,
            ),
            endTime: AppClock.instant(AppClock.addDays(clock.today(), 2), 0),
          ),
        ],
      ]) {
        await expectLater(
          dependencies.bookings.create(request(ranges)),
          throwsA(isA<AppException>()),
        );
      }
      clock.value = slots.first.startTime.add(const Duration(minutes: 1));
      await expectLater(
        dependencies.bookings.create(request([slots.first])),
        throwsA(isA<AppException>()),
      );
    },
  );

  test('repository ignores widget prices and requotes centrally', () async {
    await login();
    final slot = (await tomorrow()).first;
    final untrusted = BookingSlot(
      startTime: slot.startTime,
      endTime: slot.endTime,
      price: 1,
    );
    final result = await dependencies.bookings.create(request([untrusted]));
    expect(result.totalPrice, 250000);
  });

  test('inactive courts and unauthenticated creation are rejected', () async {
    final slot = (await tomorrow()).first;
    await expectLater(
      dependencies.bookings.create(request([slot])),
      throwsA(isA<AppException>()),
    );
    await login();
    final inactiveSlot = (await tomorrow(12)).first;
    await expectLater(
      dependencies.bookings.create(request([inactiveSlot], courtId: 12)),
      throwsA(isA<AppException>()),
    );
  });

  test('logout during confirmation prevents creating a booking', () async {
    await login();
    final slot = (await tomorrow()).first;
    final future = dependencies.bookings.create(request([slot]));
    dependencies.auth.signOut();
    await expectLater(future, throwsA(isA<AppException>()));
  });

  test('status codes and UTC half-open interval boundaries', () {
    expect(BookingStatus.values.map((status) => status.code), [
      0,
      1,
      2,
      3,
      4,
      5,
    ]);
    expect(PaymentStatus.values.map((status) => status.code), [0, 1, 2, 3, 4]);
    final first = TimeRange(
      startTime: DateTime.utc(2026, 10, 14, 0),
      endTime: DateTime.utc(2026, 10, 14, 1),
    );
    final adjacent = TimeRange(
      startTime: first.endTime,
      endTime: DateTime.utc(2026, 10, 14, 2),
    );
    expect(first.overlaps(adjacent), isFalse);
    expect(
      first.overlaps(
        TimeRange(
          startTime: first.startTime.add(const Duration(minutes: 30)),
          endTime: first.endTime,
        ),
      ),
      isTrue,
    );
  });
}
