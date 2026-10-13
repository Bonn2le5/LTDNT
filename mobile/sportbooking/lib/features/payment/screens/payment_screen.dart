import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/app_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/booking_detail_model.dart';
import '../../../models/booking_model.dart';
import '../../../models/payment_model.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/booking_repository.dart';
import '../../booking/screens/booking_result_screen.dart';
import '../../booking/widgets/booking_summary.dart';

class PaymentScreen extends StatefulWidget {
  PaymentScreen({
    super.key,
    required this.courtId,
    required List<BookingSlot> slots,
  }) : slots = List.unmodifiable(slots);
  final int courtId;
  final List<BookingSlot> slots;
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static int _requestCounter = 0;
  final String _requestKey =
      '${DateTime.now().microsecondsSinceEpoch}-${_requestCounter++}';
  PaymentMethod _method = PaymentMethod.atCourt;
  bool _busy = false;
  String? _error;
  Future<void> _confirm() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final booking = await context.read<BookingRepository>().create(
        CreateBookingRequest(
          courtId: widget.courtId,
          intervals: widget.slots,
          method: _method,
          idempotencyKey: _requestKey,
        ),
      );
      if (!mounted) return;
      // Permit replacement after the operation completes. Back is blocked only
      // while the repository is committing the simulated reservation.
      setState(() => _busy = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BookingResultScreen(bookingId: booking.id),
        ),
      );
    } on AppException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
        showMessage(context, error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Chưa thể tạo đơn. Vui lòng thử lại.');
        showMessage(context, _error!);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthRepository>().currentUser!;
    final total = widget.slots.fold(0, (sum, slot) => sum + slot.price);
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Xác nhận và thanh toán')),
        body: PageContent(
          children: [
            const Text(
              'BƯỚC 2 / 2 · XÁC NHẬN',
              style: TextStyle(
                color: AppTheme.green,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            BookingSummary(
              courtId: widget.courtId,
              userName: user.fullName,
              details: widget.slots,
            ),
            const SizedBox(height: 24),
            Text(
              'Phương thức thanh toán',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final method in PaymentMethod.values) ...[
              Semantics(
                selected: _method == method,
                button: true,
                child: Card(
                  child: InkWell(
                    key: Key('payment_${method.name}'),
                    borderRadius: BorderRadius.circular(20),
                    onTap: _busy
                        ? null
                        : () => setState(() => _method = method),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            method == PaymentMethod.atCourt
                                ? Icons.storefront_outlined
                                : method == PaymentMethod.vnpay
                                ? Icons.account_balance_wallet_outlined
                                : Icons.qr_code_rounded,
                            color: AppTheme.green,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  method.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  method.isOnline
                                      ? 'Thanh toán mô phỏng'
                                      : 'Thanh toán khi đến sân',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7E72),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _method == method
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: AppTheme.green,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 6),
            SectionCard(
              children: [
                InfoRow(
                  'Số tiền cần thanh toán',
                  AppFormat.money(total),
                  emphasize: true,
                ),
                if (_method == PaymentMethod.atCourt)
                  const Text(
                    'Bạn sẽ thanh toán tại sân. Đơn được ghi nhận ở trạng thái chờ thanh toán.',
                    style: TextStyle(fontSize: 12),
                  ),
                if (_method.isOnline)
                  const Text(
                    'Thanh toán mô phỏng. Không chuyển tiền, không kết nối ngân hàng và không yêu cầu thông tin thẻ.',
                    style: TextStyle(fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                child: const Text('Chọn lại khung giờ'),
              ),
              const SizedBox(height: 12),
            ],
            BusyButton(
              key: const Key('confirm_booking'),
              label: 'Xác nhận đặt sân',
              onPressed: _confirm,
              busy: _busy,
              icon: Icons.check_rounded,
            ),
            const SizedBox(height: 12),
            const Text(
              'Lịch sân sẽ được kiểm tra lại khi bạn xác nhận.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7E72)),
            ),
          ],
        ),
      ),
    );
  }
}
