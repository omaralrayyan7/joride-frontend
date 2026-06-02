import 'package:flutter/material.dart';
import 'Home Screen.dart';
import 'services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  bool _loading = false;

  // Strict email format (mirrors the backend regex).
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _phoneCtrl.dispose();
    _idCtrl.dispose();
    _licenseCtrl.dispose();
    super.dispose();
  }

  /// Returns null if valid, otherwise an error message. Policy mirrors the backend.
  String? _passwordError(String pwd) {
    if (pwd.length < 8) return 'Password must be at least 8 characters long.';
    if (!pwd.contains(RegExp(r'[A-Z]'))) return 'Password must contain an uppercase letter.';
    if (!pwd.contains(RegExp(r'[a-z]'))) return 'Password must contain a lowercase letter.';
    if (!pwd.contains(RegExp(r'[^A-Za-z0-9]'))) return 'Password must contain a special character.';
    return null;
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;
    final phone = _phoneCtrl.text.trim();
    final idNumber = _idCtrl.text.trim();
    final licenseNumber = _licenseCtrl.text.trim();

    // ── Client-side validation ────────────────────────────────────────────
    if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
      _showError('Name, email, phone and password are required.');
      return;
    }
    if (idNumber.isEmpty || licenseNumber.isEmpty) {
      _showError('ID Number and Driving License Number are required.');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email address.');
      return;
    }
    final pwdErr = _passwordError(password);
    if (pwdErr != null) {
      _showError(pwdErr);
      return;
    }
    if (password != confirm) {
      _showError('Password and Confirm Password do not match.');
      return;
    }

    setState(() => _loading = true);
    try {
      await ApiService.register(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirm,
        phone: phone,
        idNumber: idNumber,
        drivingLicenseNumber: licenseNumber,
      );

      final errors = <String>[];
      try {
        await ApiService.sendEmailOtp(email);
      } catch (e) {
        errors.add('Email OTP was not sent: $e');
      }
      try {
        await ApiService.sendSmsOtp(phone);
      } catch (e) {
        errors.add('SMS OTP was not sent: $e');
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyAccountScreen(
            email: email,
            phone: phone,
            startupWarnings: errors,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      final msg = switch (e.statusCode) {
        409 => 'An account with this email already exists.',
        400 => e.message.isNotEmpty ? e.message : 'Invalid registration details.',
        _ => e.message,
      };
      _showError(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF1A3D7C),
          foregroundColor: Colors.white),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 150,
              width: double.infinity,
              decoration: const BoxDecoration(
                  color: Color(0xFF1A3D7C),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(80))),
              child: const Center(
                  child: Text('Create New Account',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold))),
            ),
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  _input('Full Name', Icons.person, controller: _nameCtrl),
                  const SizedBox(height: 15),
                  _input('Email Address', Icons.email, controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 15),
                  _input('Phone Number', Icons.phone, controller: _phoneCtrl, keyboardType: TextInputType.phone),
                  const SizedBox(height: 15),
                  _input('Password', Icons.lock, isPass: true, controller: _passwordCtrl),
                  const SizedBox(height: 15),
                  _input('Confirm Password', Icons.lock_outline, isPass: true, controller: _confirmCtrl),
                  const SizedBox(height: 15),
                  _input('ID Number', Icons.badge, controller: _idCtrl),
                  const SizedBox(height: 15),
                  _input('Driving License Number', Icons.card_membership, controller: _licenseCtrl),
                  const SizedBox(height: 30),
                  SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A3D7C),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : const Text('Sign Up & Verify', style: TextStyle(color: Colors.white, fontSize: 18)),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(String label, IconData icon,
          {bool isPass = false, TextEditingController? controller, TextInputType? keyboardType}) =>
      TextField(
          controller: controller,
          obscureText: isPass,
          keyboardType: keyboardType,
          textAlign: TextAlign.left,
          decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, color: const Color(0xFF1A3D7C)),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)));
}

class VerifyAccountScreen extends StatefulWidget {
  final String email;
  final String phone;
  final List<String> startupWarnings;

