import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/models.dart';
import '../core/theme.dart';
import 'anim.dart';

const _emojis = ['🍞', '🥐', '🥖', '🧁', '🍰', '🥯', '🍪', '🥨', '🥞', '🍩'];
String emojiFor(int id) => _emojis[id.abs() % _emojis.length];

/// Red gradient banner with spinning rings, flour particles and floating
/// bakes - the app's signature header (same as the website's red panels).
class RedBanner extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final List<String> emojis;

  const RedBanner({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 28, 24, 28),
    this.radius = 30,
    this.emojis = const ['🥐', '🍞'],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius), gradient: Brand.redGradient, boxShadow: Brand.glow),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(child: FlourParticles(count: 15)),
          Positioned(
            top: -70,
            right: -70,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(.16))),
            ),
          ),
          Positioned(
            top: -30,
            right: -30,
            child: Spin(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(.2), width: 1.2)),
                child: CustomPaint(painter: _DashPainter()),
              ),
            ),
          ),
          if (emojis.isNotEmpty)
            Positioned(
              right: 14,
              bottom: 12,
              child: Row(
                children: [
                  for (var i = 0; i < emojis.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: FloatingEmoji(emojis[i], size: 38, delay: Duration(milliseconds: 900 * i)),
                    ),
                ],
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(.25)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final r = size.width / 2 - 14;
    const dashes = 36;
    for (var i = 0; i < dashes; i += 2) {
      final a1 = i / dashes * 6.2832, a2 = (i + 1) / dashes * 6.2832;
      canvas.drawArc(Rect.fromCircle(center: size.center(Offset.zero), radius: r), a1, a2 - a1, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Eyebrow + serif title + a red line that draws in, like the website.
class SectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final bool center;
  final Widget? trailing;

  const SectionHeading({super.key, required this.eyebrow, required this.title, this.center = false, this.trailing});

  @override
  Widget build(BuildContext context) {
    final col = Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(eyebrow.toUpperCase(), style: Brand.eyebrow(), textAlign: center ? TextAlign.center : TextAlign.start),
        const SizedBox(height: 10),
        Text(title, style: Brand.display(30), textAlign: center ? TextAlign.center : TextAlign.start),
        const SizedBox(height: 14),
        const GrowLine(),
      ],
    );
    return Reveal(
      child: trailing == null ? col : Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: col), trailing!]),
    );
  }
}

class GrowLine extends StatelessWidget {
  final double width;
  final Color color;

  const GrowLine({super.key, this.width = 64, this.color = Brand.red});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Container(
        width: width * v,
        height: 2,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), gradient: LinearGradient(colors: [color, color.withOpacity(.2)])),
      ),
    );
  }
}

/// Network product photo with an emoji fallback on a soft radial backdrop.
class ProductArt extends StatelessWidget {
  final Product product;
  final double emojiSize;
  final bool discount;

  const ProductArt({super.key, required this.product, this.emojiSize = 64, this.discount = false});

  @override
  Widget build(BuildContext context) {
    final fallback = Center(child: Text(emojiFor(product.id), style: TextStyle(fontSize: emojiSize)));
    return DecoratedBox(
      decoration: BoxDecoration(gradient: discount ? Brand.discountBg : Brand.productBg),
      child: product.imageUrl == null
          ? fallback
          : Padding(
              padding: const EdgeInsets.all(14),
              child: Image.network(
                product.imageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => fallback,
                loadingBuilder: (_, child, progress) => progress == null ? child : const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Brand.red))),
              ),
            ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusChip(this.label, {super.key, required this.color, this.icon});

  factory StatusChip.paid(bool paid, {String? partialLabel}) => paid
      ? const StatusChip('Paid', color: Brand.greenDark, icon: Icons.check_circle_rounded)
      : StatusChip(partialLabel ?? 'Unpaid', color: Brand.red, icon: Icons.schedule_rounded);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
          Text(label, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// White rounded card used across the app.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? color;
  final Border? border;

  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.radius = 24, this.color, this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: Brand.line),
        boxShadow: Brand.card,
      ),
      child: child,
    );
  }
}

class EmptyState extends StatelessWidget {
  final String emoji, title, message;
  final Widget? action;

  const EmptyState({super.key, required this.emoji, required this.title, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingEmoji(emoji, size: 64),
          const SizedBox(height: 18),
          Text(title, style: Brand.display(22), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Brand.muted, height: 1.5), textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => EmptyState(
        emoji: '🥖',
        title: 'Something went wrong',
        message: message,
        action: FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again')),
      );
}

/// Red gradient pill button with a pressed-scale effect.
class RedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool expand;

  const RedButton({super.key, required this.label, this.onPressed, this.loading = false, this.icon, this.expand = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Pressable(
      onTap: enabled ? onPressed : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled || loading ? 1 : .55,
        child: Container(
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), gradient: Brand.buttonGradient, boxShadow: Brand.glow),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
              else ...[
                if (icon != null) ...[Icon(icon, color: Colors.white, size: 19), const SizedBox(width: 8)],
                Text(label.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, letterSpacing: 1.6, fontSize: 13.5)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> openExternal(BuildContext context, String? url) async {
  final uri = url == null ? null : Uri.tryParse(url);
  final ok = uri != null && await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't open that. Please try again.")));
  }
}

String? telUrl(String? phone) => phone == null ? null : 'tel:${phone.replaceAll(RegExp(r'[^\d+]'), '')}';

String? whatsappUrl(Business b, {String? text}) {
  if (b.whatsappUrl == null) return null;
  return text == null ? b.whatsappUrl : '${b.whatsappUrl}?text=${Uri.encodeComponent(text)}';
}
