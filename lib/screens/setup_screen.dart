import 'package:flutter/material.dart';

import '../firebase/database_targets.dart';
import '../theme/track_me_theme.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const _BrandMark(),
            const SizedBox(height: 20),
            Text(
              'Connect Firebase',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Track Me is ready. Add your Firebase app config before signing in.',
              style: TextStyle(color: Color(0xFFCBD5E1), height: 1.4),
            ),
            const SizedBox(height: 24),
            const _Step(
              index: '1',
              title: 'Run FlutterFire',
              body:
                  'Run flutterfire configure and replace the YOUR_* values in lib/firebase/default_firebase_options.dart. Enable Email/Password and Google sign-in, then add the Android SHA-1 and the iOS reversed client id.',
            ),
            const _Step(
              index: '2',
              title: 'Use the default database',
              body:
                  'This project can have only one Realtime Database on the free plan. The app reads and writes that default database. Do not delete it.',
            ),
            const _Step(
              index: '3',
              title: 'Publish rules and an admin',
              body:
                  'Publish firebase/database.rules.json to the default database. Then set admins/you@gmail,com to true before that person signs in.',
            ),
            const SizedBox(height: 8),
            const _UrlCard(
              label: 'Database used by the app',
              url: trackingDatabaseUrl,
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: trackTeal,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.near_me, color: trackInk, size: 32),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.title,
    required this.body,
  });

  final String index;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF134E4A),
            foregroundColor: trackTeal,
            child: Text(index, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(color: Color(0xFF94A3B8), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UrlCard extends StatelessWidget {
  const _UrlCard({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: trackCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          const SizedBox(height: 6),
          Text(url, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
