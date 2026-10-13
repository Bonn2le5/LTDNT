import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/navigation/app_navigation.dart';
import '../../../core/utils/app_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/booking_model.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/booking_repository.dart';
import '../../booking/widgets/booking_summary.dart';

class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({super.key, required this.bookingId});
  final int bookingId;
  @override
  Widget build(BuildContext context) {
    BookingModel booking;
    try {
      booking = context.watch<BookingRepository>().bookingById(bookingId);
    } on AppException catch (error) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết đơn')),
        body: Center(
          child: StatePanel(
            title: 'Không tìm thấy đơn',
            message: error.message,
          ),
        ),
      );
    }
    final user = context.read<AuthRepository>().currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đơn')),
      body: PageContent(
        children: [
          Text(booking.code, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          StatusBadge(booking.status),
          const SizedBox(height: 20),
          BookingSummary(
            courtId: booking.courtId,
            userName: user.fullName,
            details: booking.details,
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Thanh toán',
            children: [
              InfoRow('Phương thức', booking.payment.method.label),
              InfoRow('Trạng thái thanh toán', booking.payment.status.label),
              InfoRow('Số tiền', AppFormat.money(booking.payment.amount)),
              InfoRow('Ngày tạo đơn', AppFormat.dateTime(booking.createdAt)),
              if (booking.payment.paidAt != null)
                InfoRow(
                  'Thời điểm mô phỏng',
                  AppFormat.dateTime(booking.payment.paidAt!),
                ),
              if (booking.payment.method.isOnline)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Thanh toán mô phỏng. Các trạng thái và số tiền là dữ liệu giả, không phải giao dịch ngân hàng.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Quay lại'),
          ),
          const SizedBox(height: 10),
          BusyButton(
            key: const Key('detail_home'),
            label: 'Về trang chủ',
            onPressed: () => AppNavigation.toTab(context, 0),
          ),
        ],
      ),
    );
  }
}
