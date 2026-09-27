import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../state/auth_provider.dart';
import '../../widgets/anim.dart';
import '../../widgets/common.dart';
import 'invoice_pdf.dart';
import 'payment_detail_screen.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;
  final String number;
  const InvoiceDetailScreen({super.key, required this.invoiceId, required this.number});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  InvoiceDetail? _d;
  String? _error;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final d = InvoiceDetail.fromJson(await Api.instance.get('/invoices/${widget.invoiceId}'));
      if (mounted) setState(() => _d = d);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _share() async {
    final d = _d;
    if (d == null) return;
    setState(() => _sharing = true);
    try {
      await shareInvoicePdf(d, customerName: context.read<AuthProvider>().customer?.name);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't create the PDF: $e")));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.number),
        actions: [
          if (d != null)
            IconButton(
              tooltip: 'Share PDF',
              onPressed: _sharing ? null : _share,
              icon: _sharing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Brand.red)) : const Icon(Icons.ios_share_rounded, color: Brand.red),
            ),
        ],
      ),
      body: d == null
          ? (_error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : ListView(padding: const EdgeInsets.all(16), children: const [Shimmer(height: 190, radius: 30), SizedBox(height: 14), Shimmer(height: 260), SizedBox(height: 14), Shimmer(height: 120)]))
          : RefreshIndicator(
              color: Brand.red,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                children: [
                  FadeSlideIn(child: _Header(d: d)),
                  const SizedBox(height: 18),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: SoftCard(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Items', style: Brand.display(20)),
                          const SizedBox(height: 10),
                          for (final (i, it) in d.items.indexed)
                            FadeSlideIn(
                              delay: Duration(milliseconds: 200 + 50 * i),
                              offset: const Offset(20, 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(border: i == d.items.length - 1 ? null : const Border(bottom: BorderSide(color: Brand.line))),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(color: Brand.soft, borderRadius: BorderRadius.circular(11)),
                                      child: Text('${it.quantity}', style: const TextStyle(color: Brand.red, fontWeight: FontWeight.w700)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(it.productName, style: const TextStyle(fontWeight: FontWeight.w500)),
                                          Text('${money(it.unitPrice)}${it.unit != null ? ' / ${it.unit}' : ''}', style: const TextStyle(color: Brand.faint, fontSize: 12.5)),
                                        ],
                                      ),
                                    ),
                                    Text(money(it.lineTotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          const Divider(color: Brand.line, height: 22),
                          _TotalRow('Total', money(d.invoice.total), bold: true),
                          _TotalRow('Paid', money(d.paid), color: Brand.greenDark),
                          _TotalRow('Balance due', money(d.invoice.balanceDue), color: d.invoice.balanceDue > 0 ? Brand.red : Brand.faint, bold: true),
                        ],
                      ),
                    ),
                  ),
                  if (d.payments.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 240),
                      child: SoftCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Payments on this invoice', style: Brand.display(19)),
                            const SizedBox(height: 8),
                            for (final p in d.payments)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                onTap: () => Navigator.of(context).push(fadeRoute(PaymentDetailScreen(batchKey: p.batchKey))),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(13)),
                                  child: const Icon(Icons.payments_rounded, color: Brand.greenDark, size: 20),
                                ),
                                title: Text(money(p.amount), style: const TextStyle(fontWeight: FontWeight.w600, color: Brand.greenDark)),
                                subtitle: Text(formatDateTime(p.collectedAt)),
                                trailing: StatusChip(p.isPartial ? 'Partial' : 'Paid off', color: p.isPartial ? Brand.amber : Brand.greenDark),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (d.notes != null) ...[
                    const SizedBox(height: 18),
                    SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Notes', style: Brand.display(18)), const SizedBox(height: 6), Text(d.notes!, style: const TextStyle(color: Brand.muted))])),
                  ],
                  const SizedBox(height: 22),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 320),
                    child: RedButton(label: 'Share as PDF', icon: Icons.picture_as_pdf_rounded, expand: true, loading: _sharing, onPressed: _share),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Header extends StatelessWidget {
  final InvoiceDetail d;
  const _Header({required this.d});

  @override
  Widget build(BuildContext context) {
    final i = d.invoice;
    return SoftCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    Text(i.number, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    Text('${formatDate(i.date)} · ${i.isCredit ? 'Credit' : 'Cash'}', style: const TextStyle(color: Brand.faint, fontSize: 12.5)),
                  ],
                ),
              ),
              StatusChip.paid(i.isPaid),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Invoice total', style: TextStyle(color: Brand.muted)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CountUp(value: i.total, decimals: 2, prefix: 'Rs. ', style: Brand.display(32)),
          ),
          if (!i.isPaid && i.balanceDue > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(color: Brand.soft, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: Brand.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Balance due: ${money(i.balanceDue)}', style: const TextStyle(color: Brand.redDark, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final bool strong;
  const _Pill(this.text, {this.strong = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: strong ? Colors.white : Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: TextStyle(color: strong ? Brand.red : Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
      );
}

class _TotalRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  final Color? color;
  const _TotalRow(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400, color: color ?? Brand.ink, fontSize: bold ? 16 : 14.5);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [Text(label, style: style.copyWith(color: bold ? Brand.ink : Brand.muted)), const Spacer(), Text(value, style: style)]),
    );
  }
}
