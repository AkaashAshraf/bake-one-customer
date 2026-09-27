import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../state/auth_provider.dart';
import '../state/site_provider.dart';
import 'account/account_screen.dart';
import 'contact/contact_screen.dart';
import 'home/home_screen.dart';
import 'products/products_screen.dart';

/// Lets any screen switch the bottom tab (e.g. "Explore products").
class ShellScope extends InheritedWidget {
  final void Function(int index) goTo;
  const ShellScope({super.key, required this.goTo, required super.child});

  static ShellScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ShellScope>()!;

  @override
  bool updateShouldNotify(ShellScope oldWidget) => false;
}

class Tabs {
  static const home = 0, products = 1, account = 2, more = 3;
  static const contact = more;
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;
  final _visited = <int>{0};
  bool? _lastLoggedIn;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load / clear the customer's own price list when they log in or out.
    final loggedIn = Provider.of<AuthProvider>(context).isLoggedIn;
    if (loggedIn != _lastLoggedIn) {
      _lastLoggedIn = loggedIn;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final site = context.read<SiteProvider>();
        loggedIn ? site.loadMine(force: true) : site.clearMine();
      });
    }
  }

  void _goTo(int i) {
    if (i == _index) return;
    setState(() {
      _index = i;
      _visited.add(i);
    });
  }

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.bakery_dining_outlined, Icons.bakery_dining_rounded, 'Products'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Account'),
    (Icons.grid_view_outlined, Icons.grid_view_rounded, 'More'),
  ];

  Widget _page(int i) {
    // Build tabs lazily the first time they're opened, then keep them alive.
    if (!_visited.contains(i)) return const SizedBox.shrink();
    switch (i) {
      case Tabs.home:
        return const HomeScreen();
      case Tabs.products:
        return const ProductsScreen();
      case Tabs.account:
        return const AccountScreen();
      default:
        return const MoreScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShellScope(
      goTo: _goTo,
      child: PopScope(
        canPop: _index == 0,
        // ignore: deprecated_member_use
        onPopInvoked: (didPop) {
          if (!didPop) _goTo(0);
        },
        child: Scaffold(
          body: IndexedStack(
            index: _index,
            // TickerMode pauses every animation on the tabs you can't see.
            children: List.generate(4, (i) => TickerMode(enabled: i == _index, child: _page(i))),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 20, offset: const Offset(0, -4))],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Row(
                  children: [
                    for (var i = 0; i < _items.length; i++)
                      Expanded(child: _NavItem(icon: _items[i].$1, activeIcon: _items[i].$2, label: _items[i].$3, active: _index == i, onTap: () => _goTo(i))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            // No overshooting curve here: it would briefly make the shadow's
            // blur negative while animating, which Flutter doesn't allow.
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(horizontal: active ? 20 : 12, vertical: 7),
            decoration: BoxDecoration(
              gradient: active ? Brand.buttonGradient : null,
              borderRadius: BorderRadius.circular(99),
              boxShadow: active ? [BoxShadow(color: Brand.red.withOpacity(.35), blurRadius: 14, offset: const Offset(0, 6))] : null,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Icon(active ? activeIcon : icon, key: ValueKey(active), color: active ? Colors.white : Brand.muted, size: 23),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: TextStyle(fontSize: 11.5, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? Brand.red : Brand.muted),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}
