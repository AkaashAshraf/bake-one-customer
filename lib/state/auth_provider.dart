import 'package:flutter/foundation.dart';

import '../core/api.dart';
import '../core/models.dart';

enum AuthStatus { unknown, guest, loggedIn }

class AuthProvider extends ChangeNotifier {
  AuthStatus status = AuthStatus.unknown;
  Customer? customer;

  bool get isLoggedIn => status == AuthStatus.loggedIn;

  AuthProvider() {
    Api.instance.onUnauthorized = () {
      if (status == AuthStatus.loggedIn) _clear();
    };
  }

  Future<void> restore() async {
    final token = await Api.instance.loadToken();
    if (token == null) {
      status = AuthStatus.guest;
      notifyListeners();
      return;
    }
    try {
      customer = Customer.fromJson(await Api.instance.get('/me'));
      status = AuthStatus.loggedIn;
    } on UnauthorizedException {
      await Api.instance.setToken(null);
      status = AuthStatus.guest;
    } catch (_) {
      // Offline at launch: keep the saved token, screens will retry.
      status = AuthStatus.loggedIn;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final res = await Api.instance.post('/login', {
      'email': email.trim(),
      'password': password,
      'device_name': 'Bake One app',
    });
    await Api.instance.setToken(res['token'] as String?);
    customer = Customer.fromJson((res['customer'] as Map<String, dynamic>?) ?? {});
    status = AuthStatus.loggedIn;
    notifyListeners();
  }

  void updateCustomer(Customer c) {
    customer = c;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await Api.instance.post('/logout');
    } catch (_) {}
    await _clear();
  }

  Future<void> _clear() async {
    await Api.instance.setToken(null);
    customer = null;
    status = AuthStatus.guest;
    notifyListeners();
  }
}
