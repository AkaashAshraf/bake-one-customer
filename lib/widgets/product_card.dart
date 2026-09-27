import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../state/site_provider.dart';
import 'anim.dart';
import 'common.dart';

/// Product tile: floating art, category tag, price, and - for logged-in
/// customers with a special rate - a pulsing SAVE badge + struck-out price.
class ProductCard extends StatelessWidget {
  final Product product;
  final int index;
  final bool showPrice;

  const ProductCard({super.key, required this.product, this.index = 0, this.showPrice = true});

  @override
  Widget build(BuildContext context) {
    final p = product;
    return FadeSlideIn(
      delay: Duration(milliseconds: 60 * (index % 10)),
      offset: const Offset(0, 36),
      scaleFrom: .94,
      child: Pressable(
        onTap: () => showProductQuickView(context, p),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: Brand.card,
          ),
          // Border drawn on top so the product image can't cover its corners.
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: p.isDiscount ? const Color(0xFFA7F3D0) : const Color(0x33E1251B), width: 1.2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: RepaintBoundary(child: ProductArt(product: p, discount: p.isDiscount))),
                    if (p.category != null)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(.92), borderRadius: BorderRadius.circular(99)),
                          child: Text(p.category!.toUpperCase(), style: const TextStyle(color: Brand.red, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                        ),
                      ),
                    if (p.isDiscount)
                      Positioned(top: 8, right: 8, child: Pulse(child: SaveBadge(percent: p.savingsPercent))),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 38,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Brand.display(15, height: 1.2)),
                      ),
                    ),
                    if (showPrice) ...[
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              money(p.price),
                              maxLines: 1,
                              style: TextStyle(fontWeight: FontWeight.w700, color: p.isDiscount ? Brand.greenDark : Brand.red, fontSize: 14),
                            ),
                            if (p.isDiscount) ...[const SizedBox(width: 6), _StrikePrice(money(p.standardPrice))],
                          ],
                        ),
                      ),
                      Text(p.unit != null ? 'per ${p.unit}' : ' ', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Brand.faint, fontSize: 11.5)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StrikePrice extends StatelessWidget {
  final String text;
  const _StrikePrice(this.text);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Brand.faint, fontSize: 11.5)),
        Positioned.fill(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOut,
            builder: (_, v, __) => Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(widthFactor: v, child: Container(height: 1.4, color: Brand.red)),
            ),
          ),
        ),
      ],
    );
  }
}

class SaveBadge extends StatelessWidget {
  final int percent;
  final double size;
  const SaveBadge({super.key, required this.percent, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [Color(0xFF34D399), Brand.greenDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: Brand.green.withOpacity(.45), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('SAVE', style: TextStyle(color: Colors.white, fontSize: size * .17, height: 1)),
          Text('$percent%', style: Brand.display(size * .3, color: Colors.white, height: 1.1)),
        ],
      ),
    );
  }
}

/// Bottom sheet with the product, description, and (when logged in) an
/// animated comparison of the standard price vs. the customer's price.
Future<void> showProductQuickView(BuildContext context, Product p) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _QuickView(product: p),
  );
}

class _QuickView extends StatelessWidget {
  final Product product;
  const _QuickView({required this.product});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final business = context.read<SiteProvider>().business;
    final wa = whatsappUrl(business, text: 'Hi Bake One, I would like to ask about "${p.name}".');
    final max = [p.standardPrice, p.price].reduce((a, b) => a > b ? a : b);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .9),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: BoxDecoration(gradient: p.isDiscount ? Brand.discountBg : Brand.productBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Spin(
                        period: const Duration(seconds: 30),
                        child: Container(width: 210, height: 210, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Brand.red.withOpacity(.18), width: 1.2))),
                      ),
                      FadeSlideIn(
                        scaleFrom: .7,
                        offset: const Offset(0, 30),
                        child: SizedBox(width: 220, height: 220, child: ProductArt(product: p, emojiSize: 120, discount: p.isDiscount)),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 0,
                  right: 0,
                  child: Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(9)))),
                ),
                if (p.isDiscount)
                  Positioned(top: 22, left: 20, child: Pulse(child: SaveBadge(percent: p.savingsPercent, size: 62))),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(color: Brand.soft, borderRadius: BorderRadius.circular(99)),
                      child: Text(p.category!.toUpperCase(), style: Brand.eyebrow().copyWith(fontSize: 10.5, letterSpacing: 2)),
                    ),
                  const SizedBox(height: 12),
                  FadeSlideIn(child: Text(p.name, style: Brand.display(30))),
                  const SizedBox(height: 12),
                  const GrowLine(),
                  const SizedBox(height: 14),
                  Text(p.description ?? 'Freshly baked every day with quality ingredients.', style: const TextStyle(color: Brand.muted, height: 1.55, fontSize: 15)),
                  const SizedBox(height: 22),
                  if (p.yourPrice != null) ...[
                    _PriceBar(label: 'Standard price', value: p.standardPrice, max: max, color: const Color(0xFFD6D3D1), delay: 0, unit: p.unit),
                    const SizedBox(height: 14),
                    _PriceBar(label: 'Your price', value: p.price, max: max, color: p.isDiscount ? Brand.green : Brand.red, delay: 250, bold: true),
                    if (p.isDiscount)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: FadeSlideIn(
                          delay: const Duration(milliseconds: 900),
                          child: Text('You save ${money(p.savings)} on every ${p.unit ?? 'unit'} 🎉', style: const TextStyle(color: Brand.greenDark, fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ] else
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: Brand.line))),
                      child: Row(
                        children: [
                          Expanded(child: Text('PRICE', style: Brand.eyebrow(color: Brand.faint))),
                          Text(money(p.standardPrice), style: Brand.display(24, color: Brand.red)),
                          if (p.unit != null) Text('  / ${p.unit}', style: const TextStyle(color: Brand.faint)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  RedButton(
                    label: wa != null ? 'Enquire on WhatsApp' : 'Call to enquire',
                    icon: wa != null ? Icons.chat_rounded : Icons.call_rounded,
                    expand: true,
                    onPressed: () => openExternal(context, wa ?? telUrl(business.phone)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceBar extends StatelessWidget {
  final String label;
  final double value, max;
  final Color color;
  final int delay;
  final bool bold;
  final String? unit;

  const _PriceBar({required this.label, required this.value, required this.max, required this.color, required this.delay, this.bold = false, this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(color: bold ? Brand.ink : Brand.muted, fontWeight: bold ? FontWeight.w600 : FontWeight.w400))),
            Text(money(value) + (unit != null ? ' / $unit' : ''), style: bold ? Brand.display(20, color: color == Brand.green ? Brand.greenDark : Brand.red) : const TextStyle(color: Brand.muted)),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Container(
            height: 10,
            color: const Color(0xFFF5F5F4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: max == 0 ? 0 : value / max),
              duration: Duration(milliseconds: 1100 + delay),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: v.clamp(0.0, 1.0),
                  child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(9))),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
