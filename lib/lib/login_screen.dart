import 'package:flutter/material.dart';

import 'ForgotPasswordScreen.dart';
import 'Home Screen.dart';
import 'l10n/app_localizations.dart';
import 'register_screen.dart';
import 'services/api_service.dart';

const Color _kBrand = Color(0xFF1A3D7C);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading       = false;
  bool _obscure       = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      _snack('Please enter email and password.', Colors.red);
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService.login(email: email, password: password);
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } on ApiException catch (e) {
      if (!mounted) return;
      final statusCode = e.statusCode;
      String msg;
      if (statusCode == 401) {
        msg = 'Invalid email or password.';
      } else if (statusCode == 423) {
        msg = e.message; // lockout message
      } else {
        msg = e.message;
      }
      _snack(msg, Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final l         = AppLocalizations.of(context);
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF2A2A3E) : Colors.grey.shade100;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero header ──────────────────────────────────────────────────
            Container(
              height: 270,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _kBrand,
                borderRadius:
                    BorderRadius.only(bottomLeft: Radius.circular(80)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Try the logo asset first; fall back to built-in icon
                  _LogoWidget(height: 90),
                  const SizedBox(height: 14),
                  Text(l.t('welcome_back'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(l.t('login_subtitle'),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),

            // ── Form ─────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 30, 30, 20),
              child: Column(
                children: [
                  _field(l.t('email'), Icons.email,
                      controller: _emailCtrl,
                      fillColor: fillColor,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 15),
                  _field(l.t('password'), Icons.lock,
                      controller: _passwordCtrl,
                      fillColor: fillColor,
                      isPass: true),
                  const SizedBox(height: 6),

                  // Forgot password link
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: _loading
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ForgotPasswordScreen())),
                      child: Text(l.t('forgot_password'),
                          style: const TextStyle(color: _kBrand)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Login button
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
                          : Text(l.t('login'),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HomeScreen())),
                    child: Text(l.t('continue_guest'),
                        style: const TextStyle(color: _kBrand)),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l.t('no_account')),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const RegisterScreen())),
                        child: Text(l.t('register_now'),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _kBrand)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    IconData icon, {
    TextEditingController? controller,
    bool isPass = false,
    Color fillColor = Colors.white,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPass && _obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: fillColor,
        prefixIcon: Icon(icon, color: _kBrand),
        suffixIcon: isPass
            ? IconButton(
                icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: _kBrand),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
      ),
    );
  }
}

/// Shows the logo asset; falls back to a text+icon combo if the file is missing.
class _LogoWidget extends StatelessWidget {
  final double height;
  const _LogoWidget({required this.height});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo_full.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Column(
        children: const [
          Icon(Icons.directions_car_filled, size: 60, color: Colors.white),
          SizedBox(height: 6),
          Text('joRide',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
