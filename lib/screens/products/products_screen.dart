import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/theme.dart';
import '../../state/auth_provider.dart';
import '../../state/site_provider.dart';
import '../../widgets/anim.dart';
import '../../widgets/common.dart';
import '../../widgets/product_card.dart';

/// Product catalogue with a pinned search + category bar. Logged-in
/// customers see their own prices and a "My special prices" filter.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';
  String _category = 'All';
  bool _specialOnly = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final site = Provider.of<SiteProvider>(context);
    if (site.requestedCategory != null || site.requestSpecialOnly || site.requestSearchFocus) {
      final cat = site.requestedCategory;
      final special = site.requestSpecialOnly;
      final focus = site.requestSearchFocus;
      site.clearRequest();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _category = cat ?? 'All';
          _specialOnly = special;
        });
        if (focus) _searchFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final site = context.read<SiteProvider>();
    if (context.read<AuthProvider>().isLoggedIn) {
      await site.loadMine(force: true);
    } else {
      await site.load(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;
    final site = context.watch<SiteProvider>();
    final catalog = site.catalogFor(loggedIn);
    final loading = catalog == null && (site.loading || site.myLoading);
    final error = loggedIn ? site.myError : site.error;

    final all = catalog?.products ?? const <Product>[];
    final categories = ['All', ...?catalog?.categories];
    final specialCount = all.where((p) => p.isDiscount).length;

    final shown = all.where((p) {
      if (_query.isNotEmpty && !p.name.toLowerCase().contains(_query)) return false;
      if (_category != 'All' && p.category != _category) return false;
      if (_specialOnly && !p.isDiscount) return false;
      return true;
    }).toList();

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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                  child: FadeSlideIn(
                    offset: const Offset(-20, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Products', style: Brand.display(28)),
                              Text(
                                loggedIn ? 'Showing your prices' : 'Fresh every day',
                                style: TextStyle(color: loggedIn ? Brand.greenDark : Brand.muted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        if (loggedIn && specialCount > 0)
                          Pulse(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(99)),
                              child: Text('$specialCount special ${specialCount == 1 ? 'price' : 'prices'}', style: const TextStyle(color: Brand.greenDark, fontWeight: FontWeight.w600, fontSize: 12)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _FilterHeader(
                  child: Column(
                    children: [
                      TextField(
                        controller: _search,
                        focusNode: _searchFocus,
                        textInputAction: TextInputAction.search,
                        onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                        decoration: InputDecoration(
                          hintText: 'Search bread, buns, cakes...',
                          prefixIcon: const Icon(Icons.search_rounded, color: Brand.red),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () => setState(() {
                                    _search.clear();
                                    _query = '';
                                  }),
                                ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEFE9E7))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEFE9E7))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Brand.red, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            if (loggedIn && specialCount > 0)
                              _Chip(
                                label: 'My prices',
                                icon: Icons.local_offer_rounded,
                                selected: _specialOnly,
                                green: true,
                                onTap: () => setState(() => _specialOnly = !_specialOnly),
                              ),
                            for (final c in categories) _Chip(label: c, selected: _category == c, onTap: () => setState(() => _category = c)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (loading)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid.count(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .66, children: List.generate(6, (_) => const Shimmer(height: 200, radius: 24))),
                )
              else if (catalog == null && error != null)
                SliverToBoxAdapter(child: ErrorView(message: error, onRetry: _refresh))
              else if (shown.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(
                    emoji: '🔍',
                    title: 'No products match',
                    message: 'Try another search or category.',
                    action: OutlinedButton(
                      onPressed: () => setState(() {
                        _search.clear();
                        _query = '';
                        _category = 'All';
                        _specialOnly = false;
                      }),
                      child: const Text('SHOW ALL'),
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 2),
                    child: Text('${shown.length} ${shown.length == 1 ? 'item' : 'items'}', style: const TextStyle(color: Brand.faint, fontSize: 12.5)),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .66),
                    delegate: SliverChildBuilderDelegate(
                      // Keyed by the filter so the cards pop in again when it changes.
                      (_, i) => ProductCard(key: ValueKey('${shown[i].id}-$_category-$_specialOnly'), product: shown[i], index: i),
                      childCount: shown.length,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool green;
  final IconData? icon;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.selected, required this.onTap, this.green = false, this.icon});

  @override
  Widget build(BuildContext context) {
    final color = green ? Brand.greenDark : Brand.red;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: selected ? color : const Color(0xFFEFE9E7)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 15, color: selected ? Colors.white : color), const SizedBox(width: 5)],
              Text(label, style: TextStyle(color: selected ? Colors.white : Brand.ink, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, fontSize: 13.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterHeader extends SliverPersistentHeaderDelegate {
  final Widget child;
  _FilterHeader({required this.child});

  @override
  double get minExtent => 128;
  @override
  double get maxExtent => 128;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final raised = overlapsContent || shrinkOffset > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFAF9),
        border: Border(bottom: BorderSide(color: raised ? const Color(0xFFEFE9E7) : Colors.transparent)),
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _FilterHeader oldDelegate) => true;
}
