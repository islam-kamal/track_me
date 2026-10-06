import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:nt_location_tracking/nt_location_tracking.dart';

import '../auth/user_profile.dart';
import '../firebase/database_targets.dart';
import '../format/time_label.dart';

class TrackedPerson {
  const TrackedPerson({
    required this.profile,
    this.location,
  });

  final UserProfile profile;
  final LocationPoint? location;
}

/// Loads tracked users for the admin map.
///
/// The live marker follows each saved position.
/// Today's history keeps one location for each hour of the local day.
class AdminMapController extends ChangeNotifier {
  AdminMapController({DatabaseReference? root})
    : _root =
          root ??
          FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL: trackingDatabaseUrl,
          ).ref();

  final DatabaseReference _root;

  static const Duration refreshInterval = Duration(minutes: 1);

  Timer? _timer;
  final Map<String, StreamSubscription<DatabaseEvent>> _locationSubs = {};
  StreamSubscription<DatabaseEvent>? _historySub;
  bool _disposed = false;
  bool loading = true;
  bool historyLoading = false;
  String? error;
  String? historyError;
  DateTime? lastRefreshed;
  List<TrackedPerson> people = const [];
  List<LocationPoint> todayHistory = const [];
  String? selectedUid;

  TrackedPerson? get selected {
    for (final person in people) {
      if (person.profile.uid == selectedUid) {
        return person;
      }
    }
    return null;
  }

  void start() {
    unawaited(refresh());
    _timer ??= Timer.periodic(refreshInterval, (_) {
      unawaited(refresh());
    });
  }

  Future<void> refresh() async {
    try {
      final snapshot = await _root.child('profiles').get();
      final known = {
        for (final person in people) person.profile.uid: person.location,
      };
      final next = <TrackedPerson>[];
      final value = snapshot.value;
      if (value is Map) {
        for (final entry in value.entries) {
          final raw = entry.value;
          if (raw is! Map) {
            continue;
          }
          final profile = UserProfile.fromValue(entry.key.toString(), raw);
          var location = await _loadCurrent(profile.uid);
          final current = known[profile.uid];
          if (current != null &&
              (location == null ||
                  current.timestamp.isAfter(location.timestamp))) {
            location = current;
          }
          next.add(TrackedPerson(profile: profile, location: location));
        }
      }
      next.sort(
        (a, b) => a.profile.displayName.toLowerCase().compareTo(
          b.profile.displayName.toLowerCase(),
        ),
      );
      people = next;
      error = null;
      lastRefreshed = DateTime.now();
      if (selectedUid != null &&
          !people.any((person) => person.profile.uid == selectedUid)) {
        selectedUid = null;
      }
      _syncLocationListeners(next.map((person) => person.profile.uid));
    } catch (caught) {
      error = 'Could not refresh locations.';
      debugPrint('Admin refresh failed: $caught');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void select(String? uid) {
    unawaited(_historySub?.cancel());
    _historySub = null;
    selectedUid = uid;
    todayHistory = const [];
    historyError = null;
    historyLoading = uid != null;
    notifyListeners();
    if (uid == null) {
      return;
    }
    _historySub = _root
        .child('users')
        .child(uid)
        .child('locations')
        .onValue
        .listen(
          (event) => _applyHistory(uid, event.snapshot.value),
          onError: (Object error) {
            if (_disposed || selectedUid != uid) {
              return;
            }
            historyLoading = false;
            historyError = "Could not load today's history.";
            debugPrint('History listen failed: $error');
            notifyListeners();
          },
        );
  }

  void _syncLocationListeners(Iterable<String> uids) {
    final wanted = uids.toSet();
    for (final uid in _locationSubs.keys.toList()) {
      if (!wanted.contains(uid)) {
        unawaited(_locationSubs.remove(uid)?.cancel());
      }
    }
    for (final uid in wanted) {
      _locationSubs.putIfAbsent(uid, () {
        return _root
            .child('users')
            .child(uid)
            .child('currentLocation')
            .onValue
            .listen(
              (event) => _applyLocation(uid, event.snapshot.value),
              onError: (Object error) {
                debugPrint('Location listen failed for $uid: $error');
              },
            );
      });
    }
  }

  void _applyLocation(String uid, Object? value) {
    if (_disposed) {
      return;
    }
    final index = people.indexWhere((person) => person.profile.uid == uid);
    if (index < 0) {
      return;
    }
    LocationPoint? point;
    if (value is Map) {
      point = LocationPoint.fromMap(Map<dynamic, dynamic>.from(value));
    }
    final next = [...people];
    next[index] = TrackedPerson(profile: people[index].profile, location: point);
    people = next;
    if (uid == selectedUid && point != null) {
      todayHistory = _hourlyToday([...todayHistory, point]);
    }
    lastRefreshed = DateTime.now();
    notifyListeners();
  }

  void _applyHistory(String uid, Object? value) {
    if (_disposed || selectedUid != uid) {
      return;
    }
    final now = DateTime.now();
    final points = <LocationPoint>[];
    if (value is Map) {
      for (final entry in value.values) {
        if (entry is! Map) {
          continue;
        }
        final LocationPoint point;
        try {
          point = LocationPoint.fromMap(Map<dynamic, dynamic>.from(entry));
        } catch (caught) {
          debugPrint('Skipped a location record: $caught');
          continue;
        }
        if (isSameLocalDay(point.timestamp, now)) {
          points.add(point);
        }
      }
    }
    final current = selected?.location;
    todayHistory = _hourlyToday([
      ...points,
      ?current,
    ]);
    historyLoading = false;
    historyError = null;
    notifyListeners();
  }

  /// One location per clock hour. Extra saves inside the same hour are dropped.
  List<LocationPoint> _hourlyToday(List<LocationPoint> points) {
    final now = DateTime.now();
    final byHour = <int, LocationPoint>{};
    for (final point in points) {
      if (!isSameLocalDay(point.timestamp, now)) {
        continue;
      }
      final hour = point.timestamp.toLocal().hour;
      final existing = byHour[hour];
      if (existing == null || point.timestamp.isAfter(existing.timestamp)) {
        byHour[hour] = point;
      }
    }
    final hours = byHour.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final hour in hours) byHour[hour]!];
  }

  Future<LocationPoint?> _loadCurrent(String uid) async {
    final snapshot = await _root
        .child('users')
        .child(uid)
        .child('currentLocation')
        .get();
    final value = snapshot.value;
    if (value is! Map) {
      return null;
    }
    return LocationPoint.fromMap(Map<dynamic, dynamic>.from(value));
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_historySub?.cancel());
    for (final subscription in _locationSubs.values) {
      unawaited(subscription.cancel());
    }
    _locationSubs.clear();
    super.dispose();
  }
}
