import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/navigation/app_navigation.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/app_clock.dart';
import '../../../core/utils/app_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/booking_detail_model.dart';
import '../../../repositories/booking_repository.dart';
import '../../../repositories/court_repository.dart';
import '../../payment/screens/payment_screen.dart';
import '../booking_selection.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.courtId});
  final int courtId;
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _selection = BookingSelection();
  DateTime? _date;
  Future<List<BookingSlot>>? _future;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _date ??= context.read<AppClock>().today();
    _future ??= context.read<BookingRepository>().slotsForDay(
      widget.courtId,
      _date!,
    );
  }

  void _load(DateTime date) {
    setState(() {
      _date = date;
      _selection.clear();
      _future = context.read<BookingRepository>().slotsForDay(
        widget.courtId,
        date,
      );
    });
  }

  Future<void> _pickDate() async {
    final today = context.read<AppClock>().today();
    final date = await showDatePicker(
      context: context,
      initialDate: _date!.isBefore(today) ? today : _date!,
      firstDate: today,
      lastDate: AppClock.addDays(today, 365),
      helpText: 'Chọn ngày đặt sân',
      cancelText: 'Quay lại',
      confirmText: 'Chọn ngày',
      fieldLabelText: 'Ngày đặt sân',
      errorFormatText: 'Ngày chưa đúng định dạng',
      errorInvalidText: 'Ngày ngoài phạm vi cho phép',
    );
    if (date != null && mounted) _load(date);
  }

  void _toggle(BookingSlot slot) {
    try {
      setState(() => _selection.toggle(slot));
    } on AppException catch (error) {
      showMessage(context, error.message);
    }
  }

  Future<void> _continue() async {
    if (_selection.slots.isEmpty) return;
    await AppNavigation.push(
      context,
      PaymentScreen(courtId: widget.courtId, slots: _selection.slots),
    );
    if (mounted) _load(_date!);
  }

  @override
  Widget build(BuildContext context) {
    final court = context.read<CourtRepository>().courtById(widget.courtId);
    final today = context.read<AppClock>().today();
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn ngày và giờ')),
      body: PageContent(
        children: [
          const Text(
            'BƯỚC 1 / 2 · CHỌN LỊCH',
            style: TextStyle(
              color: AppTheme.green,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(court.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            key: const Key('pick_date'),
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text('Ngày đặt: ${AppFormat.date(_date!)}'),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      key: Key('day_$i'),
                      label: Text(
                        i == 0
                            ? 'Hôm nay'
                            : i == 1
                            ? 'Ngày mai'
                            : AppFormat.date(AppClock.addDays(today, i))
                                  .substring(0, 5),
                      ),
                      selected: _date == AppClock.addDays(today, i),
                      onSelected: (_) => _load(AppClock.addDays(today, i)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Chọn khung giờ', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          const Text(
            'Chọn một hoặc nhiều giờ liên tiếp. Bỏ chọn từ đầu hoặc cuối để điều chỉnh lịch.',
            style: TextStyle(color: Color(0xFF6B7E72), fontSize: 12),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              Text(
                '● Còn trống',
                style: TextStyle(color: AppTheme.green, fontSize: 12),
              ),
              Text(
                '● Đã đặt',
                style: TextStyle(color: Color(0xFF9A4545), fontSize: 12),
              ),
              Text(
                '● Đã qua',
                style: TextStyle(color: Color(0xFF6B7E72), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<BookingSlot>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LoadingPanel(label: 'Đang kiểm tra lịch sân…');
              }
              if (snapshot.hasError) {
                return StatePanel(
                  title: 'Chưa tải được lịch sân',
                  message: 'Vui lòng thử lại.',
                  onRetry: () => _load(_date!),
                );
              }
              final slots = snapshot.data!;
              if (slots.isEmpty) {
                return const StatePanel(
                  title: 'Chưa có khung giờ',
                  message: 'Vui lòng chọn ngày khác.',
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!slots.any((slot) => slot.isAvailable))
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Ngày này không còn giờ trống. Hãy chọn một ngày khác.',
                      ),
                    ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 260 ? 2 : 1;
                      final width =
                          (constraints.maxWidth - (columns - 1) * 12) / columns;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final slot in slots)
                            SizedBox(
                              width: width,
                              child: _SlotTile(
                                slot: slot,
                                selected: _selection.contains(slot),
                                onTap: () => _toggle(slot),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _load(_date!),
            icon: const Icon(Icons.refresh),
            label: const Text('Làm mới lịch sân'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InfoRow(
                'Tổng thời lượng',
                AppFormat.duration(_selection.duration),
              ),
              InfoRow(
                'Tạm tính',
                AppFormat.money(_selection.total),
                emphasize: true,
              ),
              const SizedBox(height: 8),
              BusyButton(
                key: const Key('continue_payment'),
                label: 'Tiếp tục thanh toán',
                icon: Icons.arrow_forward_rounded,
                onPressed: _selection.slots.isEmpty ? null : _continue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.selected,
    required this.onTap,
  });
  final BookingSlot slot;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final label = switch (slot.availability) {
      SlotAvailability.available => AppFormat.money(slot.price),
      SlotAvailability.booked => 'Đã đặt',
      SlotAvailability.elapsed => 'Đã qua',
    };
    final color = selected
        ? Colors.white
        : slot.isAvailable
        ? AppTheme.green
        : slot.availability == SlotAvailability.booked
        ? const Color(0xFF9A4545)
        : const Color(0xFF6B7E72);
    return Semantics(
      selected: selected,
      child: OutlinedButton(
        key: Key('slot_${AppClock.vietnamTime(slot.startTime).hour}'),
        onPressed: slot.isAvailable ? onTap : null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          backgroundColor: selected
              ? AppTheme.green
              : slot.isAvailable
              ? Colors.white
              : const Color(0xFFEEF1EE),
          side: BorderSide(
            color: selected ? AppTheme.green : const Color(0xFFDCE6DF),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppFormat.time(slot.startTime)} – ${AppFormat.time(slot.endTime)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
