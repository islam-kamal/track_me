/// Canonical location model shared across tracking, storage, and maps.
///
/// [toMap]/[fromMap] provide a backend-neutral serialization format so any
/// adapter (Firebase, REST, SQL) can persist the same structure.
class LocationPoint {
  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    required this.platform,
    this.address,
    this.altitude,
    this.speed,
    this.heading,
    this.isMoving = false,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final String platform;
  final String? address;
  final double? altitude;
  final double? speed;
  final double? heading;
  final bool isMoving;

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'platform': platform,
      if (address != null) 'address': address,
      if (altitude != null) 'altitude': altitude,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
      'isMoving': isMoving,
    };
  }

  factory LocationPoint.fromMap(Map<dynamic, dynamic> map) {
    return LocationPoint(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: (map['accuracy'] as num).toDouble(),
      timestamp: _parseTimestamp(map['timestamp']),
      platform: map['platform'] as String? ?? 'unknown',
      address: map['address'] as String?,
      altitude: (map['altitude'] as num?)?.toDouble(),
      speed: (map['speed'] as num?)?.toDouble(),
      heading: (map['heading'] as num?)?.toDouble(),
      isMoving: map['isMoving'] as bool? ?? false,
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return DateTime.now();
  }

  @override
  String toString() {
    return 'LocationPoint($latitude, $longitude, accuracy: $accuracy)';
  }

  /// Copy without [address] — used when [enableReverseGeocoding] is disabled.
  LocationPoint withoutAddress() {
    return LocationPoint(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      timestamp: timestamp,
      platform: platform,
      altitude: altitude,
      speed: speed,
      heading: heading,
      isMoving: isMoving,
    );
  }
}
