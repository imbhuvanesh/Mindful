import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/colors.dart';
import '../widgets/glass_card.dart';

/// Support tab: a simple support section (tap to email) plus Bhuvy branding.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const _email = 'iambhuvanesh.a@gmail.com';
  static const _site = 'https://imbhuvanesh.github.io/dev/';

  Future<void> _mail() async {
    final uri = Uri(scheme: 'mailto', path: _email);
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
          children: [
            const Text(
              'SUPPORT',
              style: TextStyle(
                color: MindfulColors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 24),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.mail_outline,
                    color: MindfulColors.white),
                title: const Text(
                  'Contact support',
                  style: TextStyle(
                    color: MindfulColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                subtitle: const Text(
                  _email,
                  style: TextStyle(color: MindfulColors.gray, fontSize: 13),
                ),
                trailing: const Icon(Icons.chevron_right,
                    color: MindfulColors.mist),
                onTap: _mail,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Questions, feedback or need a hand? Write to us — real humans '
              'read every message.',
              style: TextStyle(color: MindfulColors.gray, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 24),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bhuvy',
                    style: TextStyle(
                      color: MindfulColors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Designed and built by Bhuvy. Craft thoughtful tools, '
                    'block the noise.',
                    style: TextStyle(
                      color: MindfulColors.mist,
                      height: 1.4,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(_site)),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Visit website'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}