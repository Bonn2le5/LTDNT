import '../models/booking_detail_model.dart';
import '../models/branch_model.dart';
import '../models/court_model.dart';

abstract class PricingRepository {
  List<BookingDetailModel> pricesForDay(
    CourtModel court,
    DateTime date,
    BranchPresentation hours,
  );
}
