import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/navigation/app_navigation.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../history/screens/history_screen.dart';
import '../../profile/screens/profile_screen.dart';
import 'home_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});
  @override
  Widget build(BuildContext context) {
    final navigation = context.watch<ShellNavigation>();
    return Scaffold(
      appBar: AppBar(
        title: navigation.index == 0
            ? const BrandMark()
            : Text(navigation.index == 1 ? 'Lịch sử đặt sân' : 'Tài khoản'),
        actions: navigation.index == 0
            ? [
                IconButton(
                  tooltip: 'Tài khoản',
                  onPressed: () => navigation.select(2),
                  icon: const Icon(Icons.account_circle_outlined),
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: IndexedStack(
        index: navigation.index,
        children: const [HomeScreen(), HistoryScreen(), ProfileScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigation.index,
        onDestinationSelected: navigation.select,
        destinations: const [
          NavigationDestination(
            key: Key('tab_home'),
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            key: Key('tab_history'),
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Lịch sử',
          ),
          NavigationDestination(
            key: Key('tab_profile'),
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
