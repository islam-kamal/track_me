import 'package:flutter/material.dart';
import 'package:nt_location_tracking/nt_location_tracking.dart';

import '../admin/admin_map_controller.dart';
import '../auth/user_profile.dart';
import '../format/time_label.dart';
import '../theme/track_me_theme.dart';
import '../widgets/account_sheet.dart';
import '../widgets/people_map.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late final AdminMapController _controller;
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AdminMapController()..start();
  }

  void _openPerson(String uid) {
    if (_controller.selectedUid != uid) {
      _controller.select(uid);
    }
    if (_sheetOpen) {
      return;
    }
    _sheetOpen = true;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.58,
          minChildSize: 0.34,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                final person = _controller.selected;
                return DecoratedBox(
                  decoration: const BoxDecoration(
                    color: trackCard,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (person == null)
                        const Text('This person is no longer on the map.')
                      else
                        _PersonDetail(
                          person: person,
                          isViewer: person.profile.uid == widget.profile.uid,
                          history: _controller.todayHistory,
                          loading: _controller.historyLoading,
                          error: _controller.historyError,
                          onClose: () => Navigator.of(context).pop(),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      _sheetOpen = false;
      if (mounted) {
        _controller.select(null);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final selected = _controller.selected;
        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: PeopleMap(
                  people: _controller.people,
                  selected: selected,
                  todayHistory: _controller.todayHistory,
                  onPersonTap: _openPerson,
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _AdminHeader(
                  profile: widget.profile,
                  lastRefreshed: _controller.lastRefreshed,
                ),
              ),
              DraggableScrollableSheet(
                initialChildSize: 0.32,
                minChildSize: 0.18,
                maxChildSize: 0.72,
                builder: (context, scrollController) {
                  return _UserSheet(
                    controller: _controller,
                    scrollController: scrollController,
                    viewerUid: widget.profile.uid,
                    onOpen: _openPerson,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({
    required this.profile,
    required this.lastRefreshed,
  });

  final UserProfile profile;
  final DateTime? lastRefreshed;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 28),
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
              const Expanded(
                child: Text(
                  'Admin map',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
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
          const SizedBox(height: 6),
          Text(
            lastRefreshed == null
                ? 'Saves every 5 minutes or 10 meters'
                : 'Updated ${formatWhen(lastRefreshed!)} · every 5 min or 10 m',
            style: const TextStyle(color: Color(0xFFCBD5E1)),
          ),
        ],
      ),
    );
  }
}

class _UserSheet extends StatelessWidget {
  const _UserSheet({
    required this.controller,
    required this.scrollController,
    required this.viewerUid,
    required this.onOpen,
  });

  final AdminMapController controller;
  final ScrollController scrollController;
  final String viewerUid;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final people = controller.people;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: trackCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tracked users',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            controller.error ??
                'Tap a marker to open that person’s details and today’s locations.',
            style: TextStyle(
              color: controller.error == null
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFFFDA4AF),
            ),
          ),
          const SizedBox(height: 12),
          if (controller.loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (people.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No tracked users yet. When someone signs in and allows location, they appear here.',
                style: TextStyle(color: Color(0xFFCBD5E1), height: 1.4),
              ),
            )
          else
            for (final person in people)
              _PersonTile(
                person: person,
                isViewer: person.profile.uid == viewerUid,
                selected: person.profile.uid == controller.selectedUid,
                onTap: () => onOpen(person.profile.uid),
              ),
        ],
      ),
    );
  }
}

class _PersonDetail extends StatelessWidget {
  const _PersonDetail({
    required this.person,
    required this.isViewer,
    required this.history,
    required this.loading,
    required this.error,
    required this.onClose,
  });

  final TrackedPerson person;
  final bool isViewer;
  final List<LocationPoint> history;
  final bool loading;
  final String? error;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final location = person.location;
    final profile = person.profile;
    return Column(
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
                    isViewer ? '${profile.displayName} · You' : profile.displayName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profile.email,
                    style: const TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'All tracked users',
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(
              icon: Icons.badge_outlined,
              label: profile.isAdmin ? 'Admin' : 'User',
            ),
            _InfoChip(
              icon: Icons.schedule,
              label: location == null
                  ? 'No location yet'
                  : 'Updated ${formatWhen(location.timestamp)}',
            ),
          ],
        ),
        if (location != null) ...[
          const SizedBox(height: 12),
          Text(
            formatCoordinates(location.latitude, location.longitude),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Accuracy ${location.accuracy.round()} m',
            style: const TextStyle(color: Color(0xFF94A3B8)),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          "Today's history",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        const Text(
          'Every location recorded today.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 4),
        Text(
          error ??
              (loading
                  ? 'Loading today’s locations…'
                  : history.isEmpty
                  ? 'No locations saved today.'
                  : '${history.length} location${history.length == 1 ? '' : 's'} today'),
          style: TextStyle(
            color: error == null
                ? const Color(0xFF94A3B8)
                : const Color(0xFFFDA4AF),
          ),
        ),
        const SizedBox(height: 12),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          for (final point in history)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      formatClock(point.timestamp),
                      style: const TextStyle(
                        color: trackTeal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      formatCoordinates(point.latitude, point.longitude),
                      style: const TextStyle(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: trackTeal),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({
    required this.person,
    required this.isViewer,
    required this.selected,
    required this.onTap,
  });

  final TrackedPerson person;
  final bool isViewer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final location = person.location;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? const Color(0xFF134E4A) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: trackTeal,
                  foregroundColor: trackInk,
                  child: Text(person.profile.initials),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isViewer
                            ? '${person.profile.displayName} · You'
                            : person.profile.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        location == null
                            ? 'No location yet'
                            : '${formatCoordinates(location.latitude, location.longitude)} · ${formatWhen(location.timestamp)}',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
