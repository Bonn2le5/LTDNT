import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/navigation/app_navigation.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/court_artwork.dart';
import '../../../repositories/court_repository.dart';
import '../../booking/screens/booking_screen.dart';

class CourtDetailScreen extends StatelessWidget {
  const CourtDetailScreen({super.key, required this.courtId});
  final int courtId;
  @override
  Widget build(BuildContext context) {
    final repository = context.read<CourtRepository>();
    final court = repository.courtById(courtId);
    final branch = repository.branchById(court.branchId);
    final hours = repository.branchPresentation(court.branchId);
    final presentation = repository.courtPresentation(courtId);
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết sân')),
      body: PageContent(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: CourtArtwork(
              type: court.type,
              height: 235,
              variant: court.id,
            ),
          ),
          const SizedBox(height: 22),
          Text(court.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: Icon(courtIcon(court.type), size: 18),
                label: Text(court.type.label),
              ),
              Chip(
                label: Text(
                  presentation.isActive ? 'Đang hoạt động' : 'Đang bảo trì',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: 'Thông tin sân',
            children: [
              InfoRow('Chi nhánh', branch.name),
              InfoRow('Địa chỉ', branch.address),
              InfoRow(
                'Giờ mở cửa',
                '${AppFormat.minutes(hours.openMinute)} – ${AppFormat.minutes(hours.closeMinute)}',
              ),
              InfoRow(
                'Giá tham khảo',
                '${AppFormat.money(court.pricePerHour)} / giờ',
                emphasize: true,
              ),
              const SizedBox(height: 8),
              const Text(
                'Giá theo giờ và ngày cuối tuần được hiển thị khi chọn lịch.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: 'Về sân này',
            children: [Text(presentation.description)],
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: 'Tiện ích',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final amenity in presentation.amenities)
                    Chip(
                      avatar: const Icon(Icons.check_circle_outline, size: 16),
                      label: Text(amenity),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          BusyButton(
            key: const Key('book_now'),
            label: presentation.isActive ? 'Đặt sân ngay' : 'Sân đang bảo trì',
            icon: Icons.calendar_month_outlined,
            onPressed: presentation.isActive
                ? () => AppNavigation.push(
                    context,
                    BookingScreen(courtId: courtId),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
