import '../../core/utils/app_exception.dart';
import '../../core/utils/validators.dart';
import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';

class MockAuthRepository extends AuthRepository {
  MockAuthRepository({this.delay = const Duration(milliseconds: 450)});
  final Duration delay;
  final Map<int, UserModel> _users = {
    1: const UserModel(
      id: 1,
      fullName: 'Nguyễn Minh Anh',
      email: 'demo@gmail.com',
    ),
  };
  // Credentials exist only in this ephemeral mock instance. Nothing is written
  // to SQLite, preferences, secure storage, logs or a network service.
  final Map<int, String> _passwords = {1: '123456'};
  final Map<int, String> _phones = {1: '0901234567'};
  UserModel? _currentUser;
  int _nextId = 2;
  int _sessionVersion = 0;

  @override
  UserModel? get currentUser => _currentUser;
  @override
  int get sessionVersion => _sessionVersion;
  @override
  String phoneFor(int userId) => _phones[userId] ?? 'Chưa cập nhật';

  @override
  Future<UserModel> signIn(String identity, String password) async {
    final error =
        Validators.identity(identity) ??
        Validators.required(password, 'mật khẩu');
    if (error != null) throw AppException(error);
    final version = _sessionVersion;
    await Future<void>.delayed(delay);
    if (version != _sessionVersion) {
      throw const AppException(
        'Phiên đăng nhập đã thay đổi. Vui lòng thử lại.',
      );
    }
    final normalized = identity.trim().toLowerCase();
    for (final user in _users.values) {
      if ((user.email == normalized ||
              _phones[user.id] == Validators.normalizePhone(normalized)) &&
          _passwords[user.id] == password) {
        _currentUser = user;
        _sessionVersion++;
        notifyListeners();
        return user;
      }
    }
    throw const AppException('Email, số điện thoại hoặc mật khẩu không đúng.');
  }

  @override
  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final error =
        Validators.required(fullName, 'họ tên') ??
        Validators.email(email) ??
        Validators.phone(phone) ??
        Validators.password(password);
    if (error != null) throw AppException(error);
    await Future<void>.delayed(delay);
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPhone = Validators.normalizePhone(phone);
    if (_users.values.any((user) => user.email == normalizedEmail)) {
      throw const AppException('Email này đã được đăng ký.');
    }
    if (_phones.containsValue(normalizedPhone)) {
      throw const AppException('Số điện thoại này đã được đăng ký.');
    }
    final id = _nextId++;
    _users[id] = UserModel(
      id: id,
      fullName: fullName.trim(),
      email: normalizedEmail,
    );
    _phones[id] = normalizedPhone;
    _passwords[id] = password;
  }

  @override
  void signOut() {
    _sessionVersion++;
    _currentUser = null;
    notifyListeners();
  }
}
