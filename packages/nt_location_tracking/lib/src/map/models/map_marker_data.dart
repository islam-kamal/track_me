import '../../models/location_point.dart';

/// Provider-neutral marker model — decouples [LocationPoint] from Google/OSM APIs.
///
/// Both map implementations consume [MapMarkerData] so marker logic stays shared.
class MapMarkerData {
  const MapMarkerData({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.address,
    this.isCurrent = false,
  });

  factory MapMarkerData.fromLocationPoint(
    LocationPoint point, {
    required String id,
    bool isCurrent = false,
  }) {
    return MapMarkerData(
      id: id,
      latitude: point.latitude,
      longitude: point.longitude,
      timestamp: point.timestamp,
      address: point.address,
      isCurrent: isCurrent,
    );
  }

  final String id;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String? address;
  final bool isCurrent;

  MapMarkerData copyWith({String? address, bool? isCurrent}) {
    return MapMarkerData(
      id: id,
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
      address: address ?? this.address,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MapMarkerData &&
        other.id == id &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.timestamp == timestamp &&
        other.address == address &&
        other.isCurrent == isCurrent;
  }

  @override
  int get hashCode => Object.hash(
        id,
        latitude,
        longitude,
        timestamp,
        address,
        isCurrent,
      );
}
