import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../state/auth_provider.dart';
import '../../state/site_provider.dart';
import '../../widgets/anim.dart';
import '../../widgets/common.dart';
import '../../widgets/product_card.dart';
import '../account/invoices_screen.dart';
import '../account/payments_screen.dart';
import '../shell.dart';

/// App-style home: greeting, search, promo carousel, account summary,
/// categories, popular products and a product grid.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Dashboard? _summary;
  bool? _lastLoggedIn;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loggedIn = Provider.of<AuthProvider>(context).isLoggedIn;
    if (loggedIn != _lastLoggedIn) {
      _lastLoggedIn = loggedIn;
      _summary = null;
      if (loggedIn) WidgetsBinding.instance.addPostFrameCallback((_) => _loadSummary());
    }
  }

  Future<void> _loadSummary() async {
    try {
      final d = Dashboard.fromJson(await Api.instance.get('/dashboard'));
      if (mounted) setState(() => _summary = d);
    } catch (_) {}
  }

  Future<void> _refresh() async {
    final site = context.read<SiteProvider>();
    final loggedIn = context.read<AuthProvider>().isLoggedIn;
    await Future.wait([
      site.load(force: true),
      if (loggedIn) site.loadMine(force: true),
      if (loggedIn) _loadSummary(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final site = context.watch<SiteProvider>();
    final catalog = site.catalogFor(auth.isLoggedIn);
    final shell = ShellScope.of(context);

    if (catalog == null && site.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Brand.red)));
    }
    if (catalog == null && site.error != null) {
      return Scaffold(body: SafeArea(child: Center(child: ErrorView(message: site.error!, onRetry: () => site.load(force: true)))));
    }

    final products = catalog?.products ?? const <Product>[];
    final popular = [...products]..sort((a, b) {
        final d = (b.isDiscount ? 2 : 0) + (b.imageUrl != null ? 1 : 0) - (a.isDiscount ? 2 : 0) - (a.imageUrl != null ? 1 : 0);
        return d != 0 ? d : a.name.compareTo(b.name);
      });

    return Scaffold(
      backgroundColor: const Color(0xFFFCFAF9),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: Brand.red,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(child: _Header(customer: auth.customer, business: site.business)),
              SliverToBoxAdapter(child: _SearchPill(onTap: () {
                site.requestSearch();
                shell.goTo(Tabs.products);
              })),
              if (!auth.isLoggedIn) SliverToBoxAdapter(child: _PromoCarousel(slides: site.site?.slides ?? const [], loggedIn: false)),
              SliverToBoxAdapter(
                child: auth.isLoggedIn ? _AccountSummary(summary: _summary) : const _LoginPrompt(),
              ),
              if ((catalog?.categories ?? const []).isNotEmpty)
                SliverToBoxAdapter(child: _Categories(catalog: catalog!)),
              if (popular.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(title: auth.isLoggedIn ? 'Picked for you' : 'Popular now', onAll: () => shell.goTo(Tabs.products)),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 250,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: popular.length.clamp(0, 10),
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => SizedBox(width: 156, child: ProductCard(product: popular[i], index: i)),
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: _Perks()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: RedButton(label: 'Browse all products', icon: Icons.bakery_dining_rounded, expand: true, onPressed: () => shell.goTo(Tabs.products)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Header ─────────────────────────

class _Header extends StatelessWidget {
  final Customer? customer;
  final Business business;
  const _Header({required this.customer, required this.business});

  @override
  Widget build(BuildContext context) {
    final shell = ShellScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: FadeSlideIn(
              offset: const Offset(-20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${greeting()} 👋', style: const TextStyle(color: Brand.muted, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    customer != null ? customer!.firstName : 'Welcome to ${business.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Brand.display(24),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          FadeSlideIn(
            scaleFrom: .6,
            child: Pressable(
              onTap: () => shell.goTo(Tabs.account),
              child: customer != null
                  ? Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(gradient: Brand.buttonGradient, shape: BoxShape.circle, boxShadow: Brand.glow),
                      alignment: Alignment.center,
                      child: Text(customer!.initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      decoration: BoxDecoration(gradient: Brand.buttonGradient, borderRadius: BorderRadius.circular(99), boxShadow: Brand.glow),
                      child: const Row(children: [
                        Icon(Icons.login_rounded, color: Colors.white, size: 17),
                        SizedBox(width: 6),
                        Text('Log in', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: FadeSlideIn(
        delay: const Duration(milliseconds: 80),
        child: Pressable(
          scale: .98,
          onTap: onTap,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFEFE9E7)), boxShadow: Brand.card),
            child: const Row(
              children: [
                Icon(Icons.search_rounded, color: Brand.red),
                SizedBox(width: 10),
                Expanded(child: Text('Search bread, buns, cakes...', style: TextStyle(color: Brand.faint, fontSize: 15))),
                Icon(Icons.tune_rounded, color: Brand.faint, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Promo carousel ─────────────────────────

class _Promo {
  final String? imageUrl;
  final String title, subtitle, emoji;
  final List<Color> colors;
  const _Promo({this.imageUrl, required this.title, required this.subtitle, this.emoji = '🥐', this.colors = const [Brand.red, Brand.redDeep]});
}

class _PromoCarousel extends StatefulWidget {
  final List<Slide> slides;
  final bool loggedIn;
  const _PromoCarousel({required this.slides, required this.loggedIn});

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  final _page = PageController(viewportFraction: .9);
  int _index = 0;
  Timer? _timer;

  List<_Promo> get _promos {
    if (widget.slides.isNotEmpty) {
      return widget.slides.map((s) => _Promo(imageUrl: s.imageUrl, title: s.title ?? '', subtitle: s.subtitle ?? '')).toList();
    }
    return [
      const _Promo(title: 'Fresh from\nthe oven', subtitle: 'Baked every single morning', emoji: '🍞'),
      if (widget.loggedIn)
        const _Promo(title: 'Your special\nprices', subtitle: 'See what you save on every order', emoji: '🏷️', colors: [Color(0xFF10B981), Color(0xFF047857)])
      else
        const _Promo(title: 'Supplying\nyour shop?', subtitle: 'Daily bulk delivery for businesses', emoji: '🚚', colors: [Color(0xFFFF7A52), Color(0xFFE1251B)]),
      const _Promo(title: 'Sweet treats\nfor tea time', subtitle: 'Cakes, cupcakes and more', emoji: '🧁', colors: [Color(0xFFF59E0B), Color(0xFFEA580C)]),
    ];
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_page.hasClients) return;
      final n = _promos.length;
      if (n < 2) return;
      _page.animateToPage((_index + 1) % n, duration: const Duration(milliseconds: 650), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promos = _promos;
    final shell = ShellScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          SizedBox(
            height: 168,
            child: PageView.builder(
              controller: _page,
              itemCount: promos.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) {
                final p = promos[i];
                return AnimatedBuilder(
                  animation: _page,
                  builder: (_, child) {
                    double t = 0;
                    if (_page.hasClients && _page.position.haveDimensions) t = ((_page.page ?? 0) - i).abs().clamp(0.0, 1.0);
                    return Transform.scale(scale: 1 - t * .06, child: child);
                  },
                  child: Pressable(
                    scale: .98,
                    onTap: () => shell.goTo(Tabs.products),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: p.imageUrl == null ? LinearGradient(colors: p.colors, begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                        boxShadow: [BoxShadow(color: p.colors.first.withOpacity(.3), blurRadius: 18, offset: const Offset(0, 8), spreadRadius: -6)],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (p.imageUrl != null) ...[
                            Image.network(p.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Brand.red)),
                            if (p.title.isNotEmpty)
                              const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black54, Colors.transparent]))),
                          ] else ...[
                            Positioned(right: -30, top: -30, child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(.1)))),
                            Positioned(right: 18, bottom: 14, child: FloatingEmoji(p.emoji, size: 64, distance: 8)),
                          ],
                          if (p.title.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 14, 104, 14),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: SizedBox(
                                width: 200,
                                child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(p.title, style: Brand.display(24, color: Colors.white, height: 1.05)),
                                  const SizedBox(height: 8),
                                  Text(p.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
                                    child: Text('Shop now', style: TextStyle(color: p.colors.first, fontWeight: FontWeight.w600, fontSize: 12)),
                                  ),
                                ],
                              ),
                              ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < promos.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(color: i == _index ? Brand.red : const Color(0xFFE7DEDB), borderRadius: BorderRadius.circular(9)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Account ─────────────────────────

class _AccountSummary extends StatelessWidget {
  final Dashboard? summary;
  const _AccountSummary({required this.summary});

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final shell = ShellScope.of(context);
    final paid = s?.paidRatio ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      child: FadeSlideIn(
        delay: const Duration(milliseconds: 150),
        child: Column(
          children: [
            // ── Wallet card ──
            Container(
              decoration: BoxDecoration(gradient: Brand.redGradient, borderRadius: BorderRadius.circular(26), boxShadow: Brand.glow),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Stack(
                  children: [
                    Positioned(right: -40, top: -50, child: _Ring(size: 170, opacity: .10)),
                    Positioned(right: 30, bottom: -70, child: _Ring(size: 140, opacity: .07)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(color: Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(11)),
                                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 19),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text('Outstanding balance',
                                    style: TextStyle(color: Colors.white.withOpacity(.85), fontSize: 13, fontWeight: FontWeight.w500)),
                              ),
                              if (s != null) _GlassChip(
                                icon: s.unpaidCount > 0 ? Icons.schedule_rounded : Icons.check_circle_rounded,
                                label: s.unpaidCount > 0 ? '${s.unpaidCount} unpaid' : 'All paid',
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          s == null
                              ? Shimmer(height: 30, width: 170, radius: 8)
                              : FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: CountUp(
                                    value: s.outstanding,
                                    decimals: 2,
                                    prefix: 'Rs. ',
                                    style: Brand.display(30, color: Colors.white, weight: FontWeight.w800),
                                  ),
                                ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: paid),
                              duration: const Duration(milliseconds: 1100),
                              curve: Curves.easeOutCubic,
                              builder: (_, v, __) => LinearProgressIndicator(
                                value: v,
                                minHeight: 7,
                                backgroundColor: Colors.white.withOpacity(.22),
                                valueColor: const AlwaysStoppedAnimation(Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s == null ? ' ' : '${s.invoiceCount - s.unpaidCount} of ${s.invoiceCount} invoices paid',
                                  style: TextStyle(color: Colors.white.withOpacity(.85), fontSize: 12),
                                ),
                              ),
                              Pressable(
                                onTap: () => Navigator.of(context).push(fadeRoute(const InvoicesScreen())),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('View', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
                                    SizedBox(width: 2),
                                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // ── Quick actions ──
            Row(
              children: [
                _QuickAction(
                  icon: Icons.receipt_long_rounded,
                  label: 'Invoices',
                  color: Brand.red,
                  onTap: () => Navigator.of(context).push(fadeRoute(const InvoicesScreen())),
                ),
                _QuickAction(
                  icon: Icons.payments_rounded,
                  label: 'Payments',
                  color: const Color(0xFF059669),
                  onTap: () => Navigator.of(context).push(fadeRoute(const PaymentsScreen())),
                ),
                _QuickAction(
                  icon: Icons.local_offer_rounded,
                  label: 'My prices',
                  color: const Color(0xFFEA580C),
                  badge: (s?.specialPriceCount ?? 0) > 0 ? '${s!.specialPriceCount}' : null,
                  onTap: () {
                    context.read<SiteProvider>().requestCategory(null, specialOnly: true);
                    shell.goTo(Tabs.products);
                  },
                ),
                _QuickAction(
                  icon: Icons.person_rounded,
                  label: 'Account',
                  color: const Color(0xFF7C3AED),
                  onTap: () => shell.goTo(Tabs.account),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double size, opacity;
  const _Ring({required this.size, required this.opacity});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(opacity)),
      );
}

class _GlassChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _GlassChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.18),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.white.withOpacity(.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? badge;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Pressable(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(.12)),
              boxShadow: [BoxShadow(color: color.withOpacity(.10), blurRadius: 16, offset: const Offset(0, 8), spreadRadius: -6)],
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [color.withOpacity(.85), color],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: color.withOpacity(.35), blurRadius: 12, offset: const Offset(0, 6), spreadRadius: -4)],
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    if (badge != null)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          constraints: const BoxConstraints(minWidth: 18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: color, width: 1.4),
                          ),
                          child: Text(badge!, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Brand.ink)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      child: FadeSlideIn(
        delay: const Duration(milliseconds: 150),
        child: Pressable(
          scale: .98,
          onTap: () => ShellScope.of(context).goTo(Tabs.account),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Brand.soft, borderRadius: BorderRadius.circular(22), border: Border.all(color: Brand.red.withOpacity(.15))),
            child: const Row(
              children: [
                Text('🔑', style: TextStyle(fontSize: 28)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bake One customer?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      SizedBox(height: 2),
                      Text('Log in to see your prices, invoices and payments.', style: TextStyle(color: Brand.muted, fontSize: 12.5)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Brand.red),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Categories ─────────────────────────

class _Categories extends StatelessWidget {
  final Catalog catalog;
  const _Categories({required this.catalog});

  @override
  Widget build(BuildContext context) {
    final shell = ShellScope.of(context);
    final cats = catalog.categories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Categories', onAll: () => shell.goTo(Tabs.products)),
        SizedBox(
          height: 104,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final inCat = catalog.products.where((p) => p.category == cats[i]).toList();
              final sample = inCat.where((p) => p.imageUrl != null).isNotEmpty ? inCat.firstWhere((p) => p.imageUrl != null) : (inCat.isNotEmpty ? inCat.first : null);
              return FadeSlideIn(
                delay: Duration(milliseconds: 200 + 60 * i),
                scaleFrom: .7,
                offset: Offset.zero,
                child: Pressable(
                  onTap: () {
                    context.read<SiteProvider>().requestCategory(cats[i]);
                    shell.goTo(Tabs.products);
                  },
                  child: SizedBox(
                    width: 72,
                    child: Column(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: Brand.line), boxShadow: Brand.card),
                          clipBehavior: Clip.antiAlias,
                          child: sample == null
                              ? Center(child: Text(emojiFor(i), style: const TextStyle(fontSize: 30)))
                              : ProductArt(product: sample, emojiSize: 30),
                        ),
                        const SizedBox(height: 7),
                        Text(cats[i], maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Bits ─────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAll;
  const _SectionHeader({required this.title, this.onAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 12, 10),
      child: Row(
        children: [
          Text(title, style: Brand.display(21)),
          const Spacer(),
          if (onAll != null)
            TextButton(
              onPressed: onAll,
              child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('See all'), SizedBox(width: 2), Icon(Icons.arrow_forward_rounded, size: 16)]),
            ),
        ],
      ),
    );
  }
}

class _Perks extends StatelessWidget {
  const _Perks();

  @override
  Widget build(BuildContext context) {
    const perks = [
      (Icons.local_fire_department_rounded, 'Baked daily'),
      (Icons.verified_user_rounded, 'Hygienic'),
      (Icons.local_shipping_rounded, 'On-time delivery'),
      (Icons.grass_rounded, 'Quality ingredients'),
    ];
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        scrollDirection: Axis.horizontal,
        itemCount: perks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99), border: Border.all(color: Brand.line)),
          child: Row(
            children: [
              Icon(perks[i].$1, color: Brand.red, size: 17),
              const SizedBox(width: 6),
              Text(perks[i].$2, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
