enum PaymentStatus {
  pending(0, 'Chờ xử lý'),
  success(1, 'Thành công'),
  failed(2, 'Thất bại'),
  refunded(3, 'Đã hoàn tiền'),
  cancelled(4, 'Đã hủy');

  const PaymentStatus(this.code, this.label);
  final int code;
  final String label;
}

enum PaymentMethod {
  atCourt('Thanh toán tại sân'),
  vnpay('VNPay (mô phỏng)'),
  vietqr('VietQR (mô phỏng)');

  const PaymentMethod(this.label);
  final String label;
  bool get isOnline => this != atCourt;
}

class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.method,
    required this.status,
    this.paidAt,
    this.transactionRef,
  });
  final int id;
  final int bookingId;
  final int amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime? paidAt;
  final String? transactionRef;
}
