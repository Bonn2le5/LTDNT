import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/navigation/app_navigation.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../repositories/auth_repository.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthRepository>();
    final user = auth.currentUser!;
    return PageContent(
      children: [
        const SizedBox(height: 18),
        const Center(
          child: CircleAvatar(
            radius: 46,
            backgroundColor: Color(0xFFDFF2E5),
            child: Icon(Icons.person_rounded, size: 54, color: AppTheme.green),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          user.fullName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        const Text(
          'Cùng bạn trên mọi sân đấu',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF6B7E72)),
        ),
        const SizedBox(height: 26),
        SectionCard(
          title: 'Thông tin cá nhân',
          children: [
            InfoRow('Họ và tên', user.fullName),
            InfoRow('Email', user.email),
            InfoRow('Số điện thoại', auth.phoneFor(user.id)),
          ],
        ),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 8,
            ),
            leading: const Icon(
              Icons.calendar_month_outlined,
              color: AppTheme.green,
            ),
            title: const Text('Lịch sử đặt sân'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => AppNavigation.toTab(context, 1),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          key: const Key('logout'),
          onPressed: () {
            AppNavigation.toTab(context, 0);
            auth.signOut();
            showMessage(context, 'Bạn đã đăng xuất.');
          },
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Đăng xuất'),
        ),
        const SizedBox(height: 22),
        const Text(
          'Phiên bản trải nghiệm\nDữ liệu chỉ được giữ trong phiên chạy hiện tại.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0xFF6B7E72)),
        ),
      ],
    );
  }
}
