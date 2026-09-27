import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/auth_provider.dart';
import '../../state/site_provider.dart';
import '../../widgets/anim.dart';
import '../../widgets/common.dart';
import '../home/about_screen.dart';
import '../shell.dart';
import 'info_screens.dart';

/// "More" tab: quick contact buttons, then a settings-style list.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final b = context.watch<SiteProvider>().business;
    final auth = context.watch<AuthProvider>();
    final shell = ShellScope.of(context);

    final contacts = <(IconData, String, Color, String?)>[
      (Icons.chat_rounded, 'WhatsApp', const Color(0xFF25D366), whatsappUrl(b, text: 'Hi Bake One!')),
      (Icons.call_rounded, 'Call', Brand.red, telUrl(b.phone)),
      (Icons.mail_rounded, 'Email', const Color(0xFF3B82F6), b.email == null ? null : 'mailto:${b.email}'),
      (Icons.near_me_rounded, 'Directions', const Color(0xFFF59E0B), b.address == null ? null : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(b.address!)}'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFCFAF9),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
          physics: const BouncingScrollPhysics(),
          children: [
            FadeSlideIn(
              offset: const Offset(-20, 0),
              child: Padding(padding: const EdgeInsets.only(left: 4, bottom: 16), child: Text('More', style: Brand.display(28))),
            ),
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: SoftCard(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Brand.softer, borderRadius: BorderRadius.circular(18)),
                          child: Image.asset('assets/images/logo.png'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b.name, style: Brand.display(20)),
                              Text(b.address ?? 'Fresh bakes, every day', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Brand.muted, fontSize: 12.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        for (final (i, c) in contacts.indexed)
                          Expanded(
                            child: FadeSlideIn(
                              delay: Duration(milliseconds: 120 + 60 * i),
                              scaleFrom: .6,
                              offset: Offset.zero,
                              child: Pressable(
                                onTap: c.$4 == null ? null : () => openExternal(context, c.$4),
                                child: Opacity(
                                  opacity: c.$4 == null ? .4 : 1,
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(color: c.$3.withOpacity(.12), shape: BoxShape.circle),
                                        child: Icon(c.$1, color: c.$3),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(c.$2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            const _GroupLabel('Account'),
            _Group(children: [
              _Tile(
                icon: auth.isLoggedIn ? Icons.person_rounded : Icons.login_rounded,
                title: auth.isLoggedIn ? 'My account' : 'Log in',
                subtitle: auth.isLoggedIn ? auth.customer?.name : 'See your prices, invoices and payments',
                onTap: () => shell.goTo(Tabs.account),
              ),
              _Tile(icon: Icons.bakery_dining_rounded, title: 'Browse products', onTap: () => shell.goTo(Tabs.products)),
            ]),
            const SizedBox(height: 18),
            const _GroupLabel('About Bake One'),
            _Group(children: [
              _Tile(icon: Icons.storefront_rounded, title: 'Our story', onTap: () => Navigator.of(context).push(fadeRoute(const AboutScreen()))),
              _Tile(icon: Icons.local_fire_department_rounded, title: 'How we bake', onTap: () => Navigator.of(context).push(fadeRoute(const ProcessScreen()))),
              _Tile(icon: Icons.help_outline_rounded, title: 'FAQ', onTap: () => Navigator.of(context).push(fadeRoute(const FaqScreen()))),
              if (b.website != null) _Tile(icon: Icons.language_rounded, title: 'Visit our website', onTap: () => openExternal(context, b.website)),
            ]),
            const SizedBox(height: 18),
            const _GroupLabel('Business'),
            _Group(children: [
              _Tile(
                icon: Icons.handshake_rounded,
                title: 'Supply for your shop or café',
                subtitle: 'Message us for daily bulk delivery',
                onTap: () => openExternal(context, whatsappUrl(b, text: 'Hi Bake One, I would like to discuss regular supply for my business.') ?? telUrl(b.phone)),
              ),
            ]),
            const SizedBox(height: 26),
            Center(child: Text('${b.name} · Made fresh daily', style: const TextStyle(color: Brand.faint, fontSize: 12))),
          ],
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 6, bottom: 8),
        child: Text(text.toUpperCase(), style: const TextStyle(color: Brand.faint, fontSize: 11.5, letterSpacing: 1.4, fontWeight: FontWeight.w600)),
      );
}

class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      delay: const Duration(milliseconds: 150),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Brand.line)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1) const Divider(height: 1, indent: 60, color: Brand.line),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _Tile({required this.icon, required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: Brand.soft, borderRadius: BorderRadius.circular(11)),
        child: Icon(icon, color: Brand.red, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle == null ? null : Text(subtitle!, style: const TextStyle(fontSize: 12.5)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Brand.faint),
    );
  }
}
