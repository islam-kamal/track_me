import 'package:flutter/material.dart';
import 'package:nt_location_tracking/nt_location_tracking.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tracking/tracking_session.dart';
import '../theme/track_me_theme.dart';

const permissionAcknowledgedKey = 'track_me_location_acknowledged';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({
    super.key,
    required this.userId,
    required this.onGranted,
  });

  final String userId;
  final VoidCallback onGranted;

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _continue() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await TrackingSession.ensureStarted(widget.userId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(permissionAcknowledgedKey, true);
      widget.onGranted();
    } on LocationPermissionException catch (error) {
      setState(() => _error = error.message);
    } catch (error) {
      setState(() => _error = 'Tracking could not start. $error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: trackTeal,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.my_location, color: trackInk, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                'Location stays on',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              const Text(
                'Track Me records this account from the moment you allow location access. Tracking continues in the background and after you close the app, until you sign out.',
                style: TextStyle(color: Color(0xFFCBD5E1), height: 1.45, fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Android shows a persistent notification while recording. iOS needs Always location so the route is saved when the app is not open.',
                style: TextStyle(color: Color(0xFF94A3B8), height: 1.4),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Color(0xFFFDA4AF))),
              ],
              const Spacer(),
              FilledButton(
                onPressed: _busy ? null : _continue,
                child: Text(_busy ? 'Starting…' : 'Allow and start tracking'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
