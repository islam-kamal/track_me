import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../auth/user_profile.dart';
import '../theme/track_me_theme.dart';

Future<void> showAccountSheet(BuildContext context, UserProfile profile) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: trackCard,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: trackTeal,
                  foregroundColor: trackInk,
                  child: Text(profile.initials),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        profile.email,
                        style: const TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              profile.isAdmin ? 'Admin' : 'Tracked account',
              style: const TextStyle(color: trackTeal, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await AuthService().signOut();
              },
              child: const Text('Sign out'),
            ),
          ],
        ),
      );
    },
  );
}
