import '../../core/utils/app_exception.dart';
import '../../models/booking_detail_model.dart';

class BookingSelection {
  final List<BookingSlot> _slots = [];
  List<BookingSlot> get slots => List.unmodifiable(_slots);
  int get total => _slots.fold(0, (sum, slot) => sum + slot.price);
  Duration get duration =>
      _slots.fold(Duration.zero, (sum, slot) => sum + slot.duration);
  bool contains(BookingSlot slot) =>
      _slots.any((value) => value.sameInterval(slot));
  void clear() => _slots.clear();

  void toggle(BookingSlot slot) {
    if (!slot.isAvailable) {
      throw const AppException('Khung giờ này không còn trống.');
    }
    final index = _slots.indexWhere((value) => value.sameInterval(slot));
    if (index >= 0) {
      if (index != 0 && index != _slots.length - 1) {
        throw const AppException(
          'Hãy bỏ chọn từ đầu hoặc cuối để giữ các giờ liên tiếp.',
        );
      }
      _slots.removeAt(index);
      return;
    }
    if (_slots.isNotEmpty &&
        !_slots.first.startTime.isAtSameMomentAs(slot.endTime) &&
        !_slots.last.endTime.isAtSameMomentAs(slot.startTime)) {
      throw const AppException('Vui lòng chọn các khung giờ liên tiếp.');
    }
    _slots.add(slot);
    _slots.sort((a, b) => a.startTime.compareTo(b.startTime));
  }
}
