import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/navigation/app_navigation.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../repositories/booking_repository.dart';
import '../../history/screens/booking_detail_screen.dart';

class BookingResultScreen extends StatelessWidget {
  const BookingResultScreen({super.key, required this.bookingId});
  final int bookingId;
  @override
  Widget build(BuildContext context) {
    final booking = context.read<BookingRepository>().bookingById(bookingId);
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kết quả đặt sân'),
          automaticallyImplyLeading: false,
        ),
        body: PageContent(
          children: [
            const SizedBox(height: 24),
            const Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Color(0xFFDFF2E5),
                child: Icon(
                  Icons.check_rounded,
                  size: 52,
                  color: AppTheme.green,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Đặt sân thành công!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            const Text(
              'Lịch hẹn với đồng đội đã sẵn sàng.\nHẹn gặp bạn trên sân!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SectionCard(
              children: [
                InfoRow('Mã đặt sân', booking.code, emphasize: true),
                InfoRow('Ngày đặt', AppFormat.instantDate(booking.startTime)),
                InfoRow(
                  'Khung giờ',
                  '${AppFormat.time(booking.startTime)} – ${AppFormat.time(booking.endTime)}',
                ),
                InfoRow(
                  'Tổng tiền',
                  AppFormat.money(booking.totalPrice),
                  emphasize: true,
                ),
                const SizedBox(height: 8),
                StatusBadge(booking.status),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              booking.payment.method.isOnline
                  ? 'Thanh toán mô phỏng thành công. Không có giao dịch ngân hàng hoặc tiền thật được xử lý.'
                  : 'Đơn đang chờ thanh toán. Bạn sẽ thanh toán khi đến sân.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.green),
            ),
            const SizedBox(height: 26),
            BusyButton(
              key: const Key('result_detail'),
              label: 'Xem chi tiết đơn',
              onPressed: () => AppNavigation.toTabAndPush(
                context,
                1,
                BookingDetailScreen(bookingId: bookingId),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('result_history'),
              onPressed: () => AppNavigation.toTab(context, 1),
              child: const Text('Xem lịch sử đặt sân'),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('result_home'),
              onPressed: () => AppNavigation.toTab(context, 0),
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    );
  }
}
