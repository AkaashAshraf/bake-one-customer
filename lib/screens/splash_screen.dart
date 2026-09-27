import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../state/auth_provider.dart';
import '../state/site_provider.dart';
import '../widgets/anim.dart';
import 'shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    // Start after the first frame - loading notifies providers, which
    // isn't allowed while the first frame is still being built.
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final auth = context.read<AuthProvider>();
    final site = context.read<SiteProvider>();
    await Future.wait([
      auth.restore(),
      site.load(),
      Future.delayed(const Duration(milliseconds: 1800)),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 700),
      pageBuilder: (_, __, ___) => const Shell(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
        child: ScaleTransition(scale: Tween(begin: 1.04, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)), child: child),
      ),
    ));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(0, -0.2), radius: 1.1, colors: [Colors.white, Brand.softer, Brand.soft]),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: FlourParticles(count: 17, color: Brand.red, altColor: Brand.peach)),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 210,
                    height: 210,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 196,
                          height: 196,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Brand.red,
                            backgroundColor: Brand.red.withOpacity(.12),
                          ),
                        ),
                        ScaleTransition(
                          scale: Tween(begin: .92, end: 1.0).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
                          child: Image.asset('assets/images/logo.png', width: 130),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 400),
                    child: Text('Baked with passion', style: Brand.display(24, style: FontStyle.italic)),
                  ),
                  const SizedBox(height: 8),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 650),
                    child: Text('FRESH EVERY DAY', style: Brand.eyebrow()),
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
