import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../widgets/anim.dart';
import '../../widgets/common.dart';
import 'dashboard_view.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final _items = <PaymentBatch>[];
  final _scroll = ScrollController();
  int _page = 0;
  bool _hasMore = true, _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) _loadMore();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _items.clear();
      _page = 0;
      _hasMore = true;
      _error = null;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final page = Paged.fromJson(await Api.instance.get('/payments', query: {'page': _page + 1}), PaymentBatch.fromJson);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _page = page.currentPage;
        _hasMore = page.hasMore;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _items.fold<double>(0, (s, b) => s + b.total);
    return Scaffold(
      appBar: AppBar(title: const Text('My payments')),
      body: RefreshIndicator(
        color: Brand.red,
        onRefresh: _reload,
        child: ListView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
          children: [
            FadeSlideIn(
              child: SoftCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(color: Brand.green.withOpacity(.12), shape: BoxShape.circle),
                      child: const Icon(Icons.south_west_rounded, color: Brand.greenDark),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total paid (shown below)', style: TextStyle(color: Brand.muted, fontSize: 13)),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: CountUp(key: ValueKey(total), value: total, decimals: 2, prefix: 'Rs. ', style: Brand.display(24, color: Brand.greenDark)),
                          ),
                          Text('${_items.length} payment${_items.length == 1 ? '' : 's'}${_hasMore ? '+' : ''}', style: const TextStyle(color: Brand.faint, fontSize: 12.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (_items.isEmpty && _loading)
              ...List.generate(5, (_) => const Padding(padding: EdgeInsets.only(bottom: 10), child: Shimmer(height: 80)))
            else if (_items.isEmpty && _error != null)
              ErrorView(message: _error!, onRetry: _reload)
            else if (_items.isEmpty)
              const EmptyState(emoji: '💵', title: 'No payments yet', message: 'Payments you make to Bake One will show up here.')
            else ...[
              for (final (i, b) in _items.indexed)
                FadeSlideIn(key: ValueKey(b.batchKey), delay: Duration(milliseconds: 40 * (i % 12)), child: PaymentTile(batch: b)),
              if (_hasMore) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: Brand.red, strokeWidth: 2.4))),
            ],
          ],
        ),
      ),
    );
  }
}
