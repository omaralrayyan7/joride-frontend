import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'services/api_service.dart';
import 'models/auth_models.dart';
import 'IDVerificationScreen.dart';
import 'DrivingLicenseScreen.dart';
import 'PaymentMethodsScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color joRideAccent = Color(0xFF13366B);
  static const Color scaffoldBg = Color(0xFFF8F9FD);

  UserProfile? _profile;
  bool _loading = true;
  String? _error;
  bool _saving = false;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() { _loading = true; _error = null; });
    try {
      final profile = await ApiService.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _nameCtrl.text = profile.name;
          _phoneCtrl.text = profile.phone ?? '';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = await ApiService.updateProfile(
        name: name,
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );
      if (mounted) {
        setState(() => _profile = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: joRideAccent,
        foregroundColor: Colors.white,
        // Explicit back arrow in brand colours
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildBody(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfile,
              style: ElevatedButton.styleFrom(backgroundColor: joRideAccent),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final profile = _profile!;
    return SingleChildScrollView(
      child: Column(
        children: [
          // ─── Header: Avatar + name + email ───────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: joRideAccent,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.white24,
                  backgroundImage: (profile.profileImageUrl != null &&
                          profile.profileImageUrl!.isNotEmpty)
                      ? NetworkImage(profile.profileImageUrl!)
                      : null,
                  child: (profile.profileImageUrl == null ||
                          profile.profileImageUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 70, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 14),
                Text(
                  profile.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                // رصيد المحفظة
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wallet_rounded,
                          color: Colors.amber, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${profile.walletBalance.toStringAsFixed(2)} JOD',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── Edit fields ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: joRideAccent,
                  ),
                ),
                const SizedBox(height: 12),
                _inputField(
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  controller: _nameCtrl,
                ),
                const SizedBox(height: 12),
                _inputField(
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: joRideAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Divider(indent: 20, endIndent: 20),

          // ─── Info items ───────────────────────────────────────────────────
          _infoTile(
            icon: Icons.card_membership_outlined,
            title: 'Driving License',
            subtitle: profile.drivingLicenseNumber ?? 'Not provided',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DrivingLicenseScreen(licenseNumber: profile.drivingLicenseNumber))),
          ),
          _infoTile(
            icon: Icons.verified_user_outlined,
            title: 'ID Verification',
            subtitle: profile.idNumber ?? 'Not provided',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IDVerificationScreen(idNumber: profile.idNumber))),
          ),
          _infoTile(
            icon: Icons.credit_card,
            title: 'Payment Methods',
            subtitle: 'Manage your cards',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsScreen())),
          ),
          _infoTile(
            icon: Icons.help_outline,
            title: 'Support',
            subtitle: 'Get help or contact us',
            onTap: () {},
          ),

          const Divider(indent: 20, endIndent: 20),

          // ─── Logout ───────────────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            onTap: _logout,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _inputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: joRideAccent),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: joRideAccent),
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: joRideAccent),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 13)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap ?? () {},
    );
  }
}
