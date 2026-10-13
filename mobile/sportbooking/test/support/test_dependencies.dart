import 'package:sportbooking/app/app_dependencies.dart';
import 'package:sportbooking/core/utils/app_clock.dart';

class TestClock extends AppClock {
  TestClock([DateTime? now]) : value = now ?? DateTime.utc(2026, 10, 13, 2);
  DateTime value;
  @override
  DateTime utcNow() => value;
}

AppDependencies testDependencies({TestClock? clock}) =>
    AppDependencies.mock(clock: clock ?? TestClock(), delay: Duration.zero);
