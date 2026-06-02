import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ContactSupportScreen.dart';
import 'PrivacyPolicyScreen.dart';
import 'l10n/app_localizations.dart';
import 'locale_provider.dart';
import 'login_screen.dart';
import 'services/api_service.dart';
import 'theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color joRideAccent = Color(0xFF13366B);

  bool _pushNotifications = true;
  bool _emailPromotions   = false;
  bool _biometricUnlock   = false;
  bool _autoLock          = true;
  bool _loading           = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('settings_push_notifications') ?? true;
      _emailPromotions   = prefs.getBool('settings_email_promotions') ?? false;
      _biometricUnlock   = prefs.getBool('settings_biometric_unlock') ?? false;
      _autoLock          = prefs.getBool('settings_auto_lock') ?? true;
      _loading           = false;
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    _toast('Saved');
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final themeProvider  = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final l              = AppLocalizations.of(context);
    final currentLang    = localeProvider.isArabic ? 'Arabic' : 'English';

    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
          title: Text(l.t('settings')), centerTitle: true),
      body: ListView(
        children: [
          // ── Appearance ──────────────────────────────────────────────────────
          _section(l.t('appearance')),
          SwitchListTile(
            secondary: Icon(
                themeProvider.isDarkMode
                    ? Icons.dark_mode
                    : Icons.light_mode,
                color: joRideAccent),
            title: Text(l.t('dark_mode')),
            value: themeProvider.isDarkMode,
            activeColor: joRideAccent,
            onChanged: themeProvider.toggleTheme,
          ),
          ListTile(
            leading: const Icon(Icons.language, color: joRideAccent),
            title: Text(l.t('language')),
            subtitle: Text(currentLang),
            trailing: DropdownButton<String>(
              value: currentLang,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'English', child: Text('English')),
                DropdownMenuItem(value: 'Arabic', child: Text('عربي')),
              ],
              onChanged: (v) {
                if (v != null) localeProvider.setLanguage(v);
              },
            ),
          ),

          // ── Notifications ───────────────────────────────────────────────────
          _section(l.t('notif_section')),
          SwitchListTile(
            secondary: const Icon(
                Icons.notifications_active_outlined,
                color: joRideAccent),
            title: Text(l.t('push_notif')),
            value: _pushNotifications,
            activeColor: joRideAccent,
            onChanged: (v) {
              setState(() => _pushNotifications = v);
              _saveBool('settings_push_notifications', v);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.email_outlined, color: joRideAccent),
            title: Text(l.t('email_promo')),
            value: _emailPromotions,
            activeColor: joRideAccent,
            onChanged: (v) {
              setState(() => _emailPromotions = v);
              _saveBool('settings_email_promotions', v);
            },
          ),

          // ── Vehicle Key & Security ──────────────────────────────────────────
          _section(l.t('security_section')),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint, color: joRideAccent),
            title: Text(l.t('biometric_unlock')),
            subtitle: Text(l.t('biometric_unlock')),
            value: _biometricUnlock,
            activeColor: joRideAccent,
            onChanged: (v) {
              setState(() => _biometricUnlock = v);
              _saveBool('settings_biometric_unlock', v);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.lock_clock, color: joRideAccent),
            title: Text(l.t('auto_lock')),
            value: _autoLock,
            activeColor: joRideAccent,
            onChanged: (v) {
              setState(() => _autoLock = v);
              _saveBool('settings_auto_lock', v);
            },
          ),

          // ── Account ─────────────────────────────────────────────────────────
          _section(l.t('account_section')),
          _tile(Icons.lock_outline, l.t('change_password'),
              onTap: () => _info(l.t('change_password'),
                  'A backend change-password endpoint will be connected here before launch.')),
          _tile(Icons.privacy_tip_outlined, l.t('privacy_policy'),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen()))),
          _tile(Icons.support_agent_outlined, l.t('contact_support'),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const ContactSupportScreen()))),

          // ── Usage ────────────────────────────────────────────────────────────
          _section('Usage'),
          _tile(Icons.history, l.t('clear_cache'), onTap: () async {
            await ApiService.clearActiveRental();
            _toast('Local active rental cache cleared.');
          }),
          _tile(Icons.delete_forever, l.t('delete_account'),
              color: Colors.red,
              onTap: () => _info(l.t('delete_account'),
                  'Account deletion requires a dedicated backend endpoint before launch.')),

          const SizedBox(height: 20),
          const Center(
            child: Text('joRide v1.1.0',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          const SizedBox(height: 16),

          // Logout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  minimumSize: const Size(double.infinity, 52)),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: Text(l.t('logout'),
                  style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              onPressed: () async {
                await ApiService.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                      (route) => false);
                }
              },
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void _info(String title, String body) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text(title),
              content: Text(body),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'))
              ],
            ));
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
        child: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: joRideAccent,
                fontSize: 15)),
      );

  Widget _tile(IconData icon, String title,
      {String? subtitle, Color color = Colors.black87, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon,
          color: color == Colors.black87
              ? Theme.of(context).colorScheme.onSurface.withAlpha(180)
              : color),
      title: Text(title,
          style: TextStyle(
              color: color == Colors.black87
                  ? Theme.of(context).colorScheme.onSurface
                  : color)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 15),
      onTap: onTap ?? () => _toast('Opened $title'),
    );
  }
}
