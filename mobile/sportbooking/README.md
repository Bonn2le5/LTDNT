# Đặt Sân — Flutter Android

Ứng dụng đặt sân thể thao bằng Dart/Flutter trong project có sẵn của LTDNT. Toàn bộ dữ liệu và thanh toán ở giai đoạn này được mô phỏng trong bộ nhớ; có thể sử dụng khi backend không chạy. Giao diện Material 3 bằng tiếng Việt, màu xanh lá, sử dụng hình minh họa sân vẽ tại máy và không tải ảnh qua mạng.

## Chạy ứng dụng

Mở thư mục `mobile/sportbooking` bằng VS Code, cài extension Flutter/Dart và chọn thiết bị Android. Project hiện yêu cầu Dart `^3.13.1`; Flutter SDK dùng để triển khai là 3.47.1. Android sử dụng `flutter.minSdkVersion` theo SDK hiện tại (24 với Flutter 3.47.1).

Từ thư mục gốc LTDNT:

```powershell
cd mobile/sportbooking
flutter pub get
flutter devices
flutter run -d <ma-thiet-bi-android>
```

Nếu dùng emulator `Medium_Phone` có sẵn trên máy:

```powershell
flutter emulators --launch Medium_Phone
flutter run -d emulator-5554
```

Thiết bị khác có thể có ID khác; dùng ID do `flutter devices` trả về. Nếu Android SDK thiếu giấy phép, chủ máy cần xem và chấp nhận bằng `flutter doctor --android-licenses`.

Tài khoản demo:

| Thông tin | Giá trị |
| --- | --- |
| Email | `demo@gmail.com` |
| Mật khẩu | `123456` |
| Số điện thoại đăng nhập tương đương | `0901234567` |

Nút **Dùng tài khoản demo** điền thông tin vào form. Tài khoản đăng ký mới có thể đăng nhập bằng email hoặc số điện thoại trong cùng phiên chạy.

## Chức năng

- Đăng nhập và đăng ký: kiểm tra trường bắt buộc, email, số điện thoại Việt Nam, mật khẩu và xác nhận mật khẩu; ẩn/hiện mật khẩu; trạng thái đang xử lý; báo lỗi và thành công. Email được chuẩn hóa không phân biệt chữ hoa/thường; số điện thoại hỗ trợ `+84`. Không cho email hoặc số điện thoại trùng nhau.
- Trang chủ: lời chào, banner, tìm theo tên sân, lọc năm môn thể thao, 12 sân thuộc ba chi nhánh, giá tham khảo, địa chỉ, giờ hoạt động, trạng thái hoạt động/bảo trì và xem chi tiết.
- Chi tiết sân: hình minh họa, chi nhánh, địa chỉ, giờ mở/đóng cửa, mô tả, tiện ích và nút đặt sân.
- Chọn lịch: DatePicker tiếng Việt, ngày từ hôm nay đến 365 ngày tới, bảy ngày chọn nhanh; các khung 60 phút theo giờ mở cửa. Vô hiệu hóa giờ đã qua và đã đặt. Chọn nhiều giờ liên tiếp, bỏ chọn từ hai đầu, tự tính thời lượng và tổng tiền. Có nút làm mới lịch.
- Thanh toán: đầy đủ thông tin người đặt, sân, ngày/giờ, giá từng khung; chọn tại sân, VNPay hoặc VietQR. Hai phương thức trực tuyến luôn được gắn nhãn **Thanh toán mô phỏng**, không xử lý tiền, không tạo mã QR ngân hàng hoặc yêu cầu thông tin thẻ.
- Xác nhận: kiểm tra lại phiên đăng nhập, sân hoạt động, giờ hợp lệ, giá và trùng lịch trước khi tạo đơn. Khóa nút khi đang xử lý và dùng khóa idempotency tại repository để tránh tạo đơn lặp.
- Kết quả: mã đơn, lịch, tiền, trạng thái; mở chi tiết, lịch sử hoặc trang chủ. Không quay lại form thanh toán sau thành công.
- Lịch sử: năm đơn mẫu của tài khoản demo; đơn mới xuất hiện ngay, mới nhất trước, lọc đủ sáu trạng thái và chỉ xem đơn của tài khoản hiện tại.
- Chi tiết đơn: thông tin người đặt/sân/chi nhánh, khoảng giờ, chi tiết giá, trạng thái đơn và thanh toán riêng, ngày tạo, thời điểm thanh toán mô phỏng.
- Tài khoản: avatar, tên, email, điện thoại, mở lịch sử và đăng xuất. Đăng xuất xóa phiên và dọn route; nút Back không mở lại màn hình yêu cầu đăng nhập.
- Ba tab được giữ bằng `IndexedStack`, bảo toàn tìm kiếm, bộ lọc và vị trí cuộn khi chuyển tab.

