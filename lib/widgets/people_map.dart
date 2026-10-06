import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nt_location_tracking/nt_location_tracking.dart';

import '../admin/admin_map_controller.dart';
import '../theme/track_me_theme.dart';

/// One named pin per tracked person, placed at that person's latest location.
class PeopleMap extends StatefulWidget {
  const PeopleMap({
    super.key,
    required this.people,
    this.selected,
    this.todayHistory = const [],
    this.onPersonTap,
  });

  final List<TrackedPerson> people;
  final TrackedPerson? selected;
  final List<LocationPoint> todayHistory;
  final ValueChanged<String>? onPersonTap;

  @override
  State<PeopleMap> createState() => _PeopleMapState();
}

class _PeopleMapState extends State<PeopleMap> {
  final MapController _controller = MapController();
  String? _framedUid;
  bool _mapReady = false;

  List<TrackedPerson> get _namedPeople => [
    for (final person in widget.people)
      if (person.location != null) person,
  ];

  @override
  void didUpdateWidget(covariant PeopleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectionChanged =
        widget.selected?.profile.uid != oldWidget.selected?.profile.uid;
    final gainedPins =
        _locatedCount(oldWidget) == 0 && _locatedCount(widget) > 0;
    final pathArrived =
        widget.selected != null &&
        oldWidget.todayHistory.isEmpty &&
        widget.todayHistory.isNotEmpty;
    final openedPerson = selectionChanged && widget.selected != null;
    if (openedPerson) {
      _framedUid = null;
    }
    if (openedPerson || gainedPins || pathArrived) {
      _frameSelection();
    }
  }

  int _locatedCount(PeopleMap map) {
    var count = 0;
    for (final person in map.people) {
      if (person.location != null) {
        count++;
      }
    }
    return count;
  }

  void _frameSelection() {
    if (!_mapReady) {
      return;
    }
    final selected = widget.selected;
    final path = widget.todayHistory;
    if (selected != null && path.isNotEmpty) {
      if (_framedUid == selected.profile.uid) {
        return;
      }
      _framedUid = selected.profile.uid;
      final coordinates = [
        for (final point in path) LatLng(point.latitude, point.longitude),
      ];
      _controller.fitCamera(
        CameraFit.coordinates(
          coordinates: coordinates,
          padding: const EdgeInsets.fromLTRB(36, 140, 36, 280),
          maxZoom: 16,
        ),
      );
      return;
    }

    final people = _namedPeople;
    if (people.isEmpty || selected != null) {
      return;
    }
    final focus = people.first.location;
    if (focus == null || _framedUid != null) {
      return;
    }
    _framedUid = people.first.profile.uid;
    _controller.move(LatLng(focus.latitude, focus.longitude), 14);
  }

  @override
  Widget build(BuildContext context) {
    final people = _namedPeople;
    final focus = widget.selected?.location ??
        (people.isEmpty ? null : people.first.location);
    final center = focus == null
        ? const LatLng(0, 0)
        : LatLng(focus.latitude, focus.longitude);

    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: center,
        initialZoom: focus == null ? 2 : 14,
        onMapReady: () {
          _mapReady = true;
          _frameSelection();
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.app.trackMe',
        ),
        if (widget.todayHistory.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [
                  for (final point in widget.todayHistory)
                    LatLng(point.latitude, point.longitude),
                ],
                color: trackTeal,
                strokeWidth: 4,
              ),
            ],
          ),
        MarkerLayer(markers: _markers(people)),
      ],
    );
  }

  List<Marker> _markers(List<TrackedPerson> people) {
    return [
      for (final person in people)
        if (person.location != null)
          Marker(
            point: LatLng(
              person.location!.latitude,
              person.location!.longitude,
            ),
            width: 148,
            height: 72,
            alignment: Alignment.bottomCenter,
            child: _NamedPin(
              name: person.profile.displayName,
              selected: person.profile.uid == widget.selected?.profile.uid,
              onTap: widget.onPersonTap == null
                  ? null
                  : () => widget.onPersonTap!(person.profile.uid),
            ),
          ),
    ];
  }
}

class _NamedPin extends StatelessWidget {
  const _NamedPin({required this.name, required this.selected, this.onTap});

  final String name;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 140),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? trackTeal : trackCard,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: trackTeal),
            ),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? trackInk : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(Icons.location_on, color: trackTeal, size: 36),
        ],
      ),
    );
  }
}