  const VerifyAccountScreen({
    super.key,
    required this.email,
    required this.phone,
    this.startupWarnings = const [],
  });

  @override
  State<VerifyAccountScreen> createState() => _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends State<VerifyAccountScreen> {
  final _emailCodeCtrl = TextEditingController();
  final _smsCodeCtrl = TextEditingController();
  bool _emailVerified = false;
  bool _phoneVerified = false;
  bool _loading = false;
  static const Color accent = Color(0xFF1A3D7C);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final warning in widget.startupWarnings) {
        _snack(warning, Colors.orange);
      }
    });
  }

  @override
  void dispose() {
    _emailCodeCtrl.dispose();
    _smsCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyEmail() async {
    final code = _emailCodeCtrl.text.trim();
    if (code.isEmpty) return _snack('Enter the email verification code.', Colors.red);
    setState(() => _loading = true);
    try {
      final ok = await ApiService.verifyEmailOtp(widget.email, code);
      if (!mounted) return;
      setState(() => _emailVerified = ok);
      _snack(ok ? 'Email verified.' : 'Email code is wrong.', ok ? Colors.green : Colors.red);
    } catch (e) {
      _snack(e.toString(), Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyPhone() async {
    final code = _smsCodeCtrl.text.trim();
    if (code.isEmpty) return _snack('Enter the SMS verification code.', Colors.red);
    setState(() => _loading = true);
    try {
      final ok = await ApiService.verifySmsOtp(widget.phone, code);
      if (!mounted) return;
      setState(() => _phoneVerified = ok);
      _snack(ok ? 'Phone verified.' : 'SMS code is wrong.', ok ? Colors.green : Colors.red);
    } catch (e) {
      _snack(e.toString(), Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendEmail() async {
    try {
      await ApiService.sendEmailOtp(widget.email);
      _snack('Email code resent.', Colors.green);
    } catch (e) {
      _snack(e.toString(), Colors.red);
    }
  }

  Future<void> _resendSms() async {
    try {
      await ApiService.sendSmsOtp(widget.phone);
      _snack('SMS code resent.', Colors.green);
    } catch (e) {
      _snack(e.toString(), Colors.red);
    }
  }

  void _snack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  void _continue() {
    if (!_emailVerified || !_phoneVerified) {
      _snack('Verify both email and phone before continuing.', Colors.red);
      return;
    }
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
  }

  Widget _verificationCard({
    required String title,
    required String subtitle,
    required bool verified,
    required TextEditingController controller,
    required VoidCallback onVerify,
    required VoidCallback onResend,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: verified ? Colors.green : accent),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17))),
          Icon(verified ? Icons.verified_rounded : Icons.pending_outlined, color: verified ? Colors.green : Colors.orange),
        ]),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(height: 14),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          enabled: !verified,
          decoration: InputDecoration(
            labelText: 'Verification Code',
            filled: true,
            fillColor: const Color(0xFFF8F9FD),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: ElevatedButton(
              onPressed: verified || _loading ? null : onVerify,
              style: ElevatedButton.styleFrom(backgroundColor: accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(verified ? 'Verified' : 'Verify', style: const TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(onPressed: verified || _loading ? null : onResend, child: const Text('Resend')),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(title: const Text('Verify Account'), backgroundColor: accent, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Almost done', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: accent)),
          const SizedBox(height: 8),
          const Text('Enter the codes sent to your email and phone to activate your JoRide account.'),
          const SizedBox(height: 24),
          _verificationCard(
            title: 'Email Verification',
            subtitle: widget.email,
            verified: _emailVerified,
            controller: _emailCodeCtrl,
            onVerify: _verifyEmail,
            onResend: _resendEmail,
            icon: Icons.email_outlined,
          ),
          _verificationCard(
            title: 'Phone Verification',
            subtitle: widget.phone,
            verified: _phoneVerified,
            controller: _smsCodeCtrl,
            onVerify: _verifyPhone,
            onResend: _resendSms,
            icon: Icons.phone_android_outlined,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _continue,
              style: ElevatedButton.styleFrom(backgroundColor: accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: const Text('Continue to JoRide', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }
}
