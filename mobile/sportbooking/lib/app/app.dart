import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/utils/app_clock.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/home/screens/main_shell.dart';
import '../repositories/auth_repository.dart';
import '../repositories/booking_repository.dart';
import '../repositories/court_repository.dart';
import '../repositories/pricing_repository.dart';
import 'app_dependencies.dart';
import 'navigation/app_navigation.dart';
import 'theme/app_theme.dart';

class SportBookingApp extends StatefulWidget {
  const SportBookingApp({super.key, this.dependencies});
  final AppDependencies? dependencies;
  @override
  State<SportBookingApp> createState() => _SportBookingAppState();
}

class _SportBookingAppState extends State<SportBookingApp> {
  late final AppDependencies _dependencies =
      widget.dependencies ?? AppDependencies.mock();
  @override
  void dispose() {
    if (widget.dependencies == null) _dependencies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthRepository>.value(value: _dependencies.auth),
      ChangeNotifierProvider<BookingRepository>.value(
        value: _dependencies.bookings,
      ),
      Provider<CourtRepository>.value(value: _dependencies.courts),
      Provider<PricingRepository>.value(value: _dependencies.pricing),
      Provider<AppClock>.value(value: _dependencies.clock),
      ChangeNotifierProvider(create: (_) => ShellNavigation()),
    ],
    child: MaterialApp(
      title: 'Đặt Sân',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const _AuthGate(),
    ),
  );
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthRepository>().currentUser;
    return user == null
        ? const LoginScreen()
        : MainShell(key: ValueKey(user.id));
  }
}
