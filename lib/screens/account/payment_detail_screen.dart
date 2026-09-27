import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../widgets/anim.dart';
import '../../widgets/common.dart';
import 'dashboard_view.dart';

class PaymentDetailScreen extends StatefulWidget {
  final String batchKey;
  const PaymentDetailScreen({super.key, required this.batchKey});

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  PaymentDetail? _d;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final d = PaymentDetail.fromJson(await Api.instance.get('/payments/${Uri.encodeComponent(widget.batchKey)}'));
      if (mounted) setState(() => _d = d);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment details')),
      body: d == null
          ? (_error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : ListView(padding: const EdgeInsets.all(16), children: const [Shimmer(height: 200, radius: 30), SizedBox(height: 14), Shimmer(height: 80), SizedBox(height: 10), Shimmer(height: 80)]))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
              children: [
                FadeSlideIn(
                  scaleFrom: .95,
                  child: SoftCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Pulse(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(color: Brand.green.withOpacity(.12), shape: BoxShape.circle),
                            child: const Icon(Icons.check_rounded, color: Brand.greenDark, size: 30),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Payment received', style: TextStyle(color: Brand.muted)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: CountUp(value: d.total, decimals: 2, prefix: 'Rs. ', style: Brand.display(32, color: Brand.greenDark)),
                        ),
                        const SizedBox(height: 4),
                        Text(formatDateTime(d.collectedAt), style: const TextStyle(color: Brand.faint, fontSize: 13)),
                        if (d.notes != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFFF7F5F4), borderRadius: BorderRadius.circular(12)),
                            child: Text(d.notes!, style: const TextStyle(color: Brand.muted)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 150),
                  child: Text(d.lines.length > 1 ? 'Applied to ${d.lines.length} invoices' : 'Applied to this invoice', style: Brand.display(21)),
                ),
                const SizedBox(height: 12),
                for (final (i, line) in d.lines.indexed)
                  FadeSlideIn(
                    delay: Duration(milliseconds: 220 + 70 * i),
                    offset: const Offset(30, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (line.invoice != null) InvoiceTile(invoice: line.invoice!),
                        Padding(
                          padding: const EdgeInsets.only(left: 14, bottom: 14, top: 0),
                          child: Row(
                            children: [
                              const Icon(Icons.subdirectory_arrow_right_rounded, size: 18, color: Brand.faint),
                              const SizedBox(width: 6),
                              Flexible(child: Text('${money(line.amount)} applied from this payment', style: const TextStyle(color: Brand.greenDark, fontWeight: FontWeight.w500))),
                              const SizedBox(width: 8),
                              StatusChip(line.isPartial ? 'Partial' : 'Paid off', color: line.isPartial ? Brand.amber : Brand.greenDark),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
