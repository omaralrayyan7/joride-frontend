import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

const Color _kBrand = Color(0xFF1A3D7C);

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('privacy_policy_title')),
        backgroundColor: _kBrand,
        foregroundColor: Colors.white,
      ),
      body: const _PolicyBody(),
    );
  }
}

class _PolicyBody extends StatelessWidget {
  const _PolicyBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        _PolicySection(
          title: '1. Introduction',
          body:
              'JoRide ("we", "us") provides a smart car-sharing platform in Jordan. '
              'By using the app, you agree to the collection and use of information as '
              'described in this policy.',
        ),
        _PolicySection(
          title: '2. Information We Collect',
          body: '• Account data: name, email, phone number, national ID, driving license number.\n'
              '• Booking data: trip start/end times, vehicle used, payment status, digital-key events.\n'
              '• Payment data: wallet balance, top-up history, fare charges and refunds.\n'
              '• Device data: approximate location when the app is open (for map display).',
        ),
        _PolicySection(
          title: '3. How We Use Your Information',
          body: '• To operate the car-sharing service and process bookings.\n'
              '• To verify your identity and driving license via seeded validation.\n'
              '• To send booking confirmations, notifications, and overtime alerts.\n'
              '• To calculate and issue refunds for early returns.\n'
              '• For fraud prevention and security of the platform.',
        ),
        _PolicySection(
          title: '4. Data Storage',
          body:
              'Your data is stored securely in Google Firebase Firestore (project: joride-e049b). '
              'Passwords are hashed with ASP.NET Core Identity\'s PasswordHasher and are '
              'never stored in plain text.',
        ),
        _PolicySection(
          title: '5. Data Sharing',
          body:
              'We do not sell your personal data. We may share data with:\n'
              '• Payment processors (simulated in current version).\n'
              '• Traccar GPS tracking for vehicle telematics.\n'
              '• Twilio for SMS OTP verification.\n'
              '• Authorities if required by Jordanian law.',
        ),
        _PolicySection(
          title: '6. Your Rights',
          body:
              'You may request to view, correct, or delete your personal data by contacting '
              'support. Account deletion removes all personal data within 30 days.',
        ),
        _PolicySection(
          title: '7. Contact',
          body:
              'For privacy inquiries, contact us at:\n'
              'Phone: +962790550787\n'
              'This policy was last updated: June 2025.',
        ),
      ],
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;
  const _PolicySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _kBrand)),
          const SizedBox(height: 8),
          Text(body,
              style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withAlpha(200))),
        ],
      ),
    );
  }
}
