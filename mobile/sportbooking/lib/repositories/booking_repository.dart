import 'package:flutter/foundation.dart';

import '../models/booking_detail_model.dart';
import '../models/booking_model.dart';

abstract class BookingRepository extends ChangeNotifier {
  Future<List<BookingSlot>> slotsForDay(int courtId, DateTime date);
  List<BookingModel> bookingsForCurrentUser();
  BookingModel bookingById(int id);
  Future<BookingModel> create(CreateBookingRequest request);
}
