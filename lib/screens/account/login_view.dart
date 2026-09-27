import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/auth_provider.dart';
import '../../widgets/anim.dart';
import '../../widgets/common.dart';
import '../shell.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _obscure = true;
  bool _busy = false;
  String? _error;
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _shake.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().login(_email.text, _password.text);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
      _shake.forward(from: 0);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F4),
      body: ListView(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 0),
              child: Column(
                children: [
                  FadeSlideIn(
                    scaleFrom: .8,
                    child: Container(
                      width: 104,
                      height: 104,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: Brand.card),
                      child: Image.asset('assets/images/logo.png'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 30),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeSlideIn(delay: const Duration(milliseconds: 300), child: Text('CUSTOMER ACCOUNT', style: Brand.eyebrow())),
                  const SizedBox(height: 8),
                  FadeSlideIn(delay: const Duration(milliseconds: 350), child: Text('Welcome back', style: Brand.display(28))),
                  const SizedBox(height: 6),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 400),
                    child: const Text('Log in to see your invoices, payments and special prices.', style: TextStyle(color: Brand.muted)),
                  ),
                  const SizedBox(height: 22),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: _error == null
                        ? const SizedBox(width: double.infinity)
                        : AnimatedBuilder(
                            animation: _shake,
                            builder: (_, child) => Transform.translate(offset: Offset(math.sin(_shake.value * math.pi * 6) * 8 * (1 - _shake.value), 0), child: child),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: Brand.soft, borderRadius: BorderRadius.circular(18), border: Border.all(color: Brand.red.withOpacity(.25))),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: Brand.red),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(_error!, style: const TextStyle(color: Brand.redDark))),
                                ],
                              ),
                            ),
                          ),
                  ),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 450),
                    child: TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.mail_outline_rounded)),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Enter your email address' : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 520),
                    child: TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, key: ValueKey(_obscure)),
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 600),
                    child: RedButton(label: 'Log in', expand: true, loading: _busy, onPressed: _submit),
                  ),
                  const SizedBox(height: 22),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 700),
                    child: SoftCard(
                      color: Brand.softer,
                      child: Row(
                        children: [
                          const Text('🔑', style: TextStyle(fontSize: 26)),
                          const SizedBox(width: 12),
                          const Expanded(child: Text("Don't have app access yet? We'll set it up for you.", style: TextStyle(color: Brand.muted, height: 1.4))),
                          TextButton(onPressed: () => ShellScope.of(context).goTo(Tabs.contact), child: const Text('Contact us')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 800),
                    child: Column(
                      children: [
                        for (final t in const ['View every invoice and share it as a PDF', 'Track payments and your outstanding balance', 'See your own special product prices'])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: const BoxDecoration(color: Brand.soft, shape: BoxShape.circle),
                                  child: const Icon(Icons.check_rounded, size: 16, color: Brand.red),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(t, style: const TextStyle(color: Brand.muted))),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
