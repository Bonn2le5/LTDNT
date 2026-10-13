import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sportbooking/app/app.dart';
import 'package:sportbooking/app/app_dependencies.dart';
import 'package:sportbooking/core/utils/app_clock.dart';
import 'package:sportbooking/features/auth/screens/login_screen.dart';
import 'package:sportbooking/features/booking/screens/booking_result_screen.dart';
import 'package:sportbooking/features/history/screens/booking_detail_screen.dart';
import 'package:sportbooking/models/booking_model.dart';
import 'package:sportbooking/models/payment_model.dart';

import 'support/test_dependencies.dart';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  if (find.byType(SnackBar).evaluate().isNotEmpty) {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }
  await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> enterVisible(WidgetTester tester, String key, String value) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
  await tester.pump();
}

Future<void> mountApp(
  WidgetTester tester,
  AppDependencies dependencies, {
  Size size = const Size(390, 844),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    dependencies.dispose();
  });
  await tester.pumpWidget(SportBookingApp(dependencies: dependencies));
  await tester.pumpAndSettle();
}

Future<void> loginDemo(WidgetTester tester) async {
  await enterVisible(tester, 'login_identity', 'demo@gmail.com');
  await enterVisible(tester, 'login_password', '123456');
  await tapVisible(tester, find.byKey(const Key('login_submit')));
}

