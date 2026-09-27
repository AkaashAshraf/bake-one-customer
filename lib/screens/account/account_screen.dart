import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import 'dashboard_view.dart';
import 'login_view.dart';

/// "My Account" tab: login form for guests, dashboard once logged in.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: Tween(begin: .97, end: 1.0).animate(a), child: child),
      ),
      child: auth.isLoggedIn ? const DashboardView(key: ValueKey('dash')) : const LoginView(key: ValueKey('login')),
    );
  }
}
