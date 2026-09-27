import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../state/auth_provider.dart';
import '../../state/site_provider.dart';
import '../../widgets/anim.dart';
import '../../widgets/common.dart';
import '../shell.dart';
import 'invoice_detail_screen.dart';
import 'invoices_screen.dart';
import 'payment_detail_screen.dart';
import 'payments_screen.dart';
import 'profile_screen.dart';

/// Clean, banking-app style account overview.
class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  Dashboard? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    // Read the provider before the network call - after an await this
    // widget might already be gone (e.g. right after logging in/out).
    final auth = context.read<AuthProvider>();
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final d = Dashboard.fromJson(await Api.instance.get('/dashboard'));
      if (!mounted) return;
      setState(() => _data = d);
      auth.updateCustomer(d.customer);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _open(Widget page) => Navigator.of(context).push(fadeRoute(page)).then((_) => _load());

  @override
  Widget build(BuildContext context) {
    final customer = context.watch<AuthProvider>().customer;
    final d = _data;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F4),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: Brand.red,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            children: [
              _Greeting(customer: customer, onProfile: () => _open(const ProfileScreen())),
              const SizedBox(height: 18),
              if (_loading) ...[
                const Shimmer(height: 190, radius: 24),
                const SizedBox(height: 12),
                const Shimmer(height: 84, radius: 20),
                const SizedBox(height: 12),
                const Shimmer(height: 220, radius: 20),
              ] else if (d == null && _error != null)
                ErrorView(message: _error!, onRetry: _load)
              else if (d != null) ...[
                FadeSlideIn(
                  child: _BalanceCard(
                    d: d,
                    onInvoices: () => _open(const InvoicesScreen()),
                    onPayments: () => _open(const PaymentsScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(delay: const Duration(milliseconds: 80), child: _StatTiles(d: d)),
                const SizedBox(height: 22),
                FadeSlideIn(delay: const Duration(milliseconds: 140), child: const _QuickActions()),
                const SizedBox(height: 26),
                _SectionTitle(
                  title: 'Needs attention',
                  trailing: d.unpaidCount > 0 ? '${d.unpaidCount} unpaid' : null,
                  onAll: d.unpaidCount > 0 ? () => _open(const InvoicesScreen(initialStatus: 'unpaid')) : null,
                ),
                const SizedBox(height: 10),
                if (d.unpaidInvoices.isEmpty)
                  const _AllClear()
                else
                  _Card(
                    child: Column(
                      children: [
                        for (final (i, inv) in d.unpaidInvoices.indexed) ...[
                          if (i > 0) const Divider(height: 1, indent: 64, color: Color(0xFFF1ECEA)),
                          FadeSlideIn(
                            delay: Duration(milliseconds: 180 + 50 * i),
                            offset: const Offset(0, 14),
                            child: _DueRow(invoice: inv, onTap: () => _open(InvoiceDetailScreen(invoiceId: inv.id, number: inv.number))),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 26),
                _SectionTitle(title: 'Recent activity', onAll: () => _open(const InvoicesScreen())),
                const SizedBox(height: 10),
                _Activity(d: d, open: _open),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Header ─────────────────────────

class _Greeting extends StatelessWidget {
  final Customer? customer;
  final VoidCallback onProfile;
  const _Greeting({required this.customer, required this.onProfile});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Pressable(
          onTap: onProfile,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(gradient: Brand.buttonGradient, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: Brand.card),
            alignment: Alignment.center,
            child: Text(customer?.initial ?? '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${greeting()},', style: const TextStyle(color: Brand.muted, fontSize: 13.5)),
              Text(customer?.firstName ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: Brand.display(22)),
            ],
          ),
        ),
        Text(DateFormat('EEE, d MMM').format(DateTime.now()), style: const TextStyle(color: Brand.faint, fontSize: 12.5)),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Profile',
          onPressed: onProfile,
          icon: const Icon(Icons.settings_outlined, color: Brand.muted),
        ),
      ],
    );
  }
}

// ───────────────────────── Balance ─────────────────────────

class _BalanceCard extends StatelessWidget {
  final Dashboard d;
  final VoidCallback onInvoices, onPayments;
  const _BalanceCard({required this.d, required this.onInvoices, required this.onPayments});

  @override
  Widget build(BuildContext context) {
    final clear = d.outstanding <= 0;
    return _Card(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Amount due', style: TextStyle(color: Brand.muted, fontWeight: FontWeight.w500)),
              const Spacer(),
              StatusChip(
                clear ? 'All paid' : '${d.unpaidCount} unpaid',
                color: clear ? Brand.greenDark : Brand.red,
                icon: clear ? Icons.check_circle_rounded : Icons.schedule_rounded,
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CountUp(
              value: d.outstanding,
              decimals: 2,
              prefix: 'Rs. ',
              style: Brand.display(34, color: clear ? Brand.greenDark : Brand.ink),
            ),
          ),
          const SizedBox(height: 14),
          if (d.invoiceCount > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Container(
                height: 8,
                color: const Color(0xFFF1ECEA),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: d.paidRatio),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: v,
                      child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), gradient: const LinearGradient(colors: [Color(0xFF34D399), Brand.green]))),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text('${d.invoiceCount - d.unpaidCount} of ${d.invoiceCount} invoices paid', style: const TextStyle(color: Brand.faint, fontSize: 12)),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(child: _CardButton(icon: Icons.receipt_long_rounded, label: 'Invoices', filled: true, onTap: onInvoices)),
              const SizedBox(width: 10),
              Expanded(child: _CardButton(icon: Icons.history_rounded, label: 'Payments', onTap: onPayments)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _CardButton({required this.icon, required this.label, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: filled ? Brand.red : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: filled ? Brand.red : const Color(0xFFE7E1DF)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: filled ? Colors.white : Brand.ink),
            const SizedBox(width: 7),
            Text(label, style: TextStyle(color: filled ? Colors.white : Brand.ink, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _StatTiles extends StatelessWidget {
  final Dashboard d;
  const _StatTiles({required this.d});

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, Color color, String value, String label) => Expanded(
          child: _Card(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(11)),
                  child: Icon(icon, color: color, size: 19),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Brand.faint, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
    return Row(
      children: [
        tile(Icons.schedule_rounded, Brand.red, '${d.unpaidCount}', 'Unpaid'),
        const SizedBox(width: 10),
        tile(Icons.receipt_long_rounded, const Color(0xFF3B82F6), '${d.invoiceCount}', 'Invoices'),
        const SizedBox(width: 10),
        tile(Icons.local_offer_rounded, Brand.greenDark, '${d.specialPriceCount}', 'Your prices'),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final shell = ShellScope.of(context);
    final List<(IconData, String, Color, VoidCallback)> items = [
      (Icons.bakery_dining_rounded, 'Products', Brand.red, () => shell.goTo(Tabs.products)),
      (
        Icons.local_offer_rounded,
        'My prices',
        Brand.greenDark,
        () {
          context.read<SiteProvider>().requestCategory(null, specialOnly: true);
          shell.goTo(Tabs.products);
        }
      ),
      (Icons.picture_as_pdf_rounded, 'Statements', const Color(0xFF3B82F6), () => Navigator.of(context).push(fadeRoute(const InvoicesScreen()))),
      (Icons.support_agent_rounded, 'Help', const Color(0xFFF59E0B), () => shell.goTo(Tabs.more)),
    ];
    return Row(
      children: [
        for (final it in items)
          Expanded(
            child: Pressable(
              onTap: it.$4,
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: Brand.card),
                    child: Icon(it.$1, color: it.$3, size: 25),
                  ),
                  const SizedBox(height: 7),
                  Text(it.$2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ───────────────────────── Lists ─────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _Card({required this.child, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onAll;
  const _SectionTitle({required this.title, this.trailing, this.onAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Text(trailing!, style: const TextStyle(color: Brand.red, fontSize: 12.5, fontWeight: FontWeight.w500)),
        ],
        const Spacer(),
        if (onAll != null)
          GestureDetector(
            onTap: onAll,
            child: const Text('See all', style: TextStyle(color: Brand.red, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
      ],
    );
  }
}

class _DueRow extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;
  const _DueRow({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final i = invoice;
    final date = parseDate(i.date);
    final days = date == null ? null : DateTime.now().difference(date).inDays;
    final old = (days ?? 0) > 30;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: (old ? Brand.red : Brand.amber).withOpacity(.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.receipt_long_rounded, color: old ? Brand.red : Brand.amber, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(i.number, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    days == null ? formatDate(i.date) : (days <= 0 ? 'Today' : '$days ${days == 1 ? 'day' : 'days'} ago'),
                    style: TextStyle(color: old ? Brand.red : Brand.faint, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(money(i.balanceDue), style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('of ${money(i.total)}', style: const TextStyle(color: Brand.faint, fontSize: 11.5)),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: Brand.faint),
          ],
        ),
      ),
    );
  }
}

class _AllClear extends StatelessWidget {
  const _AllClear();

  @override
  Widget build(BuildContext context) => _Card(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: Brand.green.withOpacity(.12), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Brand.greenDark),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("You're all caught up", style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('No unpaid invoices right now.', style: TextStyle(color: Brand.faint, fontSize: 12.5)),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Invoices and payments together, newest first.
class _Activity extends StatelessWidget {
  final Dashboard d;
  final void Function(Widget) open;
  const _Activity({required this.d, required this.open});

  @override
  Widget build(BuildContext context) {
    final items = <(DateTime, Widget)>[
      for (final i in d.recentInvoices)
        (
          parseDate(i.date) ?? DateTime(2000),
          _ActivityRow(
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFF3B82F6),
            title: 'Invoice ${i.number}',
            subtitle: formatDate(i.date),
            amount: money(i.total),
            amountColor: Brand.ink,
            badge: i.isPaid ? null : 'Unpaid',
            onTap: () => open(InvoiceDetailScreen(invoiceId: i.id, number: i.number)),
          ),
        ),
      for (final b in d.recentPayments)
        (
          parseDate(b.collectedAt) ?? DateTime(2000),
          _ActivityRow(
            icon: Icons.south_west_rounded,
            color: Brand.greenDark,
            title: 'Payment received',
            subtitle: '${formatDate(b.collectedAt)} · ${b.invoiceCount == 1 ? '1 invoice' : '${b.invoiceCount} invoices'}',
            amount: '+ ${money(b.total)}',
            amountColor: Brand.greenDark,
            onTap: () => open(PaymentDetailScreen(batchKey: b.batchKey)),
          ),
        ),
    ]..sort((a, b) => b.$1.compareTo(a.$1));

    if (items.isEmpty) {
      return const _Card(padding: EdgeInsets.all(18), child: Text('No activity yet.', style: TextStyle(color: Brand.faint)));
    }

    final shown = items.take(8).toList();
    return _Card(
      child: Column(
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 64, color: Color(0xFFF1ECEA)),
            FadeSlideIn(delay: Duration(milliseconds: 220 + 40 * i), offset: const Offset(0, 12), child: shown[i].$2),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final Color color, amountColor;
  final String title, subtitle, amount;
  final String? badge;
  final VoidCallback onTap;

  const _ActivityRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withOpacity(.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Brand.faint, fontSize: 12.5)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amount, style: TextStyle(fontWeight: FontWeight.w700, color: amountColor)),
                if (badge != null) Text(badge!, style: const TextStyle(color: Brand.red, fontSize: 11.5, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Shared tiles (used by other screens) ─────────────────────────

/// One invoice row, reused by the invoices list and payment detail.
class InvoiceTile extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback? onChanged;
  const InvoiceTile({super.key, required this.invoice, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final i = invoice;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pressable(
        onTap: () => Navigator.of(context).push(fadeRoute(InvoiceDetailScreen(invoiceId: i.id, number: i.number))),
        child: _Card(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: i.isPaid ? const Color(0xFFECFDF5) : Brand.soft, borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.receipt_long_rounded, color: i.isPaid ? Brand.greenDark : Brand.red),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(i.number, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('${formatDate(i.date)} · ${i.typeLabel}', style: const TextStyle(color: Brand.faint, fontSize: 12.5)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(money(i.total), style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  StatusChip.paid(i.isPaid),
                ],
              ),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right_rounded, color: Brand.faint),
            ],
          ),
        ),
      ),
    );
  }
}

/// One received payment (batch) row.
class PaymentTile extends StatelessWidget {
  final PaymentBatch batch;
  const PaymentTile({super.key, required this.batch});

  @override
  Widget build(BuildContext context) {
    final b = batch;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pressable(
        onTap: () => Navigator.of(context).push(fadeRoute(PaymentDetailScreen(batchKey: b.batchKey))),
        child: _Card(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.south_west_rounded, color: Brand.greenDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(money(b.total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Brand.greenDark)),
                    const SizedBox(height: 2),
                    Text(formatDate(b.collectedAt), style: const TextStyle(color: Brand.faint, fontSize: 12.5)),
                    if (b.invoiceNumbers != null)
                      Text(b.invoiceNumbers!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Brand.muted, fontSize: 12)),
                  ],
                ),
              ),
              StatusChip(b.isPartial ? 'Partial' : 'Fully paid', color: b.isPartial ? Brand.amber : Brand.greenDark),
              const Icon(Icons.chevron_right_rounded, color: Brand.faint),
            ],
          ),
        ),
      ),
    );
  }
}