## Kiến trúc và quy tắc dữ liệu

`AppDependencies` tạo đúng một bộ auth/court/pricing/booking repository cho mỗi phiên ứng dụng. `Provider` cấp chúng cho tất cả màn hình; `ChangeNotifier` thông báo thay đổi phiên và đơn đặt sân. Widget không tự tạo repository hoặc lưu danh sách sân/đơn độc lập.

Tất cả thời điểm của slot, đơn và thanh toán là UTC. Ngày chọn và giờ hiển thị luôn theo Việt Nam (UTC+7), kể cả khi thiết bị dùng múi giờ khác. Khoảng thời gian dùng quy ước `[bắt đầu, kết thúc)`, vì vậy hai khung giờ nối tiếp không trùng nhau. Repository kiểm tra toàn bộ slot sau độ trễ mô phỏng và lưu đơn liền sau kiểm tra, không có `await` giữa kiểm tra cuối và lưu.

`MockPricingRepository` quản lý giá gốc, phụ thu 20% trong 17:00–22:00 và 10% cuối tuần. Phụ thu cộng theo tỷ lệ giá gốc. Widget chỉ hiển thị giá; repository tính lại giá khi xác nhận. Số tiền dùng số nguyên VND.

`MockBookingRepository` tạo năm đơn demo và lịch mẫu của tài khoản khác trong 14 ngày tới (19:00–20:00; thêm 12:00–13:00 ở một số sân). Những đơn này và đơn mới nằm trong cùng một tập dữ liệu. Đơn hủy/hết hạn không chiếm sân. Lịch của người khác ảnh hưởng đến lịch trống nhưng không hiển thị trong lịch sử tài khoản demo.

## Tương thích backend hiện tại

Đã đọc `backend/SportBooking.Api/Models/Entities.cs`, `Data/AppDbContext.cs` và migration `Init`. Repository hiện có các bảng tiếng Anh; chưa có các bảng tiếng Việt trong đề bài hoặc file SQL độc lập. Không thay đổi backend, migration hay schema.

| Model Flutter | Entity backend hiện có | Ghi chú |
| --- | --- | --- |
| `UserModel` | `User` / `Users` | ID, họ tên, email, vai trò; không chứa mật khẩu |
| `BranchModel` | `Venue` / `Venues` | `branchId` ở sân tương ứng `VenueId` |
| `CourtModel` | `Court` / `Courts` | Loại sân tương ứng `SportType`, giá tương ứng `PricePerHour` |
| `BookingModel` | `Booking` / `Bookings` | UTC start/end, user/court, tổng tiền, trạng thái, ngày tạo |
| `PaymentModel` | `Payment` / `Payments` | Phương thức, số tiền, trạng thái, thời điểm, mã mô phỏng |
| `BookingDetailModel` | Dữ liệu trình bày mock | Backend hiện lưu một khoảng StartTime/EndTime cho mỗi đơn |
| `PricingRuleModel` | Quy tắc mock | Backend hiện chỉ có giá gốc trên Court |

Điện thoại, giờ mở cửa, khu vực, mô tả, tiện ích và trạng thái bảo trì là dữ liệu trình bày riêng, không được coi là cột bắt buộc mới trong database. `CourtType` là enum phía client cho chuỗi `SportType` của backend; không tự tạo bảng `LoaiSans`.

Booking enum có mã 0–5: chờ thanh toán, đã thanh toán, đã nhận sân, hoàn thành, đã hủy, hết hạn. Payment enum có mã 0–4 theo quy ước yêu cầu; backend hiện mới hỗ trợ Pending/Success/Failed (0–2). Backend đang lưu enum dưới dạng chuỗi C#, nên API adapter sau này phải ánh xạ tên/mã một cách tường minh; không gửi trực tiếp `enum.index` hoặc giả định database lưu số.

## Dependency

Chỉ thêm `flutter_localizations` từ Flutter SDK để DatePicker, nút điều hướng mặc định và nhãn hỗ trợ sử dụng tiếng Việt. Tận dụng `provider` và `intl` đã có. Các package có sẵn như `dio`, `sqflite`, `flutter_secure_storage`, `mobile_scanner`, `qr_flutter` được giữ lại; luồng hiện tại không gọi chúng để kết nối API, tạo database, quét mã hoặc xử lý thanh toán.

## Danh sách file triển khai

Các file sửa: `lib/main.dart`, `pubspec.yaml`, `pubspec.lock`, `test/widget_test.dart`, `README.md`, `android/app/src/main/AndroidManifest.xml` (tên ứng dụng), `android/app/build.gradle.kts` (Flutter tự cập nhật minSdk khi build).

Các file mới:

