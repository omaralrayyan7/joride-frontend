import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

const Color _kBrand = Color(0xFF1A3D7C);

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool  _loading   = false;
  bool  _sent      = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _snack('Please enter a valid email address.', Colors.red);
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 900)); // UI-only simulation
    if (mounted) {
      setState(() {
        _loading = false;
        _sent    = true;
      });
    }
  }

  void _snack(String msg, Color c) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg), backgroundColor: c));

  @override
  Widget build(BuildContext context) {
    final l      = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill   = isDark ? const Color(0xFF2A2A3E) : Colors.grey.shade100;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('forgot_password_title')),
        backgroundColor: _kBrand,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kBrand.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_reset, size: 60, color: _kBrand),
              ),
            ),
            const SizedBox(height: 30),

            Text(
              l.t('forgot_password_title'),
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: _kBrand),
            ),
            const SizedBox(height: 10),
            Text(
              l.t('forgot_password_subtitle'),
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withAlpha(170),
                  fontSize: 14,
                  height: 1.5),
            ),
            const SizedBox(height: 30),

            if (!_sent) ...[
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l.t('email'),
                  prefixIcon:
                      const Icon(Icons.email_outlined, color: _kBrand),
                  filled: true,
                  fillColor: fill,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _kBrand,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15))),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(l.t('send_reset_link'),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16)),
                ),
              ),
            ] else ...[
              // Success state
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'A password reset link has been sent to ${_emailCtrl.text.trim()}.',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: _kBrand),
                label: Text(l.t('back_to_login'),
                    style: const TextStyle(color: _kBrand)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
