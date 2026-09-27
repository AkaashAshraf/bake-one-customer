import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../state/auth_provider.dart';
import '../../widgets/anim.dart';
import '../../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: Text('Log out?', style: Brand.display(22)),
        content: const Text('You can log back in any time with your email and password.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AuthProvider>().customer;
    return Scaffold(
      appBar: AppBar(title: const Text('My profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
        children: [
          FadeSlideIn(
            child: SoftCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(gradient: Brand.buttonGradient, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(c?.initial ?? '?', style: Brand.display(28, color: Colors.white)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c?.name ?? '', style: Brand.display(21)),
                        if (c?.email != null) Text(c!.email!, style: const TextStyle(color: Brand.faint)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: SoftCard(
              child: Column(
                children: [
                  _Info(icon: Icons.person_outline_rounded, label: 'Name', value: c?.name),
                  _Info(icon: Icons.mail_outline_rounded, label: 'Email', value: c?.email),
                  _Info(icon: Icons.call_outlined, label: 'Contact', value: c?.contact),
                  _Info(icon: Icons.location_on_outlined, label: 'Address', value: c?.address, last: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Text('To change these details, please contact Bake One.', style: TextStyle(color: Brand.faint, fontSize: 12.5)),
          ),
          const SizedBox(height: 10),
          FadeSlideIn(
            delay: const Duration(milliseconds: 200),
            child: SoftCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_reset_rounded, color: Brand.red),
                    title: const Text('Change password'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const _ChangePasswordSheet()),
                  ),
                  const Divider(height: 1, color: Brand.line),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Brand.red),
                    title: const Text('Log out', style: TextStyle(color: Brand.red, fontWeight: FontWeight.w500)),
                    onTap: () => _logout(context),
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

class _Info extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool last;
  const _Info({required this.icon, required this.label, this.value, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: Brand.line))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Brand.red, size: 21),
          const SizedBox(width: 12),
          SizedBox(width: 72, child: Text(label, style: const TextStyle(color: Brand.faint))),
          Expanded(child: Text(value ?? '—', style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Api.instance.put('/password', {
        'current_password': _current.text,
        'password': _new.text,
        'password_confirmation': _confirm.text,
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated ✓')));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(22, 22, 22, MediaQuery.of(context).viewInsets.bottom + 26),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Change password', style: Brand.display(24)),
            const SizedBox(height: 16),
            if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: const TextStyle(color: Brand.redDark))),
            TextFormField(controller: _current, obscureText: true, decoration: const InputDecoration(labelText: 'Current password'), validator: (v) => (v ?? '').isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _new, obscureText: true, decoration: const InputDecoration(labelText: 'New password'), validator: (v) => (v ?? '').length < 8 ? 'At least 8 characters' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm new password'), validator: (v) => v != _new.text ? "Passwords don't match" : null),
            const SizedBox(height: 20),
            RedButton(label: 'Save password', expand: true, loading: _busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
