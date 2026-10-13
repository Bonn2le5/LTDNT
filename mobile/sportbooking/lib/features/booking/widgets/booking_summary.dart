import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/booking_detail_model.dart';
import '../../../repositories/court_repository.dart';

class BookingSummary extends StatelessWidget {
  const BookingSummary({
    super.key,
    required this.courtId,
    required this.userName,
    required this.details,
  });
  final int courtId;
  final String userName;
  final List<BookingDetailModel> details;
  @override
  Widget build(BuildContext context) {
    final courts = context.read<CourtRepository>();
    final court = courts.courtById(courtId);
    final branch = courts.branchById(court.branchId);
    final total = details.fold(0, (sum, detail) => sum + detail.price);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'Thông tin đặt sân',
          children: [
            InfoRow('Người đặt', userName),
            InfoRow('Sân', court.name),
            InfoRow('Loại sân', court.type.label),
            InfoRow('Chi nhánh', branch.name),
            InfoRow('Địa chỉ', branch.address),
            InfoRow('Ngày đặt', AppFormat.instantDate(details.first.startTime)),
            InfoRow('Giờ bắt đầu', AppFormat.time(details.first.startTime)),
            InfoRow('Giờ kết thúc', AppFormat.time(details.last.endTime)),
            InfoRow(
              'Thời lượng',
              AppFormat.duration(
                details.last.endTime.difference(details.first.startTime),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Chi tiết giá',
          children: [
            for (final detail in details)
              InfoRow(
                '${AppFormat.time(detail.startTime)} – ${AppFormat.time(detail.endTime)}',
                AppFormat.money(detail.price),
              ),
            const Divider(height: 24),
            InfoRow('Tổng tiền', AppFormat.money(total), emphasize: true),
          ],
        ),
      ],
    );
  }
}
