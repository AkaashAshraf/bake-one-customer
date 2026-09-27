import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/anim.dart';
import '../../widgets/common.dart';

/// "How we bake" - the step-by-step process, as its own page.
class ProcessScreen extends StatelessWidget {
  const ProcessScreen({super.key});

  static const _steps = [
    ('🌾', 'Quality ingredients', 'Flour, sugar, oil and every other ingredient is checked before it goes anywhere near the mixer.'),
    ('⚖️', 'Precise recipes', 'Every ingredient is weighed carefully so each batch tastes exactly like the last.'),
    ('🫧', 'Mixing & proofing', 'Dough is mixed and given the time it needs to rise, for a soft, even texture.'),
    ('🔥', 'Baked to perfection', 'Baked at just the right temperature for a golden crust and a fluffy inside.'),
    ('📦', 'Packed & delivered', 'Cooled, packed hygienically and sent out fresh to shops, cafés and homes.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How we bake')),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
        itemCount: _steps.length,
        itemBuilder: (_, i) {
          final s = _steps[i];
          final last = i == _steps.length - 1;
          return FadeSlideIn(
            delay: Duration(milliseconds: 90 * i),
            offset: const Offset(30, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(gradient: Brand.buttonGradient, shape: BoxShape.circle, boxShadow: Brand.glow),
                      alignment: Alignment.center,
                      child: Text('${i + 1}', style: Brand.display(17, color: Colors.white)),
                    ),
                    if (!last) Container(width: 2, height: 96, color: Brand.red.withOpacity(.2)),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SoftCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [Text(s.$1, style: const TextStyle(fontSize: 26)), const SizedBox(width: 10), Expanded(child: Text(s.$2, style: Brand.display(18)))]),
                          const SizedBox(height: 6),
                          Text(s.$3, style: const TextStyle(color: Brand.muted, height: 1.45)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _items = [
    ('Do you supply shops and restaurants?', 'Yes. We supply retail shops, restaurants, cafés and caterers with regular fresh deliveries. Contact us to set up an account.'),
    ('How do I place an order?', 'This app is our product menu. For orders, bulk quantities or custom requests, please call or WhatsApp us from the More tab.'),
    ('Where can I see my invoices?', 'Log in under Account to see your invoices, payments, outstanding balance and your special product prices.'),
    ('Can I share an invoice?', 'Yes. Open any invoice and tap Share as PDF.'),
    ('Are your products baked fresh?', 'Yes. Everything is baked in daily batches and delivered fresh.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
        itemCount: _items.length,
        itemBuilder: (_, i) => FadeSlideIn(
          delay: Duration(milliseconds: 60 * i),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Brand.line)),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: i == 0,
                iconColor: Brand.red,
                collapsedIconColor: Brand.faint,
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                title: Text(_items[i].$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                children: [Align(alignment: Alignment.centerLeft, child: Text(_items[i].$2, style: const TextStyle(color: Brand.muted, height: 1.5)))],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
