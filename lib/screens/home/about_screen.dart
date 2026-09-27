import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/site_provider.dart';
import '../../widgets/anim.dart';
import '../../widgets/common.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final site = context.watch<SiteProvider>().site;
    final about = site?.aboutText ??
        'Bake One has been baking for families and businesses with one simple promise: fresh, honest bread every single day. We understand how much good taste and nutrition matter, and we work hard to deliver quality and freshness in every loaf.';
    final ops = site?.operationsText ??
        'Every Bake One product is made in a clean, carefully controlled bakery. We check every ingredient, bake in daily batches and deliver on schedule, so our customers always get the same quality.';

    return Scaffold(
      appBar: AppBar(title: const Text('Our story')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          FadeSlideIn(
            child: RedBanner(
              emojis: const ['🥐', '🍞', '🧁'],
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WHO WE ARE', style: Brand.eyebrow(color: Colors.white70)),
                  const SizedBox(height: 10),
                  Text('Baked with passion,\nserved with pride', style: Brand.display(30, color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          if (site?.aboutImageUrl != null) ...[
            Reveal(child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.network(site!.aboutImageUrl!, fit: BoxFit.cover))),
            const SizedBox(height: 22),
          ],
          const SectionHeading(eyebrow: 'About Bake One', title: 'About Us'),
          const SizedBox(height: 14),
          Reveal(child: Text(about, style: const TextStyle(color: Brand.muted, fontSize: 16, height: 1.65))),
          const SizedBox(height: 34),
          if (site?.operationsImageUrl != null) ...[
            Reveal(child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.network(site!.operationsImageUrl!, fit: BoxFit.cover))),
            const SizedBox(height: 22),
          ],
          const SectionHeading(eyebrow: 'How we work', title: 'Operations'),
          const SizedBox(height: 14),
          Reveal(child: Text(ops, style: const TextStyle(color: Brand.muted, fontSize: 16, height: 1.65))),
          const SizedBox(height: 20),
          for (final (i, point) in const ['Quality ingredients', 'Hygienic production', 'Baked in daily batches', 'On-time delivery'].indexed)
            Reveal(
              delay: Duration(milliseconds: 80 * i),
              offset: const Offset(-30, 0),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Brand.red.withOpacity(.5))),
                      child: const Icon(Icons.check_rounded, size: 16, color: Brand.red),
                    ),
                    const SizedBox(width: 12),
                    Text(point, style: const TextStyle(fontSize: 15.5)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
