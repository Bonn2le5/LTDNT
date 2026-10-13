import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/navigation/app_navigation.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/app_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/court_artwork.dart';
import '../../../models/court_type_model.dart';
import '../../../repositories/auth_repository.dart';
import '../widgets/password_field.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _identity = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  @override
  void dispose() {
    _identity.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await context.read<AuthRepository>().signIn(
        _identity.text,
        _password.text,
      );
      if (mounted) showMessage(context, 'Đăng nhập thành công. Chào mừng bạn!');
    } on AppException catch (error) {
      if (mounted) showMessage(context, error.message);
    } catch (_) {
      if (mounted) {
        showMessage(context, 'Không thể đăng nhập. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _register() async {
    final email = await AppNavigation.push<String>(
      context,
      const RegisterScreen(),
    );
    if (!mounted || email == null) return;
    _identity.text = email;
    _password.clear();
    showMessage(
      context,
      'Đăng ký thành công. Hãy đăng nhập bằng tài khoản vừa tạo.',
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: PageContent(
      children: [
        const SizedBox(height: 18),
        const BrandMark(large: true),
        const SizedBox(height: 28),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: const CourtArtwork(type: CourtType.football, height: 155),
        ),
        const SizedBox(height: 24),
        Text(
          'Sẵn sàng ra sân?',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 6),
        const Text(
          'Đặt sân yêu thích. Kết nối đam mê.',
          style: TextStyle(color: Color(0xFF6B7E72)),
        ),
        const SizedBox(height: 24),
        Text('Đăng nhập', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Form(
          key: _form,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('login_identity'),
                controller: _identity,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: Validators.identity,
                decoration: const InputDecoration(
                  labelText: 'Email hoặc số điện thoại',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _password,
                label: 'Mật khẩu',
                enabled: !_busy,
                fieldKey: const Key('login_password'),
                validator: (value) => Validators.required(value, 'mật khẩu'),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy
                      ? null
                      : () => showMessage(
                          context,
                          'Khôi phục mật khẩu sẽ được hỗ trợ khi kết nối hệ thống tài khoản.',
                        ),
                  child: const Text('Quên mật khẩu?'),
                ),
              ),
              BusyButton(
                key: const Key('login_submit'),
                label: 'Đăng nhập',
                onPressed: _login,
                busy: _busy,
                icon: Icons.arrow_forward_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          key: const Key('open_register'),
          onPressed: _busy ? null : _register,
          child: const Text('Chưa có tài khoản? Đăng ký'),
        ),
        const SizedBox(height: 12),
        SectionCard(
          children: [
            const Text(
              'Khám phá với tài khoản demo',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Email: demo@gmail.com\nMật khẩu: 123456',
              style: TextStyle(color: Color(0xFF6B7E72)),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('fill_demo'),
              onPressed: _busy
                  ? null
                  : () {
                      _identity.text = 'demo@gmail.com';
                      _password.text = '123456';
                      showMessage(
                        context,
                        'Đã điền tài khoản demo. Bấm Đăng nhập để tiếp tục.',
                      );
                    },
              icon: const Icon(Icons.sports_soccer_rounded),
              label: const Text('Dùng tài khoản demo'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Dữ liệu mô phỏng • Không xử lý tiền thật',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.green, fontSize: 12),
        ),
      ],
    ),
  );
}
