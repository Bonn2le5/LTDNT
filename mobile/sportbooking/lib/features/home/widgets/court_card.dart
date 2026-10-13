import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/navigation/app_navigation.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/court_artwork.dart';
import '../../../models/court_model.dart';
import '../../../repositories/court_repository.dart';
import '../../booking/screens/booking_screen.dart';
import '../../courts/screens/court_detail_screen.dart';

class CourtCard extends StatelessWidget {
  const CourtCard({super.key, required this.court});
  final CourtModel court;
  @override
  Widget build(BuildContext context) {
    final repository = context.read<CourtRepository>();
    final branch = repository.branchById(court.branchId);
    final hours = repository.branchPresentation(court.branchId);
    final active = repository.courtPresentation(court.id).isActive;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('court_${court.id}'),
        onTap: () =>
            AppNavigation.push(context, CourtDetailScreen(courtId: court.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                CourtArtwork(type: court.type, variant: court.id),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          courtIcon(court.type),
                          size: 15,
                          color: AppTheme.green,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          court.type.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    court.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    branch.name,
                    style: const TextStyle(
                      color: AppTheme.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    branch.address,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7E72),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      Text(
                        '◷ ${AppFormat.minutes(hours.openMinute)} – ${AppFormat.minutes(hours.closeMinute)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        active ? '● Đang hoạt động' : '● Đang bảo trì',
                        style: TextStyle(
                          fontSize: 12,
                          color: active
                              ? AppTheme.green
                              : const Color(0xFF96600B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Giá tham khảo / giờ',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7E72),
                            ),
                          ),
                          Text(
                            AppFormat.money(court.pricePerHour),
                            style: const TextStyle(
                              color: AppTheme.green,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      FilledButton(
                        onPressed: active
                            ? () => AppNavigation.push(
                                context,
                                BookingScreen(courtId: court.id),
                              )
                            : null,
                        child: Text(active ? 'Đặt sân' : 'Bảo trì'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
