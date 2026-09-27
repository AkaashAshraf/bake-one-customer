import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Fades + slides its child in after [delay]. Used for staggered entrances.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final double scaleFrom;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 700),
    this.offset = const Offset(0, 28),
    this.scaleFrom = 1,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final v = _t.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(widget.offset.dx * (1 - v), widget.offset.dy * (1 - v)),
            child: Transform.scale(scale: widget.scaleFrom + (1 - widget.scaleFrom) * v, child: child),
          ),
        );
      },
    );
  }
}

/// Plays its entrance the first time it scrolls into view (like the
/// website's scroll reveals). [builder] gets 0 → 1.
class Reveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Offset offset;
  final double scaleFrom;

  const Reveal({super.key, required this.child, this.delay = Duration.zero, this.offset = const Offset(0, 36), this.scaleFrom = 1});

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 850));
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  final List<ScrollPosition> _positions = [];
  bool _started = false;
  bool _active = true;
  double _screenHeight = 800;

  void _detach() {
    for (final p in _positions) {
      p.removeListener(_check);
    }
    _positions.clear();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attach();
  }

  void _attach() {
    _active = true;
    _screenHeight = MediaQuery.sizeOf(context).height;
    _detach();
    if (_started) return;
    // Listen to every scrollable above us, so items inside a non-scrolling
    // nested grid still reveal when the outer page scrolls.
    var s = Scrollable.maybeOf(context);
    while (s != null) {
      _positions.add(s.position);
      s.position.addListener(_check);
      s = Scrollable.maybeOf(s.context);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_started || !mounted || !_active) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return;
    final top = box.localToGlobal(Offset.zero).dy;
    if (top < _screenHeight * 0.92) {
      _started = true;
      _detach();
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void deactivate() {
    _active = false;
    _detach();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _attach();
  }

  @override
  void dispose() {
    _detach();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final v = _t.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: widget.offset * (1 - v),
            child: Transform.scale(scale: widget.scaleFrom + (1 - widget.scaleFrom) * v, child: child),
          ),
        );
      },
    );
  }
}

/// Animated number that counts up from 0.
class CountUp extends StatelessWidget {
  final double value;
  final int decimals;
  final String prefix, suffix;
  final TextStyle? style;
  final Duration duration;

  const CountUp({
    super.key,
    required this.value,
    this.decimals = 0,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.duration = const Duration(milliseconds: 1600),
  });

  String _fmt(double v) {
    final fixed = v.toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final whole = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return parts.length > 1 ? '$whole.${parts[1]}' : whole;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('$prefix${_fmt(v)}$suffix', style: style),
    );
  }
}

/// Gently bobbing + swaying emoji (floating croissants etc.).
class FloatingEmoji extends StatefulWidget {
  final String emoji;
  final double size;
  final Duration delay;
  final double distance;

  const FloatingEmoji(this.emoji, {super.key, this.size = 56, this.delay = Duration.zero, this.distance = 12});

  @override
  State<FloatingEmoji> createState() => _FloatingEmojiState();
}

class _FloatingEmojiState extends State<FloatingEmoji> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 4800));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.repeat();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = _c.value * 2 * math.pi;
        return Transform.translate(
          offset: Offset(0, -widget.distance * (0.5 + 0.5 * math.sin(t))),
          child: Transform.rotate(angle: 0.1 * math.sin(t), child: child),
        );
      },
      child: Text(widget.emoji, style: TextStyle(fontSize: widget.size, shadows: [Shadow(color: Colors.black.withOpacity(.18), blurRadius: 18, offset: const Offset(0, 12))])),
    );
  }
}

/// Continuously rotating child (decorative rings).
class Spin extends StatefulWidget {
  final Widget child;
  final Duration period;
  final bool reverse;

  const Spin({super.key, required this.child, this.period = const Duration(seconds: 40), this.reverse = false});

  @override
  State<Spin> createState() => _SpinState();
}

class _SpinState extends State<Spin> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
        turns: widget.reverse ? ReverseAnimation(_c) : _c,
        child: widget.child,
      );
}

/// Pulsing scale (savings badges, notification dots).
class Pulse extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration period;

  const Pulse({super.key, required this.child, this.scale = 1.08, this.period = const Duration(milliseconds: 2200)});

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period)..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: Tween(begin: 1.0, end: widget.scale).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
        child: widget.child,
      );
}

/// Shrinks slightly while pressed - a tactile tap feel for cards/buttons.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.96});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Drifting "flour dust" particles, as on the website's banners.
class FlourParticles extends StatefulWidget {
  final int count;
  final Color color;
  final Color? altColor;

  const FlourParticles({super.key, this.count = 40, this.color = Colors.white, this.altColor});

  @override
  State<FlourParticles> createState() => _FlourParticlesState();
}

class _Particle {
  double x, y, r, vy, t, a;
  _Particle(this.x, this.y, this.r, this.vy, this.t, this.a);
}

class _FlourParticlesState extends State<FlourParticles> with SingleTickerProviderStateMixin {
  final _rand = math.Random();
  late final List<_Particle> _parts = List.generate(
    widget.count,
    (_) => _Particle(_rand.nextDouble(), _rand.nextDouble(), _rand.nextDouble() * 1.8 + .5, _rand.nextDouble() * .0016 + .0005, _rand.nextDouble() * 6.28, _rand.nextDouble() * .5 + .25),
  );
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      for (final p in _parts) {
        p.t += .02;
        p.y -= p.vy;
        p.x += math.sin(p.t) * .0006;
        if (p.y < -0.02) {
          p.y = 1.02;
          p.x = _rand.nextDouble();
        }
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return const SizedBox.expand();
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(_parts, _c, widget.color, widget.altColor),
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> parts;
  final Color color;
  final Color? alt;

  _ParticlePainter(this.parts, Listenable repaint, this.color, this.alt) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in parts) {
      final c = (alt != null && p.r < 1.3) ? alt! : color;
      paint.color = c.withOpacity((p.a * (.6 + .4 * math.sin(p.t * 2))).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(p.x * size.width, p.y * size.height), p.r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}

/// Shimmering placeholder block while content loads.
class Shimmer extends StatefulWidget {
  final double height;
  final double? width;
  final double radius;

  const Shimmer({super.key, required this.height, this.width, this.radius = 20});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(-1.5 + _c.value * 3, 0),
            end: Alignment(-0.5 + _c.value * 3, 0),
            colors: const [Brand.soft, Colors.white, Brand.soft],
          ),
        ),
      ),
    );
  }
}

/// Page route with a soft fade + rise, used for detail screens.
Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) {
        final t = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: t,
          child: SlideTransition(position: Tween(begin: const Offset(0, .06), end: Offset.zero).animate(t), child: child),
        );
      },
    );
