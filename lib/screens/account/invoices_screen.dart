import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../widgets/anim.dart';
import '../../widgets/common.dart';
import 'dashboard_view.dart';

class InvoicesScreen extends StatefulWidget {
  /// 'all', 'unpaid' or 'paid'.
  final String initialStatus;
  const InvoicesScreen({super.key, this.initialStatus = 'all'});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _items = <Invoice>[];
  final _scroll = ScrollController();
  String _status = 'all';
  String _search = '';
  int _page = 0;
  bool _hasMore = true, _loading = false;
  int _total = 0;
  String? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) _loadMore();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    _generation++;
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
    final gen = _generation;
    setState(() => _loading = true);
    try {
      final res = await Api.instance.get('/invoices', query: {
        'page': _page + 1,
        'status': _status == 'all' ? null : _status,
        'search': _search,
      });
      if (!mounted || gen != _generation) return;
      final page = Paged.fromJson(res, Invoice.fromJson);
      setState(() {
        _items.addAll(page.items);
        _page = page.currentPage;
        _hasMore = page.hasMore;
        _total = page.total;
      });
    } catch (e) {
      if (mounted && gen == _generation) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My invoices')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: TextField(
              textInputAction: TextInputAction.search,
              onSubmitted: (v) {
                _search = v.trim();
                _reload();
              },
              decoration: InputDecoration(
                hintText: 'Search invoice number',
                prefixIcon: const Icon(Icons.search_rounded, color: Brand.red),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(99)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(99), borderSide: const BorderSide(color: Color(0xFFE7E5E4))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(99), borderSide: const BorderSide(color: Brand.red, width: 1.5)),
              ),
            ),
          ),
          _Segmented(
            value: _status,
            options: const {'all': 'All', 'unpaid': 'Unpaid', 'paid': 'Paid'},
            onChanged: (v) {
              _status = v;
              _reload();
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(_items.isEmpty && _loading ? ' ' : '$_total invoice${_total == 1 ? '' : 's'}', key: ValueKey('$_status$_total'), style: const TextStyle(color: Brand.faint)),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: Brand.red,
              onRefresh: _reload,
              child: _items.isEmpty && _loading
                  ? ListView(padding: const EdgeInsets.all(16), children: List.generate(6, (_) => const Padding(padding: EdgeInsets.only(bottom: 10), child: Shimmer(height: 74))))
                  : _items.isEmpty && _error != null
                      ? ListView(children: [ErrorView(message: _error!, onRetry: _reload)])
                      : _items.isEmpty
                          ? ListView(children: const [EmptyState(emoji: '🧾', title: 'No invoices', message: 'Invoices raised on your account will show up here.')])
                          : ListView.builder(
                              controller: _scroll,
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
                              itemCount: _items.length + (_hasMore ? 1 : 0),
                              itemBuilder: (_, i) {
                                if (i >= _items.length) {
                                  return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: Brand.red, strokeWidth: 2.4)));
                                }
                                return FadeSlideIn(
                                  key: ValueKey('${_items[i].id}-$_status-$_generation'),
                                  delay: Duration(milliseconds: 40 * (i % 12)),
                                  offset: const Offset(0, 24),
                                  child: InvoiceTile(invoice: _items[i]),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  const _Segmented({required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final keys = options.keys.toList();
    final index = keys.indexOf(value);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Brand.soft, borderRadius: BorderRadius.circular(99)),
        child: LayoutBuilder(
          builder: (_, c) {
            final w = c.maxWidth / keys.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  left: w * index,
                  top: 0,
                  bottom: 0,
                  width: w,
                  child: Container(decoration: BoxDecoration(gradient: Brand.buttonGradient, borderRadius: BorderRadius.circular(99), boxShadow: Brand.glow)),
                ),
                Row(
                  children: [
                    for (final k in keys)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onChanged(k),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 250),
                              style: TextStyle(color: k == value ? Colors.white : Brand.muted, fontWeight: k == value ? FontWeight.w600 : FontWeight.w400),
                              child: Text(options[k]!),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
