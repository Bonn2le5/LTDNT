import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ShellNavigation extends ChangeNotifier {
  int _index = 0;
  int get index => _index;
  void select(int index) {
    if (_index == index) return;
    _index = index;
    notifyListeners();
  }
}

class AppNavigation {
  static Future<T?> push<T>(BuildContext context, Widget screen) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    return Navigator.of(context)
        .push<T>(MaterialPageRoute(builder: (_) => screen));
  }

  static void toTab(BuildContext context, int index) {
    context.read<ShellNavigation>().select(index);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  static void toTabAndPush(BuildContext context, int index, Widget screen) {
    final navigator = Navigator.of(context);
    context.read<ShellNavigation>().select(index);
    navigator.popUntil((route) => route.isFirst);
    navigator.push(MaterialPageRoute(builder: (_) => screen));
  }
}