```text
lib/
  app/
    app.dart
    app_dependencies.dart
    navigation/app_navigation.dart
    theme/app_theme.dart
  core/
    utils/app_clock.dart
    utils/app_exception.dart
    utils/formatters.dart
    utils/validators.dart
    widgets/common_widgets.dart
    widgets/court_artwork.dart
  models/
    user_model.dart
    branch_model.dart
    court_type_model.dart
    court_model.dart
    pricing_rule_model.dart
    booking_detail_model.dart
    booking_model.dart
    payment_model.dart
  repositories/
    auth_repository.dart
    court_repository.dart
    pricing_repository.dart
    booking_repository.dart
  data/mock/
    mock_auth_repository.dart
    mock_court_repository.dart
    mock_pricing_repository.dart
    mock_booking_repository.dart
  features/
    auth/screens/login_screen.dart
    auth/screens/register_screen.dart
    auth/widgets/password_field.dart
    home/screens/main_shell.dart
    home/screens/home_screen.dart
    home/widgets/court_card.dart
    courts/screens/court_detail_screen.dart
    booking/booking_selection.dart
    booking/screens/booking_screen.dart
    booking/screens/booking_result_screen.dart
    booking/widgets/booking_summary.dart
    payment/screens/payment_screen.dart
    history/screens/history_screen.dart
    history/screens/booking_detail_screen.dart
    profile/screens/profile_screen.dart
test/
  repositories_test.dart
  support/test_dependencies.dart
```

## Kiểm tra

```powershell
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

Unit test kiểm tra đăng nhập/đăng ký, chuẩn hóa email/điện thoại, tính giá, múi giờ UTC+7, giờ mở cửa, liên tiếp/chồng lấn, cách ly tài khoản, đơn hủy/hết hạn, trạng thái thanh toán, tính lại giá, xử lý yêu cầu lặp và cạnh tranh đặt cùng giờ. Widget test kiểm tra form, tìm kiếm/bộ lọc, DatePicker, ba phương thức thanh toán, cập nhật lịch sử/lịch trống, điều hướng và đăng xuất; có luồng trên điện thoại 320×640 với chữ tăng 30%.

Test đếm số mặc định đã được thay bằng test ứng dụng đặt sân, vì màn hình mẫu không còn là hành vi của sản phẩm.

Kết quả đã chạy trong môi trường triển khai:

- `flutter pub get`: thành công.
- `dart format`: đã định dạng toàn bộ `lib/` và `test/`.
- `flutter analyze`: không có issue.
- `flutter test`: 29 test đạt (20 unit test và 9 widget test). Sau khi bổ sung kiểm tra mật khẩu chỉ có khoảng trắng, 20 unit test đã được chạy lại và đều đạt.
- `flutter build apk --debug`: thành công; APK tại `build/app/outputs/flutter-apk/app-debug.apk`.
- `flutter run -d emulator-5554 --no-resident`: đã cài và mở ứng dụng trên emulator Android 17 / API 37; đăng nhập demo và danh sách 12 sân đã được kiểm tra trên thiết bị. Luồng đặt sân đầy đủ và các phương thức thanh toán được xác minh bằng widget test.

## Giới hạn và bước thay thế sau này

- Tài khoản đăng ký, phiên đăng nhập và đơn mới chỉ tồn tại trong bộ nhớ, mất khi tắt ứng dụng hoặc hot restart. Mật khẩu mock chỉ được so sánh trong bộ nhớ; không được lưu plaintext vào SQLite, SharedPreferences hoặc file. Khi kết nối backend, dùng xác thực phía server và chỉ lưu token theo chính sách an toàn.
- Ảnh sân là hình minh họa vẽ cục bộ, chưa phải ảnh chụp sân thật. Chưa triển khai khôi phục mật khẩu, hủy đơn, quản trị hay cổng thanh toán thật.
- Chống đặt trùng hiện bảo vệ trong một phiên ứng dụng. Backend phải xử lý giao dịch/concurrency và idempotency giữa nhiều thiết bị trong tương lai.
- Thay các interface trong `repositories/` bằng REST API repository ở `AppDependencies`. Dùng adapter DTO để ánh xạ VenueId, SportType, decimal tiền, enum chuỗi và thời điểm UTC. Các phương thức đọc đồng bộ lấy dữ liệu từ cache; API repository cần tải/refresh cache và thông báo thay đổi.
- SQLite sẽ là lớp cache/local storage riêng phía repository; không khởi tạo database trong UI. Chỉ bổ sung lưu offline và đồng bộ sau khi xác định contract API cùng chính sách dữ liệu.
- Không tự mở rộng database để lưu breakdown giá, điện thoại hoặc tiện ích; cần thống nhất contract trước khi dùng những trường mock này trong API thực tế.
