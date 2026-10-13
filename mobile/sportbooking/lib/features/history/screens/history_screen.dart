import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/navigation/app_navigation.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/booking_model.dart';
import '../../../repositories/booking_repository.dart';
import '../../../repositories/court_repository.dart';
import 'booking_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  BookingStatus? _status;
  @override
  Widget build(BuildContext context) {
    final all = context.watch<BookingRepository>().bookingsForCurrentUser();
    final bookings = all
        .where((booking) => _status == null || booking.status == _status)
        .toList();
    final courts = context.read<CourtRepository>();
    return PageContent(
      children: [
        Text(
          'Những lần ra sân của bạn',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          '${all.length} đơn đặt sân · Mới nhất trước',
          style: const TextStyle(color: Color(0xFF6B7E72)),
        ),
        const SizedBox(height: 18),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('Tất cả'),
                  selected: _status == null,
                  onSelected: (_) => setState(() => _status = null),
                ),
              ),
              for (final status in BookingStatus.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    key: Key('history_${status.name}'),
                    label: Text(status.label),
                    selected: _status == status,
                    onSelected: (_) => setState(() => _status = status),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        if (bookings.isEmpty)
          StatePanel(
            title: all.isEmpty
                ? 'Chưa có lịch đặt sân'
                : 'Chưa có đơn ở trạng thái này',
            message: all.isEmpty
                ? 'Khám phá sân và tạo lịch hẹn đầu tiên với đồng đội.'
                : 'Chọn trạng thái khác để xem các đơn của bạn.',
            icon: Icons.event_available_outlined,
          ),
        if (all.isEmpty)
          OutlinedButton(
            onPressed: () => AppNavigation.toTab(context, 0),
            child: const Text('Khám phá sân'),
          ),
        for (final booking in bookings) ...[
          Card(
            child: InkWell(
              key: Key('booking_${booking.id}'),
              borderRadius: BorderRadius.circular(20),
              onTap: () => AppNavigation.push(
                context,
                BookingDetailScreen(bookingId: booking.id),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        Text(
                          booking.code,
                          style: const TextStyle(
                            color: Color(0xFF6B7E72),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(
                          width: 145,
                          child: StatusBadge(booking.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      courts.courtById(booking.courtId).name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${AppFormat.instantDate(booking.startTime)} · ${AppFormat.time(booking.startTime)} – ${AppFormat.time(booking.endTime)}',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppFormat.money(booking.totalPrice),
                      style: const TextStyle(
                        color: AppTheme.green,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tạo lúc ${AppFormat.dateTime(booking.createdAt)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7E72),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}
