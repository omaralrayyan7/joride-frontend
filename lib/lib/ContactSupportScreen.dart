import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/app_localizations.dart';

const Color _kBrand = Color(0xFF1A3D7C);

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('contact_support_title')),
        backgroundColor: _kBrand,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 16),

          // Hero icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _kBrand.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent,
                  size: 70, color: _kBrand),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'We\'re here to help',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _kBrand),
          ),
          const SizedBox(height: 8),
          Text(
            'Our support team is available Saturday – Thursday, 9 AM – 9 PM (Jordan time).',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(170),
                height: 1.5),
          ),
          const SizedBox(height: 32),

          // Phone card
          _ContactCard(
            icon: Icons.phone,
            title: 'Phone / WhatsApp',
            value: l.t('support_phone'),
            onTap: () async {
              await Clipboard.setData(
                  ClipboardData(text: l.t('support_phone')));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text('Phone number copied to clipboard.')));
              }
            },
          ),
          const SizedBox(height: 14),

          _ContactCard(
            icon: Icons.email_outlined,
            title: 'Email',
            value: 'support@joride.jo',
            onTap: () async {
              await Clipboard.setData(
                  const ClipboardData(text: 'support@joride.jo'));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Email address copied to clipboard.')));
              }
            },
          ),
          const SizedBox(height: 14),

          _ContactCard(
            icon: Icons.location_on_outlined,
            title: 'Location',
            value: 'Amman, Jordan',
            onTap: null,
          ),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _kBrand.withAlpha(12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kBrand.withAlpha(40)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: _kBrand),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap a contact card to copy the details to your clipboard.',
                    style: TextStyle(color: _kBrand, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData  icon;
  final String    title;
  final String    value;
  final VoidCallback? onTap;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardTheme.color ??
          Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: _kBrand.withAlpha(20),
                    shape: BoxShape.circle),
                child: Icon(icon, color: _kBrand),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(150),
                          fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ],
              ),
              if (onTap != null) ...[
                const Spacer(),
                Icon(Icons.copy_outlined,
                    size: 18,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(100)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
