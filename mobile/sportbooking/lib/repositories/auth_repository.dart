import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

abstract class AuthRepository extends ChangeNotifier {
  UserModel? get currentUser;
  int get sessionVersion;
  String phoneFor(int userId);
  Future<UserModel> signIn(String identity, String password);
  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  });
  void signOut();
}
