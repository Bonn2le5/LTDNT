class Validators {
  static String? required(String? value, String label) =>
      value == null || value.trim().isEmpty ? 'Vui lòng nhập $label.' : null;
  static String? email(String? value) {
    if (required(value, 'email') != null) return 'Vui lòng nhập email.';
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value!.trim())
        ? null
        : 'Email chưa đúng định dạng.';
  }

  static String normalizePhone(String value) {
    final compact = value.replaceAll(RegExp(r'[\s.-]'), '');
    return compact.startsWith('+84') ? '0${compact.substring(3)}' : compact;
  }

  static String? phone(String? value) {
    if (required(value, 'số điện thoại') != null) {
      return 'Vui lòng nhập số điện thoại.';
    }
    return RegExp(r'^0[35789]\d{8}$').hasMatch(normalizePhone(value!))
        ? null
        : 'Nhập số điện thoại Việt Nam hợp lệ (10 chữ số).';
  }

  static String? identity(String? value) {
    if (required(value, 'email hoặc số điện thoại') != null) {
      return 'Vui lòng nhập email hoặc số điện thoại.';
    }
    return value!.contains('@') ? email(value) : phone(value);
  }

  static String? password(String? value) =>
      value == null || value.trim().isEmpty || value.length < 6
      ? 'Mật khẩu cần ít nhất 6 ký tự.'
      : null;
}
