import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../repositories/auth_repository.dart';
import '../widgets/password_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  @override
  void dispose() {
    for (final controller in [_name, _email, _phone, _password, _confirm]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await context.read<AuthRepository>().register(
        fullName: _name.text,
        email: _email.text,
        phone: _phone.text,
        password: _password.text,
      );
      if (mounted) Navigator.of(context).pop(_email.text.trim());
    } on AppException catch (error) {
      if (mounted) showMessage(context, error.message);
    } catch (_) {
      if (mounted) showMessage(context, 'Không thể đăng ký. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: PageContent(
        children: [
          Text(
            'Bắt đầu cùng Đặt Sân',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Tạo tài khoản để lưu lịch sân của riêng bạn.'),
          const SizedBox(height: 24),
          Form(
            key: _form,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('register_name'),
                  controller: _name,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (value) => Validators.required(value, 'họ tên'),
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('register_email'),
                  controller: _email,
                  enabled: !_busy,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('register_phone'),
                  controller: _phone,
                  enabled: !_busy,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: Validators.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _password,
                  label: 'Mật khẩu',
                  enabled: !_busy,
                  fieldKey: const Key('register_password'),
                  validator: Validators.password,
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _confirm,
                  label: 'Xác nhận mật khẩu',
                  enabled: !_busy,
                  fieldKey: const Key('register_confirm'),
                  validator: (value) =>
                      value != _password.text || value == null || value.isEmpty
                      ? 'Mật khẩu xác nhận chưa trùng khớp.'
                      : null,
                ),
                const SizedBox(height: 24),
                BusyButton(
                  key: const Key('register_submit'),
                  label: 'Đăng ký',
                  onPressed: _submit,
                  busy: _busy,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: const Text('Đã có tài khoản? Đăng nhập'),
          ),
        ],
      ),
    ),
  );
}