void main() {
  // The original counter smoke test is replaced because the generated counter
  // screen has been replaced by the requested sports booking application.
  testWidgets('login validation, wrong credentials and password visibility', (
    tester,
  ) async {
    await mountApp(tester, testDependencies());
    await tapVisible(tester, find.byKey(const Key('login_submit')));
    expect(
      find.text('Vui lòng nhập email hoặc số điện thoại.'),
      findsOneWidget,
    );
    expect(find.text('Vui lòng nhập mật khẩu.'), findsOneWidget);
    await enterVisible(tester, 'login_identity', 'demo@gmail.com');
    await enterVisible(tester, 'login_password', 'wrong');
    await tapVisible(tester, find.byTooltip('Hiện mật khẩu'));
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const Key('login_password')),
              matching: find.byType(EditableText),
            ),
          )
          .obscureText,
      isFalse,
    );
    await tapVisible(tester, find.byKey(const Key('login_submit')));
    expect(
      find.text('Email, số điện thoại hoặc mật khẩu không đúng.'),
      findsOneWidget,
    );
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('register validation, matching passwords and new account login', (
    tester,
  ) async {
    final dependencies = testDependencies();
    await mountApp(tester, dependencies);
    await tapVisible(tester, find.byKey(const Key('open_register')));
    await tapVisible(tester, find.byKey(const Key('register_submit')));
    expect(find.text('Vui lòng nhập họ tên.'), findsOneWidget);
    await enterVisible(tester, 'register_name', 'Trần Hà');
    await enterVisible(tester, 'register_email', 'ha@example.com');
    await enterVisible(tester, 'register_phone', '0987654321');
    await enterVisible(tester, 'register_password', 'abcdef');
    await enterVisible(tester, 'register_confirm', 'different');
    await tapVisible(tester, find.byKey(const Key('register_submit')));
    expect(find.text('Mật khẩu xác nhận chưa trùng khớp.'), findsOneWidget);
    await enterVisible(tester, 'register_confirm', 'abcdef');
    await tapVisible(tester, find.byKey(const Key('register_submit')));
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('login_identity')))
          .controller!
          .text,
      'ha@example.com',
    );
    await enterVisible(tester, 'login_password', 'abcdef');
    await tapVisible(tester, find.byKey(const Key('login_submit')));
    await tapVisible(tester, find.byKey(const Key('tab_history')));
    expect(find.text('Chưa có lịch đặt sân'), findsOneWidget);
    expect(dependencies.auth.currentUser!.fullName, 'Trần Hà');
    expect(tester.takeException(), isNull);
  });

  testWidgets('home search and type filters survive tab switching', (
    tester,
  ) async {
    await mountApp(tester, testDependencies());
    await loginDemo(tester);
    await enterVisible(tester, 'court_search', 'không tồn tại');
    expect(find.text('Không tìm thấy sân'), findsOneWidget);
    await enterVisible(tester, 'court_search', 'Gia Định');
    await tapVisible(tester, find.byKey(const Key('filter_badminton')));
    expect(find.byKey(const Key('court_2')), findsOneWidget);
    expect(find.byKey(const Key('court_11')), findsNothing);
    await tapVisible(tester, find.byKey(const Key('tab_history')));
    await tapVisible(tester, find.byKey(const Key('tab_home')));
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('court_search')))
          .controller!
          .text,
      'Gia Định',
    );
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const Key('filter_badminton')))
          .selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  for (final method in PaymentMethod.values) {
    testWidgets('complete booking flow with ${method.name}', (tester) async {
      final dependencies = testDependencies();
      await mountApp(tester, dependencies);
      await loginDemo(tester);
      await tapVisible(tester, find.byKey(const Key('court_1')));
      await tapVisible(tester, find.byKey(const Key('book_now')));
      await tapVisible(tester, find.byKey(const Key('day_1')));
      final continueButton = find.descendant(
        of: find.byKey(const Key('continue_payment')),
        matching: find.byType(FilledButton),
      );
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
      await tapVisible(tester, find.byKey(const Key('slot_6')));
      await tapVisible(tester, find.byKey(const Key('slot_8')));
      expect(
        find.text('Vui lòng chọn các khung giờ liên tiếp.'),
        findsOneWidget,
      );
      await tapVisible(tester, find.byKey(const Key('slot_7')));
      expect(find.text('500.000 ₫'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('slot_19')))
            .onPressed,
        isNull,
      );
      await tapVisible(tester, find.byKey(const Key('continue_payment')));
      await tapVisible(tester, find.byKey(Key('payment_${method.name}')));
      // Repeated taps cannot create two orders, including before the first frame.
      await tester.ensureVisible(find.byKey(const Key('confirm_booking')));
      await tester.tap(find.byKey(const Key('confirm_booking')));
      await tester.tap(find.byKey(const Key('confirm_booking')));
      await tester.pumpAndSettle();
      expect(find.byType(BookingResultScreen), findsOneWidget);
      expect(find.text('Đặt sân thành công!'), findsOneWidget);
      final booking = dependencies.bookings.bookingsForCurrentUser().first;
      expect(dependencies.bookings.bookingsForCurrentUser().length, 6);
      expect(
        booking.status,
        method.isOnline ? BookingStatus.paid : BookingStatus.pending,
      );
      await tapVisible(tester, find.byKey(const Key('result_detail')));
      expect(find.byType(BookingDetailScreen), findsOneWidget);
      expect(find.text(booking.code), findsOneWidget);
      await tapVisible(tester, find.byType(BackButton));
      expect(find.byKey(Key('booking_${booking.id}')), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('tab_home')));
      await tapVisible(tester, find.byKey(const Key('court_1')));
      await tapVisible(tester, find.byKey(const Key('book_now')));
      await tapVisible(tester, find.byKey(const Key('day_1')));
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('slot_6')))
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('date picker localizes Vietnamese and excludes past dates', (
    tester,
  ) async {
    final dependencies = testDependencies();
    await mountApp(tester, dependencies);
    await loginDemo(tester);
    await tapVisible(tester, find.byKey(const Key('court_1')));
    await tapVisible(tester, find.byKey(const Key('book_now')));
    await tapVisible(tester, find.byKey(const Key('pick_date')));
    final picker = tester.widget<DatePickerDialog>(
      find.byType(DatePickerDialog),
    );
    expect(picker.firstDate, dependencies.clock.today());
    expect(picker.lastDate, AppClock.addDays(dependencies.clock.today(), 365));
    expect(find.text('Chọn ngày đặt sân'), findsOneWidget);
    await tapVisible(tester, find.text('Quay lại'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('history status filter and logout remove protected navigation', (
    tester,
  ) async {
    await mountApp(tester, testDependencies());
    await loginDemo(tester);
    await tapVisible(tester, find.byKey(const Key('tab_history')));
    await tapVisible(tester, find.byKey(const Key('history_pending')));
    expect(find.byKey(const Key('booking_1')), findsOneWidget);
    expect(find.byKey(const Key('booking_2')), findsNothing);
    await tapVisible(tester, find.byKey(const Key('tab_profile')));
    await tapVisible(tester, find.byKey(const Key('logout')));
    expect(find.byType(LoginScreen), findsOneWidget);
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    expect(navigator.canPop(), isFalse);
    expect(find.byKey(const Key('tab_home')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('small phone and large text complete booking without overflow', (
    tester,
  ) async {
    await mountApp(
      tester,
      testDependencies(),
      size: const Size(320, 640),
      scale: 1.3,
    );
    await loginDemo(tester);
    await tapVisible(tester, find.byKey(const Key('court_1')));
    await tapVisible(tester, find.byKey(const Key('book_now')));
    await tapVisible(tester, find.byKey(const Key('day_1')));
    await tapVisible(tester, find.byKey(const Key('slot_6')));
    await tapVisible(tester, find.byKey(const Key('continue_payment')));
    await tapVisible(tester, find.byKey(const Key('payment_vietqr')));
    await tapVisible(tester, find.byKey(const Key('confirm_booking')));
    await tapVisible(tester, find.byKey(const Key('result_detail')));
    await tapVisible(tester, find.byKey(const Key('detail_home')));
    await tapVisible(tester, find.byKey(const Key('tab_profile')));
    expect(tester.takeException(), isNull);
  });
}
