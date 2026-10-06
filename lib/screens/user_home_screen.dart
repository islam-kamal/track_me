import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nt_location_tracking/nt_location_tracking.dart';

import '../admin/admin_map_controller.dart';
import '../auth/user_profile.dart';
import 'admin_home_screen.dart';
import '../format/time_label.dart';
import '../theme/track_me_theme.dart';
import '../tracking/tracking_session.dart';
import '../widgets/account_sheet.dart';
import '../widgets/people_map.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  StreamSubscription<LocationPoint>? _liveSubscription;
  StreamSubscription<TrackingException>? _errorSubscription;
  LocationPoint? _current;
  String? _error;
  bool _starting = true;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      await TrackingSession.ensureStarted(widget.profile.uid);
      _liveSubscription = LocationTracking.onLocation.listen((point) {
        if (mounted) {
          setState(() => _current = point);
        }
      });
      _errorSubscription = LocationTracking.onPersistenceError.listen((error) {
        if (mounted) {
          setState(() => _error = error.message);
        }
      });
      final current = await LocationTracking.getCurrentLocation();
      if (mounted) {
        setState(() {
          _current = current ?? _current;
          _starting = false;
        });
      }
    } on LocationPermissionException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _starting = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = 'Tracking could not start.';
          _starting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    unawaited(_liveSubscription?.cancel());
    unawaited(_errorSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: trackSlate)),
          Positioned.fill(
            child: PeopleMap(
              people: [
                TrackedPerson(profile: widget.profile, location: current),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _StatusBar(
              profile: widget.profile,
              current: current,
              starting: _starting,
              error: _error,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.profile,
    required this.current,
    required this.starting,
    required this.error,
  });

  final UserProfile profile;
  final LocationPoint? current;
  final bool starting;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xE60B1220), Color(0x000B1220)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Pill(
                icon: Icons.circle,
                label: starting ? 'Starting' : 'Recording',
                iconColor: starting ? const Color(0xFFFBBF24) : trackTeal,
              ),
              if (profile.isAdmin) ...[
                const SizedBox(width: 8),
                _PeopleButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AdminHomeScreen(profile: profile),
                      ),
                    );
                  },
                ),
              ],
              const Spacer(),
              Material(
                color: trackCard,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => showAccountSheet(context, profile),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      profile.initials,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            current == null
                ? 'Waiting for the first location'
                : formatCoordinates(current!.latitude, current!.longitude),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            current == null
                ? 'This route is saved for your account, including after the app closes.'
                : 'Updated ${formatWhen(current!.timestamp)}',
            style: const TextStyle(color: Color(0xFFCBD5E1)),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: const TextStyle(color: Color(0xFFFDA4AF))),
          ],
        ],
      ),
    );
  }
}

class _PeopleButton extends StatelessWidget {
  const _PeopleButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: trackCard,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.groups, size: 16, color: trackTeal),
              SizedBox(width: 6),
              Text('People', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: trackCard,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: iconColor),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
