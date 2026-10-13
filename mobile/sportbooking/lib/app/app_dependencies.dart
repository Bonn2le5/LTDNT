import '../core/utils/app_clock.dart';
import '../data/mock/mock_auth_repository.dart';
import '../data/mock/mock_booking_repository.dart';
import '../data/mock/mock_court_repository.dart';
import '../data/mock/mock_pricing_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/booking_repository.dart';
import '../repositories/court_repository.dart';
import '../repositories/pricing_repository.dart';

/// One dependency graph per app run; screens never create their own mock data.
class AppDependencies {
  AppDependencies({
    required this.auth,
    required this.courts,
    required this.pricing,
    required this.bookings,
    required this.clock,
  });
  factory AppDependencies.mock({
    AppClock clock = const AppClock(),
    Duration delay = const Duration(milliseconds: 450),
  }) {
    final auth = MockAuthRepository(delay: delay);
    final courts = MockCourtRepository(delay: delay);
    const pricing = MockPricingRepository();
    final bookings = MockBookingRepository(
      auth: auth,
      courts: courts,
      pricing: pricing,
      clock: clock,
      delay: delay,
    );
    return AppDependencies(
      auth: auth,
      courts: courts,
      pricing: pricing,
      bookings: bookings,
      clock: clock,
    );
  }
  final AuthRepository auth;
  final CourtRepository courts;
  final PricingRepository pricing;
  final BookingRepository bookings;
  final AppClock clock;
  void dispose() {
    auth.dispose();
    bookings.dispose();
  }
}
