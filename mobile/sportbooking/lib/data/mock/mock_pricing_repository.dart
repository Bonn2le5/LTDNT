import '../../core/utils/app_clock.dart';
import '../../models/booking_detail_model.dart';
import '../../models/branch_model.dart';
import '../../models/court_model.dart';
import '../../models/pricing_rule_model.dart';
import '../../repositories/pricing_repository.dart';

class MockPricingRepository implements PricingRepository {
  const MockPricingRepository();
  static const rules = [
    PricingRuleModel(
      id: 1,
      startMinute: 1020,
      endMinute: 1320,
      surchargePercent: 20,
    ),
    PricingRuleModel(
      id: 2,
      startMinute: 0,
      endMinute: 1440,
      surchargePercent: 10,
      weekendOnly: true,
    ),
  ];

  @override
  List<BookingDetailModel> pricesForDay(
    CourtModel court,
    DateTime date,
    BranchPresentation hours,
  ) {
    final result = <BookingDetailModel>[];
    for (
      var minute = hours.openMinute;
      minute + 60 <= hours.closeMinute;
      minute += 60
    ) {
      var percent = 100;
      for (final rule in rules) {
        if (minute >= rule.startMinute &&
            minute < rule.endMinute &&
            (rule.type == null || rule.type == court.type) &&
            (!rule.weekendOnly || date.weekday >= DateTime.saturday)) {
          percent += rule.surchargePercent;
        }
      }
      result.add(
        BookingDetailModel(
          startTime: AppClock.instant(date, minute),
          endTime: AppClock.instant(date, minute + 60),
          price: (court.pricePerHour * percent / 100).round(),
        ),
      );
    }
    return List.unmodifiable(result);
  }
}
